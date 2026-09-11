// Edge Function "delete-account".
// Deletes the caller's own account: their avatar objects, then their auth user, which
// cascades to the profile and every session through the foreign keys.
//
// Deleting an auth user needs the service role key, which must never reach the Flutter
// client, so the deletion has to happen here. The function deletes the caller and only
// the caller: the id comes from verifying their access token, never from the request
// body, so no payload can name somebody else's account.

const AVATAR_BUCKET = "avatars";

const corsHeaders: Record<string, string> = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

function jsonResponse(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, "Content-Type": "application/json" },
  });
}

function errorResponse(message: string, status: number): Response {
  return jsonResponse({ error: message }, status);
}

/// Resolves the access token to a user id, or null when the token is missing,
/// expired or not one of ours.
async function resolveCallerId(
  supabaseUrl: string,
  anonKey: string,
  authorizationHeader: string,
): Promise<string | null> {
  let response: Response;
  try {
    response = await fetch(`${supabaseUrl}/auth/v1/user`, {
      headers: { Authorization: authorizationHeader, apikey: anonKey },
    });
  } catch {
    return null;
  }

  if (!response.ok) return null;

  let user: unknown;
  try {
    user = await response.json();
  } catch {
    return null;
  }

  const id = (user as Record<string, unknown>)?.id;
  return typeof id === "string" && id.length > 0 ? id : null;
}

/// Removes everything the user has in the avatars bucket.
///
/// Storage objects hang off no foreign key, so they outlive the auth user and
/// would otherwise be orphaned in the bucket for good. A failure here is not
/// fatal: an orphaned picture is a smaller problem than an account the user
/// asked to delete and which survives.
async function deleteAvatarObjects(
  supabaseUrl: string,
  serviceRoleKey: string,
  userId: string,
): Promise<void> {
  const headers = {
    Authorization: `Bearer ${serviceRoleKey}`,
    apikey: serviceRoleKey,
    "Content-Type": "application/json",
  };

  const listResponse = await fetch(
    `${supabaseUrl}/storage/v1/object/list/${AVATAR_BUCKET}`,
    {
      method: "POST",
      headers,
      body: JSON.stringify({ prefix: userId, limit: 100 }),
    },
  );
  if (!listResponse.ok) return;

  const objects = await listResponse.json();
  if (!Array.isArray(objects) || objects.length === 0) return;

  const prefixes = objects
    .map((object) => (object as Record<string, unknown>)?.name)
    .filter((name): name is string => typeof name === "string")
    .map((name) => `${userId}/${name}`);
  if (prefixes.length === 0) return;

  await fetch(`${supabaseUrl}/storage/v1/object/${AVATAR_BUCKET}`, {
    method: "DELETE",
    headers,
    body: JSON.stringify({ prefixes }),
  });
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return errorResponse("Only POST is supported.", 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    return errorResponse("The function is not configured.", 500);
  }

  const authorizationHeader = request.headers.get("Authorization");
  if (!authorizationHeader) {
    return errorResponse("Authentication required.", 401);
  }

  const userId = await resolveCallerId(supabaseUrl, anonKey, authorizationHeader);
  if (userId === null) {
    return errorResponse("Authentication required.", 401);
  }

  try {
    await deleteAvatarObjects(supabaseUrl, serviceRoleKey, userId);
  } catch {
    // Deliberately swallowed: see deleteAvatarObjects.
  }

  let deleteResponse: Response;
  try {
    deleteResponse = await fetch(
      `${supabaseUrl}/auth/v1/admin/users/${userId}`,
      {
        method: "DELETE",
        headers: {
          Authorization: `Bearer ${serviceRoleKey}`,
          apikey: serviceRoleKey,
        },
      },
    );
  } catch {
    return errorResponse("The account could not be deleted.", 502);
  }

  if (!deleteResponse.ok) {
    return errorResponse("The account could not be deleted.", 502);
  }

  return jsonResponse({ deleted: true }, 200);
});
