// ============================================================
// FILL THESE IN from Supabase Dashboard → Project Settings → API
// SUPABASE_ANON_KEY is safe to be public — it only ever works
// within the limits set by the Row Level Security policies in
// supabase/schema.sql. Never put the "service_role" key here.
// ============================================================
const SUPABASE_URL = 'https://synmlrjvutavlnqtebmh.supabase.co';
const SUPABASE_ANON_KEY = 'sb_publishable_LqJo3_9AjaKR_4sr_z4tHA_VFwaqclU';


// The deployed admin-api Edge Function URL (see README "Deploy the Edge Function")
const ADMIN_API_URL = `${SUPABASE_URL}/functions/v1/admin-api`;

const supabaseClient = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
