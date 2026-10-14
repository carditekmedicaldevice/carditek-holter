-- ============================================================
-- Migration 002 — only needed if you're seeing garbled text like
-- "0: {; 1: "; 2: P..." in the Symptom entries table.
--
-- That happens when the symptom_notes column ended up as type
-- "text" instead of "jsonb" (e.g. if it was added by hand through
-- Table Editor before running migration 001). Run the check below
-- first; only run the fix if it confirms the problem.
-- ============================================================

-- 1. Check the current column type:
select column_name, data_type
from information_schema.columns
where table_name = 'symptom_entries' and column_name = 'symptom_notes';

-- If data_type says "text" (not "jsonb"), run this to fix it —
-- safe to run even with existing rows, since the text already
-- holds valid JSON:
alter table public.symptom_entries
  alter column symptom_notes type jsonb using symptom_notes::jsonb;

alter table public.symptom_entries
  alter column symptom_notes set default '{}'::jsonb;
