// ============================================================
// FILL THESE IN from Supabase Dashboard → Project Settings → API
// SUPABASE_ANON_KEY is safe to be public — it only ever works
// within the limits set by the Row Level Security policies in
// supabase/schema.sql. Never put the "service_role" key here.
// ============================================================
const SUPABASE_URL = "https://synmlrjvutavlnqtebmh.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN5bm1scmp2dXRhdmxucXRlYm1oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTAzMTk4ODMsImV4cCI6MjEwNTg5NTg4M30.gvF9NrMuR69K_LVAqeNBMAzSi6_R-mFSgpouihUzbe0";

// The deployed admin-api Edge Function URL (see README "Deploy the Edge Function")
const ADMIN_API_URL = `${SUPABASE_URL}/functions/v1/admin-api`;

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
