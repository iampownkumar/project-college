// ============================================================
// File: app/static/js/sessions.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Sessions tab — render session table, create,
//              activate, close, and delete exam sessions.
//              The setInterval countdowns live in common.js;
//              this module only owns the render and action logic.
// ============================================================

function renderSessions() {
    const list = document.getElementById('sessionsList');
    list.innerHTML = '';

    if (filteredSessions.length === 0) {
        list.innerHTML = `<tr><td colspan="6" class="px-6 py-8 text-center text-gray-500">No sessions found.</td></tr>`;
        return;
    }

    filteredSessions.forEach(s => {
        const statusColor = s.status === 'active'
            ? 'bg-green-100 text-green-800'
            : s.status === 'draft'
                ? 'bg-gray-100 text-gray-800'
                : 'bg-red-100 text-red-800';

        const timeStr    = s.start_time ? parseUTCDate(s.start_time).toLocaleString() : 'Not Set';
        const endStr     = s.end_time   ? `<br>Ends: ${parseUTCDate(s.end_time).toLocaleTimeString()}` : '';
        const activeTimer = s.status === 'active' && s.end_time
            ? `<br><div class="session-countdown mt-1" data-end="${s.end_time}"></div>` : '';

        // "Scheduled" badge for draft sessions that have a future start_time
        const isScheduled = s.status === 'draft' && s.start_time &&
            parseUTCDate(s.start_time).getTime() > Date.now();
        const scheduledBadge = isScheduled
            ? `<span class="ml-2 px-2 py-0.5 rounded-full text-[10px] font-bold bg-indigo-100 text-indigo-700 border border-indigo-200 uppercase">⏰ Auto-starts ${parseUTCDate(s.start_time).toLocaleTimeString()}</span>`
            : '';

        list.innerHTML += `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4">${s.id}</td>
                <td class="px-6 py-4 font-medium text-gray-900">
                    <button onclick="openSessionDetail(${s.id})"
                        class="text-left hover:text-indigo-700 transition font-semibold">
                        ${s.title}
                    </button>
                </td>
                <td class="px-6 py-4">${s.department}</td>
                <td class="px-6 py-4 text-xs text-gray-500">
                    ${timeStr}${endStr}${activeTimer}<br>
                    <span class="font-bold">${s.duration_minutes}m</span> limit
                </td>
                <td class="px-6 py-4">
                    <span class="px-2 py-1 rounded-full text-xs font-semibold ${statusColor}">${s.status}</span>
                    ${scheduledBadge}
                </td>
                <td class="px-6 py-4 text-right space-x-2">
                    <button onclick="openSessionDetail(${s.id})" class="sd-open-btn">Open →</button>
                    ${s.status === 'draft' ? `<button onclick="updateSessionStatus(${s.id}, 'active')" class="text-green-600 hover:text-green-900 text-xs font-bold border border-green-200 bg-green-50 px-2 py-1 rounded shadow-sm">Activate</button>` : ''}
                    ${s.status === 'active' ? `<button onclick="updateSessionStatus(${s.id}, 'closed')" class="text-red-600 hover:text-red-900 text-xs font-bold border border-red-200 bg-red-50 px-2 py-1 rounded shadow-sm">Close Exam</button>` : ''}
                    <button onclick="deleteSession(${s.id})" class="text-red-600 hover:text-red-900 text-xs font-bold border border-red-200 bg-red-50 px-2 py-1 rounded shadow-sm">Delete</button>
                </td>
            </tr>
        `;
    });
}

async function createSession() {
    const d = document.getElementById('sDept').value;
    const payload = {
        title            : document.getElementById('sTitle').value,
        department       : d,
        language         : document.getElementById('sLang').value,
        duration_minutes : parseInt(document.getElementById('sMins').value),
    };
    const start = document.getElementById('sStart').value;
    const end   = document.getElementById('sEnd').value;
    if (start) payload.start_time = new Date(start).toISOString();
    if (end)   payload.end_time   = new Date(end).toISOString();

    const res = await fetch(`${API_BASE}/session`, {
        method: 'POST', headers: getHeaders(), body: JSON.stringify(payload)
    });
    if (res.ok) {
        closeModal('sessionModal');
        showToast('Session created');
        await loadInitialData();
    } else {
        showToast('Failed to create session', true);
    }
}

async function updateSessionStatus(id, status) {
    if (status === 'closed' && !confirm('Are you sure you want to close this exam session?')) return;
    await fetch(`${API_BASE}/session/${id}/status`, {
        method: 'PUT', headers: getHeaders(), body: JSON.stringify({ status })
    });
    showToast(`Session marked as ${status}`);
    await loadInitialData();
}

async function deleteSession(id) {
    if (!confirm('Permanently delete this session and all its questions/assignments?')) return;
    const res = await fetch(`${API_BASE}/session/${id}`, {
        method: 'DELETE', headers: getHeaders()
    });
    if (res.ok) {
        showToast('Session deleted');
        await loadInitialData();
    } else {
        showToast('Failed to delete session', true);
    }
}
