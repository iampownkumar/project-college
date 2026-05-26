// ============================================================
// File: app/static/js/session_detail.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Description: Session Detail slide-over panel.
//   Opens when coordinator clicks "Open" on a session row.
//   Shows Questions, Students count, and Live Monitor in one view.
//   Reuses existing modal helpers from questions.js / assignments.js.
// ============================================================

// ── State ─────────────────────────────────────────────────────
let _sdCurrentSession   = null;   // full session object
let _sdMonitorInterval  = null;   // setInterval handle
let _sdQuestionsOpen    = true;
let _sdStudentsOpen     = true;
let _sdMonitorOpen      = true;

// ── Open / Close ──────────────────────────────────────────────

function openSessionDetail(sessionId) {
    const session = rawAllSessions.find(s => s.id === sessionId);
    if (!session) return showToast('Session not found', true);

    _sdCurrentSession = session;

    // Populate header
    _sdRenderHeader(session);

    // Show/hide live badge
    const liveBadge = document.getElementById('sd-live-badge');
    if (liveBadge) liveBadge.style.display = session.status === 'active' ? '' : 'none';

    // Show backdrop + panel
    document.getElementById('sdBackdrop').classList.remove('sd-hidden');
    document.getElementById('sdPanel').classList.remove('sd-slide-out');
    document.getElementById('sdPanel').classList.add('sd-slide-in');
    document.body.style.overflow = 'hidden';

    // Load sections
    sdLoadQuestions(session.id);
    sdLoadStudentsSummary(session.id);
    if (session.status === 'active') {
        _sdExpandMonitor(true);
        sdStartMonitor(session.id);
    } else {
        _sdExpandMonitor(false);
    }
}

function closeSessionDetail() {
    document.getElementById('sdPanel').classList.remove('sd-slide-in');
    document.getElementById('sdPanel').classList.add('sd-slide-out');
    setTimeout(() => {
        document.getElementById('sdBackdrop').classList.add('sd-hidden');
    }, 300);
    document.body.style.overflow = '';
    sdStopMonitor();
    _sdCurrentSession = null;
}

// ── Header ────────────────────────────────────────────────────

function _sdRenderHeader(s) {
    document.getElementById('sd-title').textContent = s.title;
    document.getElementById('sd-dept').textContent  = s.department || '—';

    const scheduledEl = document.getElementById('sd-scheduled');
    if (s.start_time) {
        const d = parseUTCDate(s.start_time);
        scheduledEl.textContent = `⏰ ${d.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}`;
        scheduledEl.style.display = '';
    } else {
        scheduledEl.style.display = 'none';
    }

    document.getElementById('sd-duration').textContent = `⏱ ${s.duration_minutes} mins`;

    // Status badge
    const badge = document.getElementById('sd-status-badge');
    badge.textContent = s.status.toUpperCase();
    badge.className = 'sd-status-badge ' + (
        s.status === 'active' ? 'sd-badge-active'
      : s.status === 'draft'  ? 'sd-badge-draft'
      : 'sd-badge-closed'
    );

    // Action buttons
    const activateBtn = document.getElementById('sd-btn-activate');
    const closeBtn    = document.getElementById('sd-btn-close-exam');
    activateBtn.style.display  = s.status === 'draft'  ? '' : 'none';
    closeBtn.style.display     = s.status === 'active' ? '' : 'none';
}

// ── Header action buttons ─────────────────────────────────────

async function sdActivateSession() {
    if (!_sdCurrentSession) return;
    const id = _sdCurrentSession.id;
    await fetch(`${API_BASE}/session/${id}/status`, {
        method: 'PUT', headers: getHeaders(), body: JSON.stringify({ status: 'active' })
    });
    showToast('Session activated 🟢');
    await loadInitialData();
    const updated = rawAllSessions.find(s => s.id === id);
    if (updated) {
        _sdCurrentSession = updated;
        _sdRenderHeader(updated);
        _sdExpandMonitor(true);
        sdStartMonitor(id);
    }
}

async function sdCloseSession() {
    if (!_sdCurrentSession) return;
    if (!confirm('Close this exam session? Students will no longer be able to submit.')) return;
    const id = _sdCurrentSession.id;
    await fetch(`${API_BASE}/session/${id}/status`, {
        method: 'PUT', headers: getHeaders(), body: JSON.stringify({ status: 'closed' })
    });
    showToast('Session closed');
    await loadInitialData();
    const updated = rawAllSessions.find(s => s.id === id);
    if (updated) {
        _sdCurrentSession = updated;
        _sdRenderHeader(updated);
        sdStopMonitor();
    }
}

// ── Questions section ─────────────────────────────────────────

async function sdLoadQuestions(sid) {
    const list    = document.getElementById('sd-questions-list');
    const counter = document.getElementById('sd-q-count');
    list.innerHTML = '<p class="sd-loading">Loading questions…</p>';

    try {
        const res  = await fetch(`${API_BASE}/session/${sid}/questions`, { headers: getHeaders() });
        const data = await res.json();

        counter.textContent = data.length;

        if (data.length === 0) {
            list.innerHTML = '<p class="sd-empty">No questions yet. Add one below.</p>';
            return;
        }

        list.innerHTML = '';
        data.forEach((q, idx) => {
            const filesBadge = q.file_count && q.file_count > 0
                ? `<span class="sd-badge sd-badge-file" title="${q.file_count} file(s) attached">📎 ${q.file_count} file${q.file_count > 1 ? 's' : ''}</span>`
                : '';

            const tcBadge = q.test_case_count > 0
                ? `<span class="sd-badge sd-badge-tc">${q.test_case_count} test case${q.test_case_count > 1 ? 's' : ''}</span>`
                : '<span class="sd-badge sd-badge-warn">no test cases</span>';

            const langBadge = `<span class="sd-badge sd-badge-lang">${q.language || 'python'}</span>`;

            list.innerHTML += `
            <div class="sd-q-card" id="sd-qcard-${q.id}">
                <div class="sd-q-header" onclick="sdToggleQuestion(${q.id})">
                    <div class="sd-q-left">
                        <span class="sd-q-num">Q${idx + 1}</span>
                        <div class="sd-q-info">
                            <span class="sd-q-title">${q.title}</span>
                            <div class="sd-q-badges">${tcBadge}${filesBadge}${langBadge}</div>
                        </div>
                    </div>
                    <div class="sd-q-right">
                        <span class="sd-chevron" id="sd-qchev-${q.id}">›</span>
                    </div>
                </div>
                <div class="sd-q-body" id="sd-qbody-${q.id}" style="display:none">
                    <div class="sd-q-stmt">
                        <p class="sd-label">Problem Statement</p>
                        <p class="sd-q-stmt-text">${q.statement}</p>
                        ${q.starter_code ? `<p class="sd-label mt-3">Starter Code</p><pre class="sd-code">${escapeHtml(q.starter_code)}</pre>` : ''}
                    </div>
                    <div class="sd-q-files">
                        <div class="sd-q-files-header">
                            <p class="sd-label">📎 Attached Files</p>
                            <label class="sd-btn-sm sd-btn-indigo">
                                + Attach
                                <input type="file" class="hidden" accept=".csv,.json,.txt,.png,.jpg,.jpeg,.dat,.bmp"
                                    onchange="sdUploadFile(${q.id}, this)">
                            </label>
                        </div>
                        <div id="sd-qfiles-${q.id}">
                            <p class="sd-loading">Loading files…</p>
                        </div>
                    </div>
                    <div class="sd-q-actions">
                        <button onclick="event.stopPropagation(); sdDeleteQuestion(${q.id})" class="sd-btn-sm sd-btn-danger">Delete Question</button>
                    </div>
                </div>
            </div>`;
        });
    } catch (e) {
        list.innerHTML = '<p class="sd-error">Failed to load questions.</p>';
    }
}

function sdToggleQuestion(qid) {
    const body  = document.getElementById(`sd-qbody-${qid}`);
    const chev  = document.getElementById(`sd-qchev-${qid}`);
    const open  = body.style.display !== 'none';
    body.style.display = open ? 'none' : 'block';
    chev.style.transform = open ? 'rotate(0deg)' : 'rotate(90deg)';
    if (!open) sdLoadQuestionFiles(qid);
}

async function sdLoadQuestionFiles(qid) {
    const container = document.getElementById(`sd-qfiles-${qid}`);
    if (!container) return;
    container.innerHTML = '<p class="sd-loading">Loading…</p>';

    try {
        const res   = await fetch(`${API_BASE}/question/${qid}/files`, { headers: getHeaders() });
        const files = await res.json();

        if (files.length === 0) {
            container.innerHTML = '<p class="sd-empty">No files attached.</p>';
            return;
        }

        container.innerHTML = files.map(f => {
            const sizeLabel = f.size_bytes < 1024 ? `${f.size_bytes} B`
                : f.size_bytes < 1048576 ? `${(f.size_bytes / 1024).toFixed(1)} KB`
                : `${(f.size_bytes / 1048576).toFixed(1)} MB`;
            return `
            <div class="sd-file-row">
                <span class="sd-file-icon">${fileIcon(f.filename)}</span>
                <span class="sd-file-name">${f.filename}</span>
                <span class="sd-file-size">${sizeLabel}</span>
                <button onclick="sdDeleteFile(${qid}, '${f.filename}')" class="sd-file-del" title="Remove">✕</button>
            </div>`;
        }).join('');
    } catch {
        container.innerHTML = '<p class="sd-error">Failed to load files.</p>';
    }
}

async function sdUploadFile(qid, input) {
    const file = input.files[0];
    if (!file) return;
    input.value = '';

    const container = document.getElementById(`sd-qfiles-${qid}`);
    container.innerHTML = '<p class="sd-loading">Uploading…</p>';

    const form = new FormData();
    form.append('file', file);

    try {
        const res = await fetch(`${API_BASE}/question/${qid}/files`, {
            method: 'POST',
            headers: { 'X-Admin-Key': adminKey },
            body: form
        });
        if (res.ok) {
            showToast(`${file.name} attached`);
            await sdLoadQuestionFiles(qid);
            sdLoadQuestions(_sdCurrentSession.id); // refresh badge counts
        } else {
            const err = await res.json().catch(() => ({}));
            showToast(err.detail || 'Upload failed', true);
            await sdLoadQuestionFiles(qid);
        }
    } catch {
        showToast('Upload failed — check connection', true);
        await sdLoadQuestionFiles(qid);
    }
}

async function sdDeleteFile(qid, filename) {
    if (!confirm(`Remove "${filename}"?`)) return;
    const res = await fetch(`${API_BASE}/question/${qid}/files/${encodeURIComponent(filename)}`, {
        method: 'DELETE', headers: getHeaders()
    });
    if (res.ok) {
        showToast(`${filename} removed`);
        await sdLoadQuestionFiles(qid);
        sdLoadQuestions(_sdCurrentSession.id);
    } else {
        showToast('Failed to delete file', true);
    }
}

async function sdDeleteQuestion(qid) {
    if (!confirm('Permanently delete this question?')) return;
    const res = await fetch(`${API_BASE}/question/${qid}`, {
        method: 'DELETE', headers: getHeaders()
    });
    if (res.ok) {
        showToast('Question deleted');
        sdLoadQuestions(_sdCurrentSession.id);
        await loadInitialData();
    } else {
        showToast('Failed to delete question', true);
    }
}

// Opens the existing question modal pre-filled with this session
function sdOpenAddQuestion() {
    if (!_sdCurrentSession) return;
    const mqSel = document.getElementById('mqSession');
    if (mqSel) {
        // ensure current session is selected in the modal
        [...mqSel.options].forEach(o => {
            o.selected = o.value === String(_sdCurrentSession.id);
        });
    }
    document.getElementById('qTitle').value   = '';
    document.getElementById('qStmt').value    = '';
    document.getElementById('qStarter').value = '';
    document.getElementById('testCasesContainer').innerHTML = '';
    openModal('questionModal');

    // Patch createQuestion to reload SD panel after success
    window._sdAwaitingQuestion = true;
}

// Patch: after createQuestion() succeeds, also reload SD panel
const _origCreateQuestion = typeof createQuestion !== 'undefined' ? createQuestion : null;
// We hook at the end of createQuestion's success path via a flag check
// (session_detail is loaded after questions.js so we wrap here)
document.addEventListener('DOMContentLoaded', () => {
    // Override createQuestion to hook into panel reload
    const origFn = window.createQuestion;
    if (origFn) {
        window.createQuestion = async function () {
            await origFn();
            if (window._sdAwaitingQuestion && _sdCurrentSession) {
                window._sdAwaitingQuestion = false;
                sdLoadQuestions(_sdCurrentSession.id);
            }
        };
    }
});

// ── Students section ──────────────────────────────────────────

async function sdLoadStudentsSummary(sid) {
    const counter    = document.getElementById('sd-stu-count');
    const subCounter = document.getElementById('sd-stu-submitted');
    const bigCount   = document.getElementById('sd-stu-count-big');
    const bigSub     = document.getElementById('sd-stu-sub-big');
    if (counter)    counter.textContent    = '…';
    if (subCounter) subCounter.textContent = '…';
    if (bigCount)   bigCount.textContent   = '…';
    if (bigSub)     bigSub.textContent     = '…';

    try {
        const res  = await fetch(`${API_BASE}/session/${sid}/monitor`, { headers: getHeaders() });
        const data = await res.json();
        const total = data.total_students ?? 0;
        const sub   = (data.students || []).filter(s => s.has_submitted).length;
        if (counter)    counter.textContent    = total;
        if (subCounter) subCounter.textContent = `${sub} ✅`;
        if (bigCount)   bigCount.textContent   = total;
        if (bigSub)     bigSub.textContent     = sub;
    } catch {
        if (counter) counter.textContent = '?';
    }
}

// Opens the existing assign modal pre-filled with this session
function sdOpenAssign() {
    if (!_sdCurrentSession) return;
    const maSel = document.getElementById('maSession');
    if (maSel) {
        [...maSel.options].forEach(o => {
            o.selected = o.value === String(_sdCurrentSession.id);
        });
        loadQuestionsForMultiAssign(_sdCurrentSession.id);
    }
    openModal('assignmentModal');
}

// ── Live Monitor section ───────────────────────────────────────

function _sdExpandMonitor(expand) {
    const body = document.getElementById('sd-monitor-body');
    const chev = document.getElementById('sd-monitor-chev');
    if (!body) return;
    _sdMonitorOpen = expand;
    body.style.display = expand ? 'block' : 'none';
    if (chev) chev.style.transform = expand ? 'rotate(90deg)' : 'rotate(0deg)';
}

function sdToggleMonitor() {
    _sdExpandMonitor(!_sdMonitorOpen);
    if (_sdMonitorOpen && _sdCurrentSession) {
        sdStartMonitor(_sdCurrentSession.id);
    } else {
        sdStopMonitor();
    }
}

function sdStartMonitor(sid) {
    sdStopMonitor();
    _sdRefreshMonitorPanel(sid);
    _sdMonitorInterval = setInterval(() => _sdRefreshMonitorPanel(sid), 5000);
}

function sdStopMonitor() {
    if (_sdMonitorInterval) {
        clearInterval(_sdMonitorInterval);
        _sdMonitorInterval = null;
    }
}

async function _sdRefreshMonitorPanel(sid) {
    try {
        const res  = await fetch(`${API_BASE}/session/${sid}/monitor`, { headers: getHeaders() });
        const data = await res.json();

        document.getElementById('sd-online-count').textContent  = data.online_count ?? data.online_students ?? 0;
        document.getElementById('sd-total-count') && (document.getElementById('sd-total-count').textContent = data.total_students ?? 0);
        const submitted = (data.students || []).filter(s => s.has_submitted).length;
        document.getElementById('sd-submitted-count').textContent = submitted;
        // Sync count chips in section headers
        const stuCountChip = document.getElementById('sd-stu-count');
        const stuSubChip   = document.getElementById('sd-stu-submitted');
        if (stuCountChip) stuCountChip.textContent = data.total_students ?? 0;
        if (stuSubChip)   stuSubChip.textContent   = `${submitted} ✅`;
        // Sync big numbers in student body
        const bigCount = document.getElementById('sd-stu-count-big');
        const bigSub   = document.getElementById('sd-stu-sub-big');
        if (bigCount) bigCount.textContent = data.total_students ?? 0;
        if (bigSub)   bigSub.textContent   = submitted;

        const grid = document.getElementById('sd-monitor-grid');
        if (!data.students || data.students.length === 0) {
            grid.innerHTML = '<p class="sd-empty">No students assigned to this session.</p>';
            return;
        }

        grid.innerHTML = data.students.map(s => {
            const isOnline  = s.is_online;
            const submitted = s.has_submitted;
            const dot       = isOnline ? 'sd-dot-online' : 'sd-dot-offline';
            const cardCls   = isOnline ? 'sd-monitor-card sd-card-online' : 'sd-monitor-card sd-card-offline';

            const subBadge  = submitted
                ? '<span class="sd-badge sd-badge-submitted">✅ Submitted</span>'
                : '';
            const exitBadge = s.last_exit_code !== null && s.last_exit_code !== undefined
                ? `<span class="sd-badge ${s.last_exit_code === 0 ? 'sd-badge-exit-ok' : 'sd-badge-exit-fail'}">exit ${s.last_exit_code}</span>`
                : '';

            return `
            <div class="${cardCls}">
                <div class="sd-mc-top">
                    <div class="sd-mc-left">
                        <span class="sd-dot ${dot}"></span>
                        <div>
                            <div class="sd-mc-name">${s.name} ${subBadge}</div>
                            <div class="sd-mc-reg">${s.registration_number} · ${s.year} Yr, Sec ${s.section}</div>
                            ${s.question_title ? `<div class="sd-mc-q">Q: ${s.question_title}</div>` : ''}
                        </div>
                    </div>
                    <div class="sd-mc-right">
                        <div class="sd-mc-runs">Runs: <b>${s.run_count}</b> ${exitBadge}</div>
                        <div class="sd-mc-ip">IP: ${s.machine_ip || '—'}</div>
                        ${s.machine_name ? `<div class="sd-mc-machine">${s.machine_name}</div>` : ''}
                    </div>
                </div>
            </div>`;
        }).join('');
    } catch (e) {
        // Silent fail during auto-refresh
    }
}

// ── Section collapse toggles ───────────────────────────────────

function sdToggleSection(sectionId, chevId) {
    const body = document.getElementById(sectionId);
    const chev = document.getElementById(chevId);
    if (!body) return;
    const isOpen = body.style.display !== 'none';
    body.style.display = isOpen ? 'none' : 'block';
    if (chev) chev.style.transform = isOpen ? 'rotate(0deg)' : 'rotate(90deg)';
}

// ── Utility ────────────────────────────────────────────────────

function escapeHtml(str) {
    return (str || '')
        .replace(/&/g, '&amp;')
        .replace(/</g, '&lt;')
        .replace(/>/g, '&gt;');
}

// Close on Escape key
document.addEventListener('keydown', e => {
    if (e.key === 'Escape' && _sdCurrentSession) closeSessionDetail();
});
