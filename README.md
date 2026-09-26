# Carditek Holter Patient Portal — Setup Guide

Three pages, plain HTML/CSS/JS (no build step), backed by Supabase, meant to be
hosted free on GitHub Pages.

```
index.html        → patient login + self-registration (public entry point)
admin-login.html  → separate, low-visibility admin login (not shown to patients)
patient.html      → patient dashboard (profile, symptom log, history, WhatsApp help)
admin.html        → admin dashboard (patient list, add/edit patient, exports, password reset)
css/style.css     → shared styling
js/                → shared logic + Supabase config
assets/            → your logo + favicon (already dropped in)
supabase/          → database schema, migrations, and the one server-side function
```

**If you already deployed an earlier version:** also run
`supabase/migrations/001_symptom_notes.sql` in the SQL Editor — it adds the
column the new per-symptom detail boxes need. Everything else in this update
is just HTML/CSS/JS, so re-pushing the files to GitHub is all that's needed
for the rest.

Do these steps in order. None of it needs you to write code — just fill in
values and copy/paste commands.

## 1. Create your Supabase project
1. Go to supabase.com → New project.
2. Wait for it to finish provisioning (~2 minutes).

## 2. Create the database tables
1. In your Supabase project: **SQL Editor → New query**.
2. Open `supabase/schema.sql` from this folder, paste the whole thing in, click **Run**.
   This creates the tables and the security rules that keep one patient from
   ever seeing another patient's data.

## 3. Turn off email confirmation
Patients log in with their phone number, not a real inbox, so Supabase can't send
them a confirmation email.
1. **Authentication → Providers → Email**.
2. Turn **Confirm email** OFF. Save.

## 4. Create your one admin account
1. **Authentication → Users → Add user**.
2. Enter your own email and a strong password. Turn **Auto Confirm User** ON. Create.
3. Back in **SQL Editor**, run this (swap in the email you just used):
   ```sql
   update public.profiles set role = 'admin'
   where id = (select id from auth.users where email = 'YOUR_ADMIN_EMAIL_HERE');
   ```
This is the only way an admin account gets created — there's no public
"admin sign-up" on the site itself. Anyone visiting the site can only ever
register as a patient, which is what keeps patient data safe from randoms.
Admin logs in at `admin-login.html`, a separate page not linked anywhere
prominent on the patient-facing site (there's a small "Staff login" link in
the footer). Bookmark that page's URL for yourself.

## 5. Deploy the one server-side function
Creating a patient's login and resetting a patient's password both need a
secret key that must never sit inside the website's own code. That one piece
of logic runs on Supabase's servers instead — this step deploys it there.

1. Install the Supabase CLI (one time): `npm install -g supabase`
2. From this folder: `supabase login`
3. `supabase link --project-ref YOUR-PROJECT-REF` (find the ref in your project's URL or Settings → General)
4. `supabase functions deploy admin-api`

That's it — no secrets to copy in manually, Supabase provides them to the function automatically.

## 6. Connect the website to your project
Open `js/supabase-client.js` and fill in the two values from
**Project Settings → API**:
```js
const SUPABASE_URL = "https://xxxxxxxx.supabase.co";
const SUPABASE_ANON_KEY = "eyJ...";
```
The anon key is safe to be public — the database rules from step 2 are what
actually enforce privacy, not this key being secret.

## 7. Put your real logo in place (optional)
Your logo is already in `assets/carditek-logo.png`. If you get an updated
version later, just replace that file with the same name — nothing else
needs to change.

## 8. Test it locally
Open `index.html` in a browser (or run `python3 -m http.server` in this folder
and visit `http://localhost:8000`). Register a test patient, log in as admin,
check the two accounts can see the right things.

## 9. Put it on GitHub Pages
1. Create a new GitHub repo, push everything in this folder to it.
2. Repo → **Settings → Pages** → Source: deploy from branch → `main` / root.
3. Your site is live at `https://yourusername.github.io/reponame/`.

---

## How the pieces fit together

| Concern | How it's handled |
|---|---|
| Patient login | Phone number → matched to a private auto-generated email behind the scenes |
| Admin login | Real email + password, account created once by you in Supabase, not via the site |
| Data privacy | Supabase Row Level Security — a patient's account can only ever read/write their own rows, enforced by the database itself, not by the website's code |
| Forgot password | Admin clicks "Reset password" on that patient → a fresh temporary password is generated → admin reads it to them on the phone → they must set their own on next login |
| Patient added by admin | "Add patient" on the admin page creates their login and record together, gives you a temp password to hand over |
| Patient self-registers | Public "New patient" tab on the login page — same underlying record, just started by the patient instead |
| Symptom logging | Choice-based (tap to select) rather than free text, so entries stay consistent and easy to scan |
| Exports | CSV and a letterhead PDF (your logo, company name, patient details, entry log), generated directly in the browser |
| WhatsApp help | Floating button on the patient page → opens WhatsApp to 9110600616 with the patient's name and ID pre-filled |

## Things worth deciding before you go live with real patients
- **Consent record** — a checkbox exists at registration; if you need a signed/printed consent form too, that's outside this system for now.
- **Emergency number (98441 10277)** — not wired into the app yet; tell me where you want it shown (e.g. on the WhatsApp button as a fallback, or a "call now" link) and I'll add it.
- **Study status "completed"** — currently just hides the symptom form and shows a message; if you want the admin toggle to also auto-email/notify anyone, that's not built yet.
- **Backups** — Supabase backs up your database on paid plans; worth checking your plan's backup policy once real patient data is in there.
