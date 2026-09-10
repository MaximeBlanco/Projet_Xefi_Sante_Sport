const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const { readAll, writeAll } = require('./db');

const app = express();
app.use(cors());
app.use(express.json());

// GET /api/habits - liste toutes les habitudes
app.get('/api/habits', (req, res) => {
  res.json(readAll());
});

// POST /api/habits - crée une habitude { name, emoji, colorValue }
app.post('/api/habits', (req, res) => {
  const { name, emoji, colorValue } = req.body;
  if (!name || !emoji || typeof colorValue !== 'number') {
    return res.status(400).json({ error: 'name, emoji et colorValue sont requis' });
  }

  const habit = {
    id: crypto.randomUUID(),
    name,
    emoji,
    colorValue,
    createdAt: new Date().toISOString(),
    completedDates: [],
  };

  const habits = readAll();
  habits.push(habit);
  writeAll(habits);
  res.status(201).json(habit);
});

// PATCH /api/habits/:id/toggle - bascule une date { date: "YYYY-MM-DD" }
app.patch('/api/habits/:id/toggle', (req, res) => {
  const { date } = req.body;
  if (!date) return res.status(400).json({ error: 'date est requise' });

  const habits = readAll();
  const habit = habits.find((h) => h.id === req.params.id);
  if (!habit) return res.status(404).json({ error: 'Habitude introuvable' });

  const index = habit.completedDates.indexOf(date);
  if (index === -1) {
    habit.completedDates.push(date);
  } else {
    habit.completedDates.splice(index, 1);
  }

  writeAll(habits);
  res.json(habit);
});

// DELETE /api/habits/:id - supprime une habitude
app.delete('/api/habits/:id', (req, res) => {
  const habits = readAll();
  const next = habits.filter((h) => h.id !== req.params.id);
  if (next.length === habits.length) {
    return res.status(404).json({ error: 'Habitude introuvable' });
  }
  writeAll(next);
  res.status(204).send();
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`API monapp à l'écoute sur http://localhost:${PORT}`);
});
