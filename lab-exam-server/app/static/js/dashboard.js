// ============================================================
// Korelium Lab — Admin Dashboard JS
// ============================================================

const BASE = '';
let currentSessionId = null;
let monitorTimer = null;
let allStudents = [];   // cached from API
let parsedRows = [];    // CSV parse result
let currentYear = null;
let currentSection = null;

// ── API ───────────────────────────────────────────────────
async function api(method, path, body = null) {
  const opts = { method, headers: { 'Content-Type': 'application/json' } };
  if (body !== null) opts.body = JSON.stringify(body);
  const res = await fetch(BASE + path, opts);
  if (!res.ok) {
    const e = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(e.detail || res.statusText);
  }
  return res.status === 204 ? null : res.json();
}

// ── Toast ─────────────────────────────────────────────────
function toast(msg, type = 'inf', ms = 3500) {
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.innerHTML = `<span>${msg}</span>`;
  document.getElementById('toasts').appendChild(el);
  setTimeout(() => el.remove(), ms);
}

// ── Time ──────────────────────────────────────────────────
function fmt(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('en-IN', {
    timeZone: 'Asia/Kolkata', day: '2-digit', month: 'short',
    hour: '2-digit', minute: '2-digit'
  });
}
function since(iso) {
  if (!iso) return '—';
  const s = Math.floor((Date.now() - new Date(iso)) / 1000);
  if (s < 60) return `${s}s ago`;
  if (s < 3600) return `${Math.floor(s/60)}m ago`;
  return `${Math.floor(s/3600)}h ago`;
}

function esc(s) {
  return String(s ?? '').replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
}

// ── Nav ───────────────────────────────────────────────────
function showView(name) {
  document.querySelectorAll('.view').forEach(v => v.classList.add('hidden'));
  document.querySelectorAll('.nav-item').forEach(b => b.classList.remove('active'));
  const views = { sessions: 'view-sessions', students: 'view-students' };
  const navs  = { sessions: 'navSessions',   students: 'navStudents' };
  if (views[name]) {
    document.getElementById(views[name]).classList.remove('hidden');
    document.getElementById(navs[name]).classList.add('active');
  }
  stopMonitor();
  if (name === 'sessions') loadSessions();
  if (name === 'students') loadStudentView();
}

// ════════════════════════════════════════════════════════
//  SESSIONS
// ════════════════════════════════════════════════════════
async function loadSessions() {
  const grid = document.getElementById('sessionsGrid');
  grid.innerHTML = `<div class="loading-state"><div class="spinner"></div> Loading…</div>`;
  try {
    const sessions = await api('GET', '/api/v1/admin/sessions');
    renderSessionsGrid(sessions);
  } catch (e) {
    grid.innerHTML = `<div class="loading-state" style="color:var(--red)">Failed: ${esc(e.message)}</div>`;
  }
}

const STATUS_ORDER = { active: 0, draft: 1, closed: 2 };
function renderSessionsGrid(sessions) {
  const grid = document.getElementById('sessionsGrid');
  if (!sessions.length) {
    grid.innerHTML = `<div class="loading-state" style="color:var(--dim)">No sessions yet — create one!</div>`;
    return;
  }
  sessions.sort((a, b) => (STATUS_ORDER[a.status] ?? 3) - (STATUS_ORDER[b.status] ?? 3));
  grid.innerHTML = sessions.map(s => `
    <div class="session-card" onclick="openSession(${s.id})">
      <div class="sc-title">${esc(s.title)}</div>
      <div class="sc-meta">
        <span class="badge badge-${s.status}">${s.status}</span>
        <span class="sc-dept">${esc(s.department)}</span>
        <span class="sc-dept">${s.language.toUpperCase()}</span>
      </div>
      <div class="sc-footer">
        <span class="sc-counts">${s.question_count} questions · ${s.student_count} students</span>
        <span class="sc-counts">${s.duration_minutes} min</span>
      </div>
    </div>
  `).join('');
}

async function openSession(id) {
  currentSessionId = id;
  document.querySelectorAll('.view').forEach(v => v.classList.add('hidden'));
  document.getElementById('view-session-detail').classList.remove('hidden');
  try {
    const s = await api('GET', `/api/v1/admin/session/${id}`);
    renderSessionDetail(s);
    switchDetailTab('monitor');
    startMonitor();
  } catch (e) { toast(e.message, 'err'); }
}

function renderSessionDetail(s) {
  document.getElementById('bcTitle').textContent = s.title;
  document.getElementById('dTitle').textContent = s.title;
  const sb = document.getElementById('dStatus');
  sb.className = `badge badge-${s.status}`; sb.textContent = s.status;
  document.getElementById('dMeta').innerHTML = [
    `<span>${esc(s.department)}</span>`,
    `<span>${s.language.toUpperCase()}</span>`,
    `<span>${s.duration_minutes} min</span>`,
    s.start_time ? `<span>Start: ${fmt(s.start_time)}</span>` : '',
    s.end_time   ? `<span>End: ${fmt(s.end_time)}</span>` : '',
  ].filter(Boolean).join('');
  document.getElementById('dActivate').style.display = s.status === 'draft'  ? '' : 'none';
  document.getElementById('dClose').style.display    = s.status === 'active' ? '' : 'none';
}

function switchDetailTab(name) {
  document.querySelectorAll('#view-session-detail .tab').forEach(t => t.classList.toggle('active', t.dataset.tab === name));
  document.querySelectorAll('#view-session-detail .tab-content').forEach(c => c.classList.add('hidden'));
  document.getElementById(`dtab-${name}`).classList.remove('hidden');
  stopMonitor();
  if (name === 'monitor')     startMonitor();
  if (name === 'submissions') loadSubmissions();
}

// Session actions
async function setStatus(status) {
  try {
    await api('PUT', `/api/v1/admin/session/${currentSessionId}/status`, { status });
    toast(`Session ${status}`, 'ok');
    const s = await api('GET', `/api/v1/admin/session/${currentSessionId}`);
    renderSessionDetail(s);
    loadSessions();
  } catch (e) { toast(e.message, 'err'); }
}

async function deleteSession() {
  if (!confirm('Delete this session and all its data?')) return;
  try {
    await api('DELETE', `/api/v1/admin/session/${currentSessionId}`);
    toast('Session deleted', 'ok');
    showView('sessions');
  } catch (e) { toast(e.message, 'err'); }
}

// New session modal
function openNewSessionModal() {
  document.getElementById('modalBackdrop').classList.remove('hidden');
  document.getElementById('m_title').focus();
}
function closeModal() { document.getElementById('modalBackdrop').classList.add('hidden'); }
async function createSession() {
  const title = document.getElementById('m_title').value.trim();
  const dept  = document.getElementById('m_dept').value.trim();
  const dur   = parseInt(document.getElementById('m_dur').value) || 60;
  if (!title || !dept) { toast('Title and department required', 'err'); return; }
  try {
    const s = await api('POST', '/api/v1/admin/session', { title, department: dept, duration_minutes: dur, language: 'python' });
    toast('Session created', 'ok'); closeModal();
    document.getElementById('m_title').value = '';
    document.getElementById('m_dept').value  = '';
    document.getElementById('m_dur').value   = '60';
    await loadSessions();
    openSession(s.id);
  } catch (e) { toast(e.message, 'err'); }
}

// ── Live Monitor ──────────────────────────────────────────
function startMonitor() { fetchMonitor(); monitorTimer = setInterval(fetchMonitor, 5000); }
function stopMonitor()  { if (monitorTimer) { clearInterval(monitorTimer); monitorTimer = null; } }

async function fetchMonitor() {
  if (!currentSessionId) return;
  try {
    const d = await api('GET', `/api/v1/admin/session/${currentSessionId}/monitor`);
    document.getElementById('monStats').innerHTML = `
      <div class="stat-chip"><b>${d.total_students}</b> <span style="color:var(--muted)">total</span></div>
      <div class="stat-chip"><b style="color:var(--green)">${d.online_count}</b> <span style="color:var(--muted)">online</span></div>
      <div class="stat-chip"><b style="color:var(--accent)">${d.submitted_count}</b> <span style="color:var(--muted)">submitted</span></div>
    `;
    const tbody = document.getElementById('monitorBody');
    if (!d.students.length) { tbody.innerHTML = `<tr><td colspan="7" class="empty-cell">No students assigned</td></tr>`; return; }
    tbody.innerHTML = d.students.map(s => `<tr>
      <td>${esc(s.name)}</td>
      <td class="mono">${esc(s.registration_number)}</td>
      <td>${s.machine_ip ? `${esc(s.machine_name||'')} <span style="color:var(--dim);font-size:11px">${esc(s.machine_ip)}</span>` : '<span style="color:var(--dim)">—</span>'}</td>
      <td><span class="badge badge-${s.is_online ? 'online' : 'offline'}">${s.is_online ? 'Online' : 'Offline'}</span></td>
      <td>${s.run_count}</td>
      <td>${s.has_submitted ? `<span class="badge badge-sub">Submitted</span>` : '<span style="color:var(--dim)">—</span>'}</td>
      <td style="color:var(--muted);font-size:12px">${since(s.last_seen_at)}</td>
    </tr>`).join('');
  } catch {/* silent */}
}

// ── Submissions ───────────────────────────────────────────
async function loadSubmissions() {
  const tbody = document.getElementById('submissionsBody');
  tbody.innerHTML = `<tr><td colspan="6" class="empty-cell"><div class="spinner" style="margin:auto"></div></td></tr>`;
  try {
    const subs = await api('GET', `/api/v1/admin/session/${currentSessionId}/submissions`);
    if (!subs.length) { tbody.innerHTML = `<tr><td colspan="6" class="empty-cell">No submissions yet</td></tr>`; return; }
    const COLORS = { normal:'badge-sub', auto_tab_switch:'badge badge-draft', auto_timer:'badge-closed', resubmission:'badge-draft' };
    tbody.innerHTML = subs.map(s => `<tr>
      <td>${esc(s.student_name||'—')}</td>
      <td class="mono">${esc(s.registration_number||'—')}</td>
      <td style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap">${esc(s.question_title||'—')}</td>
      <td class="mono" style="color:${s.exit_code===0?'var(--green)':'var(--red)'}">${s.exit_code??'—'}</td>
      <td><span class="badge ${COLORS[s.submission_type]||'badge-draft'}">${esc(s.submission_type||'normal')}</span></td>
      <td style="color:var(--muted);font-size:12px">${fmt(s.submitted_at)}</td>
    </tr>`).join('');
  } catch (e) {
    tbody.innerHTML = `<tr><td colspan="6" class="empty-cell" style="color:var(--red)">Failed to load</td></tr>`;
  }
}

// ════════════════════════════════════════════════════════
//  STUDENTS — YEAR/SECTION DRILL-DOWN
// ════════════════════════════════════════════════════════
const YEAR_LABELS = { '1st': '1st Year', '2nd': '2nd Year', '3rd': '3rd Year', '4th': '4th Year' };
const YEAR_ORDER  = ['1st', '2nd', '3rd', '4th'];

async function loadStudentView() {
  const grid = document.getElementById('yearCards');
  grid.innerHTML = `<div class="loading-state"><div class="spinner"></div> Loading…</div>`;
  document.getElementById('sectionView').classList.add('hidden');
  document.getElementById('registerView').classList.add('hidden');
  try {
    allStudents = await api('GET', '/api/v1/admin/students');
    renderYearCards(allStudents);
  } catch (e) {
    grid.innerHTML = `<div class="loading-state" style="color:var(--red)">Failed: ${esc(e.message)}</div>`;
  }
}

function renderYearCards(students) {
  const grid = document.getElementById('yearCards');
  // Count by year
  const byYear = {};
  students.forEach(s => {
    const y = s.year || 'Unknown';
    byYear[y] = (byYear[y] || 0) + 1;
  });

  const ordinals = ['1st','2nd','3rd','4th'];
  const cards = ordinals.map((y, i) => {
    const count = byYear[y] || 0;
    const num = ['1','2','3','4'][i];
    const suffix = ['st','nd','rd','th'][i];
    const empty = count === 0;
    return `<div class="year-card ${empty ? 'year-card-empty' : ''}" ${empty ? '' : `onclick="openYear('${y}')"`}>
      <span class="year-card-num">${num}<sup style="font-size:16px;font-weight:600;opacity:.7">${suffix}</sup></span>
      <div class="year-card-label">Year</div>
      <div class="year-card-count">${empty ? 'No students' : count + ' students'}</div>
    </div>`;
  }).join('');

  // Any other years not in standard list
  const extra = Object.keys(byYear).filter(y => !ordinals.includes(y));
  const extraCards = extra.map(y => `
    <div class="year-card" onclick="openYear('${esc(y)}')">
      <span class="year-card-num" style="font-size:22px">${esc(y)}</span>
      <div class="year-card-label">Year</div>
      <div class="year-card-count">${byYear[y]} students</div>
    </div>
  `).join('');

  grid.innerHTML = cards + extraCards;
}

function openYear(year) {
  currentYear = year;
  const students = allStudents.filter(s => s.year === year);

  // Group by section
  const bySection = {};
  students.forEach(s => {
    const sec = s.section || '?';
    if (!bySection[sec]) bySection[sec] = [];
    bySection[sec].push(s);
  });

  document.getElementById('sectionTitle').textContent = `${year} Year — Select a Section`;
  const sectCards = Object.keys(bySection).sort().map(sec => `
    <div class="section-card" onclick="openSection('${esc(sec)}')">
      <div class="sec-letter">Section ${esc(sec)}</div>
      <div class="sec-count">${bySection[sec].length} students</div>
    </div>
  `).join('');

  document.getElementById('sectionCards').innerHTML = sectCards;
  document.getElementById('sectionView').classList.remove('hidden');
  document.getElementById('registerView').classList.add('hidden');
  document.getElementById('sectionView').scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function closeSectionView() {
  document.getElementById('sectionView').classList.add('hidden');
  document.getElementById('registerView').classList.add('hidden');
  currentYear = null; currentSection = null;
}

function openSection(section) {
  currentSection = section;
  const students = allStudents.filter(s => s.year === currentYear && s.section === section);
  document.getElementById('registerTitle').textContent = `${currentYear} Year · Section ${section} — ${students.length} students`;
  renderRegister(students);
  document.getElementById('registerView').classList.remove('hidden');
  document.getElementById('registerView').scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function closeRegisterView() {
  document.getElementById('registerView').classList.add('hidden');
  currentSection = null;
}

function renderRegister(students) {
  const tbody = document.getElementById('registerBody');
  if (!students.length) {
    tbody.innerHTML = `<tr><td colspan="7" class="empty-cell">No students</td></tr>`; return;
  }
  tbody.innerHTML = students.map((s, i) => `<tr>
    <td style="color:var(--muted)">${i + 1}</td>
    <td class="mono">${esc(s.registration_number)}</td>
    <td>${esc(s.name)}</td>
    <td>${esc(s.department)}</td>
    <td>${esc(s.section)}</td>
    <td><span class="badge badge-${s.enabled ? 'enabled' : 'disabled'}">${s.enabled ? 'Active' : 'Disabled'}</span></td>
    <td>
      <button class="row-act ${s.enabled ? 'warn' : ''}" onclick="${s.enabled ? 'disableS' : 'enableS'}('${esc(s.registration_number)}')">
        ${s.enabled ? 'Disable' : 'Enable'}
      </button>
      <button class="row-act danger" onclick="deleteS('${esc(s.registration_number)}')">Delete</button>
    </td>
  </tr>`).join('');
}

async function enableS(reg)  { try { await api('PUT',`/api/v1/admin/student/${reg}/enable`);  await reloadSection(); } catch(e){toast(e.message,'err');} }
async function disableS(reg) { try { await api('PUT',`/api/v1/admin/student/${reg}/disable`); await reloadSection(); } catch(e){toast(e.message,'err');} }
async function deleteS(reg)  {
  if (!confirm(`Delete ${reg}?`)) return;
  try { await api('DELETE',`/api/v1/admin/student/${reg}`); toast('Deleted','ok'); await reloadSection(); } catch(e){toast(e.message,'err');}
}
async function reloadSection() {
  allStudents = await api('GET', '/api/v1/admin/students');
  renderYearCards(allStudents);
  if (currentYear && currentSection) openSection(currentSection);
}

// ════════════════════════════════════════════════════════
//  CSV UPLOAD
// ════════════════════════════════════════════════════════
function toggleCsvUpload() {
  const p = document.getElementById('csvPanel');
  p.classList.toggle('hidden');
}

function handleFile(file) {
  if (!file || !file.name.endsWith('.csv')) { toast('Please select a CSV file', 'err'); return; }
  const reader = new FileReader();
  reader.onload = e => {
    try { parsedRows = parseStudentCSV(e.target.result); renderCsvPreview(); }
    catch (err) { toast(err.message, 'err'); }
  };
  reader.readAsText(file);
}

// Parse the college CSV format:
// department, section, register number, name, year
// → maps to API: registration_number, name, department, section, year, batch
function parseStudentCSV(text) {
  const lines = text.trim().split('\n').map(l => l.trim()).filter(Boolean);
  if (lines.length < 2) throw new Error('CSV is empty');

  // Normalize headers
  const headers = lines[0].split(',').map(h => h.trim().toLowerCase().replace(/\s+/g,'_').replace(/[^a-z_]/g,''));
  // Accept both "register_number" and "registration_number"
  const regIdx  = headers.findIndex(h => h.includes('register'));
  const nameIdx = headers.findIndex(h => h === 'name');
  const deptIdx = headers.findIndex(h => h === 'department' || h === 'dept');
  const secIdx  = headers.findIndex(h => h === 'section');
  const yearIdx = headers.findIndex(h => h === 'year');

  const missing = [['Register No.', regIdx], ['Name', nameIdx], ['Department', deptIdx], ['Section', secIdx], ['Year', yearIdx]]
    .filter(([, i]) => i === -1).map(([n]) => n);
  if (missing.length) throw new Error(`Missing columns: ${missing.join(', ')}`);

  const rows = [];
  for (let i = 1; i < lines.length; i++) {
    const vals = splitCsvLine(lines[i]);
    const reg  = (vals[regIdx]  || '').trim();
    const name = (vals[nameIdx] || '').trim();
    const dept = (vals[deptIdx] || '').trim();
    const sec  = (vals[secIdx]  || '').trim();
    const year = (vals[yearIdx] || '').trim();
    if (!reg || !name) continue; // skip empty rows

    // Derive batch from register number (e.g. 2117240020001 → "24" → "2024-28")
    const batch = deriveBatch(reg, year);

    rows.push({ registration_number: reg, name, department: dept, section: sec, year, batch, enabled: true });
  }
  if (!rows.length) throw new Error('No valid rows found in CSV');
  return rows;
}

function deriveBatch(reg, year) {
  // Register format: 2117240020001 — digits 5-6 are the year joined (24 = 2024)
  const m = reg.match(/^\d{4}(\d{2})\d/);
  if (!m) return 'Unknown';
  const joinedYear = 2000 + parseInt(m[1]);
  // If student is 2nd year, they joined 1 year ago, etc.
  const yearOffset = { '1st': 0, '2nd': 1, '3rd': 2, '4th': 3 };
  const offset = yearOffset[year] ?? 0;
  const entryYear = joinedYear - offset;  // not always accurate but best guess
  // Actually just use the join year from the register number directly
  return `${joinedYear}-${joinedYear + 4}`;
}

function splitCsvLine(line) {
  const vals = []; let cur = ''; let inQ = false;
  for (const ch of line) {
    if (ch === '"') { inQ = !inQ; }
    else if (ch === ',' && !inQ) { vals.push(cur); cur = ''; }
    else cur += ch;
  }
  vals.push(cur);
  return vals;
}

function renderCsvPreview() {
  const cols   = ['registration_number','name','department','section','year'];
  const labels = ['Reg. No.','Name','Dept','Section','Year'];
  const preview = document.getElementById('csvPreview');
  preview.innerHTML = `<table>
    <thead><tr>${labels.map(l=>`<th>${l}</th>`).join('')}</tr></thead>
    <tbody>
      ${parsedRows.slice(0,12).map(r=>`<tr>${cols.map(c=>`<td>${esc(r[c]||'')}</td>`).join('')}</tr>`).join('')}
      ${parsedRows.length > 12 ? `<tr><td colspan="5" style="text-align:center;color:var(--muted);padding:8px">…and ${parsedRows.length-12} more</td></tr>` : ''}
    </tbody>
  </table>`;
  preview.classList.remove('hidden');
  document.getElementById('csvConfirm').classList.remove('hidden');
}

async function doUpload() {
  if (!parsedRows.length) return;
  const btn = document.getElementById('uploadBtn');
  btn.disabled = true; btn.textContent = 'Uploading…';
  try {
    const r = await api('POST', '/api/v1/admin/students/bulk', { students: parsedRows });
    toast(`✓ ${r.created} created, ${r.skipped} skipped${r.errors.length ? ` · ${r.errors.length} errors` : ''}`,
          r.errors.length ? 'inf' : 'ok', 5000);
    resetCsv();
    loadStudentView();
  } catch (e) { toast(e.message, 'err'); }
  finally { btn.disabled = false; btn.textContent = 'Upload Students'; }
}

function resetCsv() {
  parsedRows = [];
  document.getElementById('csvPanel').classList.add('hidden');
  document.getElementById('csvPreview').classList.add('hidden');
  document.getElementById('csvConfirm').classList.add('hidden');
  document.getElementById('csvInput').value = '';
}

// ════════════════════════════════════════════════════════
//  SERVER STATUS
// ════════════════════════════════════════════════════════
async function checkServer() {
  try {
    await fetch('/api/v1/health');
    document.getElementById('sdot').className = 'sdot on';
    document.getElementById('slabel').textContent = 'Server online';
  } catch {
    document.getElementById('sdot').className = 'sdot off';
    document.getElementById('slabel').textContent = 'Server offline';
  }
}

// ════════════════════════════════════════════════════════
//  INIT
// ════════════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {
  // Nav
  document.getElementById('navSessions').addEventListener('click', () => showView('sessions'));
  document.getElementById('navStudents').addEventListener('click', () => showView('students'));

  // Session detail
  document.getElementById('dActivate').addEventListener('click', () => setStatus('active'));
  document.getElementById('dClose').addEventListener('click', () => setStatus('closed'));
  document.getElementById('dDelete').addEventListener('click', deleteSession);

  // Session detail tabs
  document.querySelectorAll('#view-session-detail .tab').forEach(t => {
    t.addEventListener('click', () => switchDetailTab(t.dataset.tab));
  });

  // Modal
  document.getElementById('modalBackdrop').addEventListener('click', e => {
    if (e.target === document.getElementById('modalBackdrop')) closeModal();
  });

  // CSV
  const inp = document.getElementById('csvInput');
  inp.addEventListener('change', () => handleFile(inp.files[0]));
  const dz = document.getElementById('dropZone');
  dz.addEventListener('click', () => inp.click());
  dz.addEventListener('dragover', e => { e.preventDefault(); dz.classList.add('over'); });
  dz.addEventListener('dragleave', () => dz.classList.remove('over'));
  dz.addEventListener('drop', e => { e.preventDefault(); dz.classList.remove('over'); handleFile(e.dataTransfer.files[0]); });

  // Boot
  checkServer();
  setInterval(checkServer, 15000);
  showView('sessions');
});
