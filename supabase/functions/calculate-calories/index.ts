// Edge Function "calculate-calories".
// Receives {activity, weightKg, durationMin} and answers {caloriesBurned}.
// The API key lives in the CALORIES_API_KEY secret and never reaches the Flutter client.

const CALORIES_BURNED_ENDPOINT = "https://api.api-ninjas.com/v1/caloriesburned";

// The provider works in imperial units: "weight" is pounds and "duration" is minutes. Sending
// kilograms would still return a number, just a wrong one, so this conversion is load-bearing.
const POUNDS_PER_KILOGRAM = 2.20462262;
const MINIMUM_SUPPORTED_WEIGHT_POUNDS = 50;
const MAXIMUM_SUPPORTED_WEIGHT_POUNDS = 500;
const MINIMUM_DURATION_MINUTES = 1;

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

function kilogramsToPounds(weightKg: number): number {
  return weightKg * POUNDS_PER_KILOGRAM;
}

function poundsToKilograms(weightPounds: number): number {
  return weightPounds / POUNDS_PER_KILOGRAM;
}

interface CalculateCaloriesRequest {
  activity: string;
  weightKg: number;
  durationMin: number;
}

type PayloadValidationResult =
  | { isValid: true; request: CalculateCaloriesRequest }
  | { isValid: false; message: string };

function validatePayload(payload: unknown): PayloadValidationResult {
  if (typeof payload !== "object" || payload === null || Array.isArray(payload)) {
    return { isValid: false, message: "Request body must be a JSON object." };
  }

  const { activity, weightKg, durationMin } = payload as Record<string, unknown>;

  if (typeof activity !== "string" || activity.trim().length === 0) {
    return { isValid: false, message: "activity must be a non-empty string." };
  }

  if (typeof weightKg !== "number" || !Number.isFinite(weightKg) || weightKg <= 0) {
    return { isValid: false, message: "weightKg must be a positive number." };
  }

  if (
    typeof durationMin !== "number" ||
    !Number.isInteger(durationMin) ||
    durationMin < MINIMUM_DURATION_MINUTES
  ) {
    return {
      isValid: false,
      message: `durationMin must be a whole number of at least ${MINIMUM_DURATION_MINUTES}.`,
    };
  }

  // Outside this window the provider rejects the request anyway. Clamping to the nearest bound
  // would hide the problem behind a plausible but wrong calorie count, so it is a bad request.
  const weightPounds = kilogramsToPounds(weightKg);
  if (
    weightPounds < MINIMUM_SUPPORTED_WEIGHT_POUNDS ||
    weightPounds > MAXIMUM_SUPPORTED_WEIGHT_POUNDS
  ) {
    const minimumKg = poundsToKilograms(MINIMUM_SUPPORTED_WEIGHT_POUNDS).toFixed(1);
    const maximumKg = poundsToKilograms(MAXIMUM_SUPPORTED_WEIGHT_POUNDS).toFixed(1);
    return {
      isValid: false,
      message: `weightKg must be between ${minimumKg} and ${maximumKg}, the range the calories provider supports.`,
    };
  }

  return { isValid: true, request: { activity: activity.trim(), weightKg, durationMin } };
}

function buildUpstreamUrl(request: CalculateCaloriesRequest): URL {
  const url = new URL(CALORIES_BURNED_ENDPOINT);
  url.searchParams.set("activity", request.activity);
  url.searchParams.set("weight", kilogramsToPounds(request.weightKg).toFixed(1));
  url.searchParams.set("duration", String(request.durationMin));
  return url;
}

Deno.serve(async (request: Request): Promise<Response> => {
  if (request.method === "OPTIONS") {
    return new Response(null, { status: 204, headers: corsHeaders });
  }

  if (request.method !== "POST") {
    return errorResponse("Only POST is supported.", 405);
  }

  const apiKey = Deno.env.get("CALORIES_API_KEY");
  if (!apiKey) {
    return errorResponse("The calories provider is not configured.", 500);
  }

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return errorResponse("Request body must be valid JSON.", 400);
  }

  const validation = validatePayload(payload);
  if (!validation.isValid) {
    return errorResponse(validation.message, 400);
  }

  let upstreamResponse: Response;
  try {
    upstreamResponse = await fetch(buildUpstreamUrl(validation.request), {
      headers: { "X-Api-Key": apiKey },
    });
  } catch {
    return errorResponse("The calories provider is unreachable.", 502);
  }

  if (!upstreamResponse.ok) {
    // A non-error status here (a redirect, say) would make the Response constructor throw.
    const forwardedStatus = upstreamResponse.status >= 400 && upstreamResponse.status <= 599
      ? upstreamResponse.status
      : 502;
    return errorResponse(
      `The calories provider returned status ${upstreamResponse.status}.`,
      forwardedStatus,
    );
  }

  let matchingActivities: unknown;
  try {
    matchingActivities = await upstreamResponse.json();
  } catch {
    return errorResponse("The calories provider returned a malformed response.", 502);
  }

  if (!Array.isArray(matchingActivities) || matchingActivities.length === 0) {
    return errorResponse(
      `No calorie data found for activity "${validation.request.activity}".`,
      404,
    );
  }

  const bestMatch = matchingActivities[0] as Record<string, unknown>;
  const totalCalories = bestMatch?.total_calories;
  if (typeof totalCalories !== "number" || !Number.isFinite(totalCalories)) {
    return errorResponse("The calories provider returned an unusable payload.", 502);
  }

  return jsonResponse({ caloriesBurned: totalCalories }, 200);
});
