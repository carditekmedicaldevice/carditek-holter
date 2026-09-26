// ============================================================
// Shared helpers used by patient.html and admin.html
// ============================================================

const WHATSAPP_NUMBER = "919110600616"; // country code 91 + 9110600616

function whatsappLink(patientName, patientCode) {
  const text = `Hi, this is ${patientName} (ID: ${patientCode}). I need help regarding my Holter monitoring.`;
  return `https://wa.me/${WHATSAPP_NUMBER}?text=${encodeURIComponent(text)}`;
}

function injectWhatsappFab(patientName, patientCode) {
  const a = document.createElement("a");
  a.className = "whatsapp-fab";
  a.href = whatsappLink(patientName, patientCode);
  a.target = "_blank";
  a.rel = "noopener";
  a.setAttribute("aria-label", "Get help on WhatsApp");
  a.innerHTML = `<svg viewBox="0 0 32 32" fill="white" xmlns="http://www.w3.org/2000/svg">
    <path d="M16.02 3C9.4 3 4 8.36 4 14.98c0 2.17.58 4.29 1.68 6.16L4 29l8.04-1.65a12.98 12.98 0 0 0 3.98.62h.01c6.62 0 12.02-5.36 12.02-11.98C28.05 8.37 22.65 3 16.02 3Zm0 21.83h-.01a10 10 0 0 1-5.1-1.4l-.37-.22-4.77.98.98-4.66-.24-.38a9.8 9.8 0 0 1-1.5-5.2c0-5.44 4.45-9.87 9.93-9.87 2.65 0 5.14 1.04 7.01 2.92a9.79 9.79 0 0 1 2.9 6.96c0 5.44-4.45 9.87-9.83 9.87Zm5.42-7.39c-.3-.15-1.76-.87-2.03-.97-.27-.1-.47-.15-.67.15-.2.3-.77.97-.94 1.17-.17.2-.35.22-.65.07-.3-.15-1.24-.46-2.36-1.46a8.85 8.85 0 0 1-1.63-2.03c-.17-.3-.02-.46.13-.6.13-.13.3-.35.45-.52.15-.17.2-.3.3-.5.1-.2.05-.37-.02-.52-.07-.15-.67-1.62-.92-2.22-.24-.58-.49-.5-.67-.51h-.57c-.2 0-.52.07-.79.37-.27.3-1.04 1.02-1.04 2.48 0 1.46 1.07 2.87 1.22 3.07.15.2 2.1 3.2 5.08 4.49.71.3 1.26.49 1.7.63.71.23 1.36.2 1.87.12.57-.08 1.76-.72 2-1.42.25-.7.25-1.3.17-1.42-.07-.13-.27-.2-.57-.35Z"/>
  </svg>`;
  document.body.appendChild(a);
}

function showMsg(el, text, type = "error") {
  el.textContent = text;
  el.className = `msg ${type}`;
  el.style.display = "block";
}

function hideMsg(el) {
  el.style.display = "none";
}

async function requireSession(expectedRole) {
  const loginPage = expectedRole === "admin" ? "admin-login.html" : "index.html";
  const { data: { session } } = await supabaseClient.auth.getSession();
  if (!session) {
    window.location.href = loginPage;
    return null;
  }
  const { data: profile } = await supabaseClient
    .from("profiles")
    .select("role, must_change_password")
    .eq("id", session.user.id)
    .single();

  if (!profile || profile.role !== expectedRole) {
    await supabaseClient.auth.signOut();
    window.location.href = loginPage;
    return null;
  }
  return { session, profile };
}

async function logout(destination) {
  await supabaseClient.auth.signOut();
  window.location.href = destination || "index.html";
}

function injectFooter(showStaffLink) {
  const f = document.createElement("footer");
  f.className = "site-footer";
  f.innerHTML = `
    <div class="company">Carditek Medical Devices Pvt Ltd</div>
    <div class="contact">Contact: 91106 00616</div>
    <div class="emergency">Emergency only: 98441 10277</div>
    ${showStaffLink ? '<a class="quiet-link" href="admin-login.html">Staff login</a>' : ""}
  `;
  document.body.appendChild(f);
}

function fmtDate(d) {
  if (!d) return "—";
  return new Date(d).toLocaleDateString(undefined, { year: "numeric", month: "short", day: "numeric" });
}

function fmtDateTime(d) {
  if (!d) return "—";
  return new Date(d).toLocaleString(undefined, { year: "numeric", month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" });
}
