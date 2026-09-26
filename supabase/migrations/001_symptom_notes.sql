-- ============================================================
-- Migration 001 — run this ONCE in your already-live project
-- (Dashboard → SQL Editor → New query → paste → Run)
-- Adds per-symptom optional detail, replacing the old single
-- "note" field. Safe to run even if you have existing entries —
-- their old note text won't be lost, it's just not carried
-- forward into the new format automatically.
-- ============================================================

alter table public.symptom_entries
  add column if not exists symptom_notes jsonb not null default '{}'::jsonb;

-- Optional cleanup once you've confirmed the app works with the new column:
-- alter table public.symptom_entries drop column if exists note;
