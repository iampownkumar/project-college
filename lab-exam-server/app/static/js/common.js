// ============================================================
// File: app/static/js/common.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Shared state, auth helpers, toast, tab switching,
//              modal helpers, initial data loader, and RFC-4180
//              CSV parser used across all dashboard tabs.
// ============================================================

const API_BASE = '/api/v1/admin';
let adminKey  = localStorage.getItem('adminKey')  || '';
let staffCode = localStorage.getItem('staffCode') || '';

// ── Shared data caches ────────────────────────────────────────
let rawAllStudents   = [];
let rawAllSessions   = [];
let filteredStudents = [];
let filteredSessions = [];
let allDepts         = [];

// ── Undo-delete tracking ──────────────────────────────────────
let pendingDeletions = {}; // regNum → timeout ID

// ── Auth ──────────────────────────────────────────────────────
function getHeaders() {
    return {
        'Content-Type': 'application/json',
        'X-Admin-Key': adminKey
    };
}

async function performLogin() {
    const sc  = document.getElementById('staffCode').value;
    const pwd = document.getElementById('staffPassword').value;
    const err = document.getElementById('loginError');
    err.classList.add('hidden');

    try {
        const res  = await fetch('/api/v1/auth/admin/login', {
            method : 'POST',
            headers: { 'Content-Type': 'application/json' },
            body   : JSON.stringify({ staff_code: sc, password: pwd })
        });
        const data = await res.json();
        if (data.success) {
            adminKey  = data.admin_key;
            staffCode = data.staff_code;
            localStorage.setItem('adminKey',  adminKey);
            localStorage.setItem('staffCode', staffCode);
            document.getElementById('loginOverlay').classList.add('hidden');
            document.getElementById('mainApp').classList.remove('hidden');
            document.getElementById('staffNameDisplay').innerText = `Logged in as ${staffCode}`;
            loadInitialData();
        } else {
            err.innerText = data.message;
            err.classList.remove('hidden');
        }
    } catch {
        err.innerText = 'Connection error.';
        err.classList.remove('hidden');
    }
}

function logout() {
    localStorage.removeItem('adminKey');
    localStorage.removeItem('staffCode');
    location.reload();
}

// ── Toast ─────────────────────────────────────────────────────
function showToast(msg, isError = false) {
    const t = document.getElementById('toast');
    t.textContent = msg;
    t.className = `fixed top-4 right-4 px-4 py-2 rounded shadow-lg transition-opacity duration-300 z-50 ${isError ? 'bg-red-600' : 'bg-gray-800'} text-white`;
    t.style.opacity = '1';
    setTimeout(() => t.style.opacity = '0', 3000);
}

// ── Tab switching ─────────────────────────────────────────────
function switchTab(tabId) {
    document.querySelectorAll('.tab-content').forEach(el => el.classList.remove('active'));
    document.querySelectorAll('.tab-btn').forEach(el => {
        el.classList.remove('active', 'bg-blue-100', 'text-blue-700');
        el.classList.add('text-gray-600');
    });
    document.getElementById(tabId + '-tab').classList.add('active');

    const btn = document.querySelector(`.tab-btn[data-tab="${tabId}"]`);
    if (btn) {
        btn.classList.add('active', 'bg-blue-100', 'text-blue-700');
        btn.classList.remove('text-gray-600');
    }

    if (tabId === 'sessions')     renderSessions();
    if (tabId === 'departments')  loadDepartments();
    if (tabId === 'questions')    { /* questions.js bootstraps via session select */ }
    if (tabId === 'students')     { stuLevel = 0; stuSelectedYear = null; stuSelectedSection = null; stuShowLevel(0); renderStudents(); }
    if (tabId === 'monitor')      refreshMonitor();
    if (tabId === 'submissions')  refreshSubmissions();
}

// ── Modal helpers ─────────────────────────────────────────────
function openModal(id)  { document.getElementById(id).classList.remove('hidden'); }
function closeModal(id) { document.getElementById(id).classList.add('hidden'); }

// ── Date helpers ──────────────────────────────────────────────
function parseUTCDate(dateStr) {
    if (!dateStr) return null;
    const hasTz = dateStr.endsWith('Z') || dateStr.includes('+') ||
        (dateStr.includes('-') && dateStr.lastIndexOf('-') > 15);
    return new Date(hasTz ? dateStr : dateStr + 'Z');
}

// ── RFC-4180 CSV parser ───────────────────────────────────────
// Handles quoted fields with embedded newlines, CRLF, and escaped quotes.
function parseCsv(text) {
    // Normalise line endings
    text = text.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

    const rows = [];
    let i = 0;

    while (i <= text.length) {
        const row = [];

        while (i <= text.length) {
            if (i === text.length || (text[i] === '\n' && !row._inQuote)) {
                if (i < text.length) i++;
                break;
            }

            let cell = '';
            if (text[i] === '"') {
                i++; // skip opening quote
                while (i < text.length) {
                    if (text[i] === '"') {
                        if (text[i + 1] === '"') {
                            cell += '"'; i += 2; // escaped quote
                        } else {
                            i++; break; // closing quote
                        }
                    } else {
                        cell += text[i++];
                    }
                }
                if (text[i] === ',') i++;
            } else {
                while (i < text.length && text[i] !== ',' && text[i] !== '\n') {
                    cell += text[i++];
                }
                if (text[i] === ',') i++;
            }
            row.push(cell.trim());
        }

        if (row.length > 0 && row.some(c => c !== '')) rows.push(row);
    }
    return rows;
}

// ── Initial data load ─────────────────────────────────────────
async function loadInitialData() {
    try {
        const [sRes, stRes] = await Promise.all([
            fetch(`${API_BASE}/sessions`, { headers: getHeaders() }),
            fetch(`${API_BASE}/students`, { headers: getHeaders() })
        ]);

        if (sRes.status === 401 || stRes.status === 401) return logout();

        await loadDepartments();
        rawAllSessions   = await sRes.json();
        rawAllStudents   = await stRes.json();
        filteredSessions = rawAllSessions;
        filteredStudents = rawAllStudents;

        updateSessionDropdowns();
        updateStudentFilters();
        renderSessions();
        renderStudents();
    } catch (e) { console.error('Error loading initial data', e); }
}

function updateSessionDropdowns() {
    const selects = [
        { id: 'qSessionSelect', loader: loadQuestionsForSession },
        { id: 'aSessionSelect', loader: loadAssignmentsForSession },
        { id: 'mSessionSelect', loader: () => refreshMonitor() },
        { id: 'subSessionSelect', loader: () => refreshSubmissions() },
        { id: 'mqSession',     loader: null },
        { id: 'bqSession',     loader: null },
        { id: 'maSession',     loader: loadQuestionsForMultiAssign }
    ];

    selects.forEach(obj => {
        const el = document.getElementById(obj.id);
        if (!el) return;
        const oldVal = el.value;
        el.innerHTML = '<option value="">-- Select Session --</option>';
        let found = false;
        filteredSessions.forEach(s => {
            el.innerHTML += `<option value="${s.id}">[${s.id}] ${s.title} (${s.status})</option>`;
            if (s.id.toString() === oldVal) found = true;
        });
        if (found && oldVal) {
            el.value = oldVal;
            if (obj.loader) obj.loader(oldVal);
        } else if (obj.loader) {
            obj.loader('');
        }
    });
}

function updateStudentFilters() {
    const maList = document.getElementById('maStudents');
    if (maList) {
        maList.innerHTML = '';
        filteredStudents.forEach(s => {
            maList.innerHTML += `<option value="${s.registration_number}">${s.registration_number} - ${s.name} (${s.section})</option>`;
        });
    }
    renderStudents();
}

// ── Countdown ticker (runs every second) ──────────────────────
setInterval(() => {
    // Per-row session countdowns
    document.querySelectorAll('.session-countdown').forEach(el => {
        const endStr = el.getAttribute('data-end');
        if (!endStr) return;
        const diff = parseUTCDate(endStr).getTime() - Date.now();
        if (diff <= 0) {
            el.innerHTML = '<span class="text-red-600 font-bold">Expired</span>';
        } else {
            const h = Math.floor(diff / 3600000);
            const m = Math.floor((diff % 3600000) / 60000);
            const s = Math.floor((diff % 60000) / 1000);
            el.innerHTML = `<span class="text-green-600 font-bold font-mono text-sm">${h}h ${m}m ${s}s left</span>`;
        }
    });

    // Top-bar countdown + JS-side auto-close (server is authoritative but this keeps UI snappy)
    const activeSession = filteredSessions.find(s => s.status === 'active' && s.end_time);
    const topDiv   = document.getElementById('topActiveSession');
    const topCount = document.getElementById('topCountdown');
    if (activeSession) {
        const diff = parseUTCDate(activeSession.end_time).getTime() - Date.now();
        topDiv.classList.remove('hidden');
        if (diff <= 0) {
            topCount.innerText = 'EXPIRED';
            if (!window._autoClosingSession) {
                window._autoClosingSession = true;
                fetch(`${API_BASE}/session/${activeSession.id}/status`, {
                    method : 'PUT',
                    headers: getHeaders(),
                    body   : JSON.stringify({ status: 'closed' })
                }).then(() => {
                    showToast('Session auto-closed — time expired');
                    window._autoClosingSession = false;
                    loadInitialData();
                }).catch(() => { window._autoClosingSession = false; });
            }
        } else {
            const h = Math.floor(diff / 3600000);
            const m = String(Math.floor((diff % 3600000) / 60000)).padStart(2, '0');
            const s = String(Math.floor((diff % 60000) / 1000)).padStart(2, '0');
            topCount.innerText = `${h}:${m}:${s}`;
        }
    } else {
        if (topDiv) topDiv.classList.add('hidden');
        window._autoClosingSession = false;
    }
}, 1000);

// ── Bootstrap on page load ────────────────────────────────────
if (adminKey) {
    document.getElementById('loginOverlay').classList.add('hidden');
    document.getElementById('mainApp').classList.remove('hidden');
    document.getElementById('staffNameDisplay').innerText = `Logged in as ${staffCode}`;
    loadInitialData();
}
