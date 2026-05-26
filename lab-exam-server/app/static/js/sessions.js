// ============================================================
// File: app/static/js/sessions.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Admin dashboard — Sessions module.
//              Manages: exam sessions grid, session detail view,
//              live student monitor (auto-refresh 5s),
//              submissions table, and new-session modal.
// Depends on: common.js
// ============================================================

let currentSessionId = null;
let monitorTimer = null;

const STATUS_ORDER = { active: 0, draft: 1, closed: 2 };

// ════════════════════════════════════════════════════════
//  SESSIONS GRID
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

// ════════════════════════════════════════════════════════
//  SESSION DETAIL
// ════════════════════════════════════════════════════════
async function openSession(id) {
  currentSessionId = id;
  document.querySelectorAll('.view').forEach(v => v.classList.add('hidden'));
  document.getElementById('view-session-detail').classList.remove('hidden');
  try {
    const s = await api('GET', `/api/v1/admin/session/${id}`);
    renderSessionDetail(s);
    switchDetailTab('monitor');
    startMonitor();
  } catch (e) {
    toast(e.message, 'err');
  }
}

function renderSessionDetail(s) {
  document.getElementById('bcTitle').textContent = s.title;
  document.getElementById('dTitle').textContent  = s.title;

  const sb = document.getElementById('dStatus');
  sb.className   = `badge badge-${s.status}`;
  sb.textContent = s.status;

  document.getElementById('dMeta').innerHTML = [
    `<span>${esc(s.department)}</span>`,
    `<span>${s.language.toUpperCase()}</span>`,
    `<span>${s.duration_minutes} min</span>`,
    s.start_time ? `<span>Start: ${fmt(s.start_time)}</span>` : '',
    s.end_time   ? `<span>End: ${fmt(s.end_time)}</span>`   : '',
  ].filter(Boolean).join('');

  document.getElementById('dActivate').style.display = s.status === 'draft'  ? '' : 'none';
  document.getElementById('dClose').style.display    = s.status === 'active' ? '' : 'none';
}

function switchDetailTab(name) {
  document.querySelectorAll('#view-session-detail .tab').forEach(t => {
    t.classList.toggle('active', t.dataset.tab === name);
  });
  document.querySelectorAll('#view-session-detail .tab-content').forEach(c => {
    c.classList.add('hidden');
  });
  document.getElementById(`dtab-${name}`).classList.remove('hidden');

  stopMonitor();
  if (name === 'monitor')     startMonitor();
  if (name === 'submissions') loadSubmissions();
}

// ── Session Status Actions ────────────────────────────────
async function setStatus(status) {
  try {
    await api('PUT', `/api/v1/admin/session/${currentSessionId}/status`, { status });
    toast(`Session ${status}`, 'ok');
    const s = await api('GET', `/api/v1/admin/session/${currentSessionId}`);
    renderSessionDetail(s);
  } catch (e) {
    toast(e.message, 'err');
  }
}

async function deleteSession() {
  if (!confirm('Delete this session and all its data?')) return;
  try {
    await api('DELETE', `/api/v1/admin/session/${currentSessionId}`);
    toast('Session deleted', 'ok');
    currentSessionId = null;
    showView('sessions');
  } catch (e) {
    toast(e.message, 'err');
  }
}

// ── New Session Modal ─────────────────────────────────────
function openNewSessionModal() {
  document.getElementById('modalBackdrop').classList.remove('hidden');
  document.getElementById('m_title').focus();
}
function closeModal() {
  document.getElementById('modalBackdrop').classList.add('hidden');
}

async function createSession() {
  const title = document.getElementById('m_title').value.trim();
  const dept  = document.getElementById('m_dept').value.trim();
  const dur   = parseInt(document.getElementById('m_dur').value) || 60;
  if (!title || !dept) { toast('Title and department required', 'err'); return; }
  try {
    const s = await api('POST', '/api/v1/admin/session', {
      title, department: dept, duration_minutes: dur, language: 'python',
    });
    toast('Session created', 'ok');
    closeModal();
    document.getElementById('m_title').value = '';
    document.getElementById('m_dept').value  = '';
    document.getElementById('m_dur').value   = '60';
    openSession(s.id);
  } catch (e) {
    toast(e.message, 'err');
  }
}

// ════════════════════════════════════════════════════════
//  LIVE MONITOR
// ════════════════════════════════════════════════════════
function startMonitor() {
  fetchMonitor();
  monitorTimer = setInterval(fetchMonitor, 5000);
}

function stopMonitor() {
  if (monitorTimer) { clearInterval(monitorTimer); monitorTimer = null; }
}

async function fetchMonitor() {
  if (!currentSessionId) return;
  try {
    const d = await api('GET', `/api/v1/admin/session/${currentSessionId}/monitor`);
    renderMonitor(d);
  } catch { /* silent on poll error */ }
}

function renderMonitor(d) {
  document.getElementById('monStats').innerHTML = `
    <div class="stat-chip"><b>${d.total_students}</b> <span style="color:var(--muted)">total</span></div>
    <div class="stat-chip"><b style="color:var(--green)">${d.online_count}</b> <span style="color:var(--muted)">online</span></div>
    <div class="stat-chip"><b style="color:var(--accent)">${d.submitted_count}</b> <span style="color:var(--muted)">submitted</span></div>
  `;
  const tbody = document.getElementById('monitorBody');
  if (!d.students.length) {
    tbody.innerHTML = `<tr><td colspan="7" class="empty-cell">No students assigned yet</td></tr>`;
    return;
  }
  tbody.innerHTML = d.students.map(s => `
    <tr>
      <td>${esc(s.name)}</td>
      <td class="mono">${esc(s.registration_number)}</td>
      <td>${s.machine_ip
          ? `${esc(s.machine_name || '')} <span style="color:var(--dim);font-size:11px">${esc(s.machine_ip)}</span>`
          : '<span style="color:var(--dim)">—</span>'}</td>
      <td><span class="badge badge-${s.is_online ? 'online' : 'offline'}">${s.is_online ? 'Online' : 'Offline'}</span></td>
      <td>${s.run_count}</td>
      <td>${s.has_submitted
          ? `<span class="badge badge-sub">Submitted</span>`
          : '<span style="color:var(--dim)">—</span>'}</td>
      <td style="color:var(--muted);font-size:12px">${since(s.last_seen_at)}</td>
    </tr>
  `).join('');
}

// ════════════════════════════════════════════════════════
//  SUBMISSIONS
// ════════════════════════════════════════════════════════
async function loadSubmissions() {
  const tbody = document.getElementById('submissionsBody');
  tbody.innerHTML = `<tr><td colspan="6" class="empty-cell"><div class="spinner" style="margin:auto"></div></td></tr>`;
  try {
    const subs = await api('GET', `/api/v1/admin/session/${currentSessionId}/submissions`);
    if (!subs.length) {
      tbody.innerHTML = `<tr><td colspan="6" class="empty-cell">No submissions yet</td></tr>`;
      return;
    }
    const TYPE_CLASS = {
      normal: 'badge-sub', auto_tab_switch: 'badge-draft',
      auto_timer: 'badge-closed', resubmission: 'badge-draft',
    };
    tbody.innerHTML = subs.map(s => `
      <tr>
        <td>${esc(s.student_name || '—')}</td>
        <td class="mono">${esc(s.registration_number || '—')}</td>
        <td style="max-width:180px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap"
            title="${esc(s.question_title || '')}">${esc(s.question_title || '—')}</td>
        <td class="mono" style="color:${s.exit_code === 0 ? 'var(--green)' : 'var(--red)'}">${s.exit_code ?? '—'}</td>
        <td><span class="badge ${TYPE_CLASS[s.submission_type] || 'badge-draft'}">${esc(s.submission_type || 'normal')}</span></td>
        <td style="color:var(--muted);font-size:12px">${fmt(s.submitted_at)}</td>
      </tr>
    `).join('');
  } catch {
    tbody.innerHTML = `<tr><td colspan="6" class="empty-cell" style="color:var(--red)">Failed to load</td></tr>`;
  }
}

// ════════════════════════════════════════════════════════
//  EVENT LISTENERS (sessions module)
// ════════════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {
  // Session detail actions
  document.getElementById('dActivate').addEventListener('click', () => setStatus('active'));
  document.getElementById('dClose').addEventListener('click',    () => setStatus('closed'));
  document.getElementById('dDelete').addEventListener('click',   deleteSession);

  // Session detail tabs
  document.querySelectorAll('#view-session-detail .tab').forEach(t => {
    t.addEventListener('click', () => switchDetailTab(t.dataset.tab));
  });

  // New session modal buttons
  document.getElementById('createSessionBtn').addEventListener('click', createSession);
  document.getElementById('cancelModalBtn').addEventListener('click', closeModal);
  document.getElementById('m_title').addEventListener('keydown', e => {
    if (e.key === 'Enter') createSession();
  });
});
