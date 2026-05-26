// ============================================================
// File: app/static/js/assignments.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Assignments tab — list assignments per session,
//              populate question dropdown for the multi-assign
//              modal, and submit bulk round-robin assignment.
// ============================================================

async function loadAssignmentsForSession(sid) {
    const list = document.getElementById('assignmentsList');
    if (!sid) { list.innerHTML = ''; return; }

    const res  = await fetch(`${API_BASE}/session/${sid}/assignments`, { headers: getHeaders() });
    const data = await res.json();
    list.innerHTML = '';

    if (data.length === 0) {
        list.innerHTML = '<tr><td colspan="3" class="px-6 py-4 text-gray-500">No assignments in this session.</td></tr>';
        return;
    }

    data.forEach(a => {
        list.innerHTML += `
            <tr class="hover:bg-gray-50">
                <td class="px-6 py-4 font-medium text-gray-800">
                    ${a.student_name}
                    <span class="text-xs text-gray-500 block font-mono">
                        ${a.student_registration} | ${a.student_department}, ${a.student_year} Year, Sec ${a.student_section}
                    </span>
                </td>
                <td class="px-6 py-4 text-blue-700">${a.question_title}</td>
                <td class="px-6 py-4 text-xs text-gray-500">${parseUTCDate(a.assigned_at).toLocaleString()}</td>
            </tr>
        `;
    });
}

async function loadQuestionsForMultiAssign(sid) {
    const qSelect = document.getElementById('maQuestion');
    qSelect.innerHTML = '<option value="">-- Auto Round Robin All Questions --</option>';
    if (!sid) return;

    const res  = await fetch(`${API_BASE}/session/${sid}/questions`, { headers: getHeaders() });
    const data = await res.json();
    data.forEach(q => qSelect.innerHTML += `<option value="${q.id}">${q.title}</option>`);
}

async function submitMultiAssign() {
    const sid = document.getElementById('maSession').value;
    const qid = document.getElementById('maQuestion').value;
    const year = document.getElementById('maYear').value;
    const sec  = document.getElementById('maSec').value.trim().toUpperCase();
    if (!sid) return showToast('Select Session', true);

    const payload = {
        session_id: parseInt(sid),
        year      : year === 'all' ? null : year,
        section   : sec === '' ? null : sec
    };
    if (qid) payload.question_id = parseInt(qid);

    const res  = await fetch(`${API_BASE}/assignment/bulk`, {
        method: 'POST', headers: getHeaders(), body: JSON.stringify(payload)
    });
    const data = await res.json();

    if (res.ok) {
        closeModal('assignmentModal');
        await loadInitialData();
        showToast(data.message || 'Assignment complete');
        const sel = document.getElementById('aSessionSelect');
        if (sel && sel.value === sid) loadAssignmentsForSession(sid);
    } else {
        showToast(data.detail || 'Assignment failed', true);
    }
}
