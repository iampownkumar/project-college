// ============================================================
// File: app/static/js/submissions.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Submissions tab — table of final submissions
//              with submission type badges (normal, malpractice,
//              timer-expired, resubmission) and inline code viewer.
// ============================================================

let lastSubmissions = [];

async function refreshSubmissions() {
    const sid  = document.getElementById('subSessionSelect').value;
    const list = document.getElementById('submissionsList');
    if (!sid) { list.innerHTML = ''; return; }

    const res  = await fetch(`${API_BASE}/session/${sid}/submissions`, { headers: getHeaders() });
    const data = await res.json();
    lastSubmissions = data;
    list.innerHTML  = '';

    if (data.length === 0) {
        list.innerHTML = '<tr><td colspan="6" class="px-6 py-4 text-center text-gray-500">No submissions yet.</td></tr>';
        return;
    }

    data.forEach(s => {
        let typeColor, typeIcon, typeLabel, rowTint = '';
        switch (s.submission_type) {
            case 'auto_tab_switch':
                typeColor = 'bg-red-100 text-red-800 border-red-300';
                typeIcon  = '🚨'; typeLabel = 'Malpractice'; rowTint = 'bg-red-50';
                break;
            case 'auto_timer':
                typeColor = 'bg-yellow-100 text-yellow-800 border-yellow-300';
                typeIcon  = '⏰'; typeLabel = 'Time Expired';
                break;
            case 'resubmission':
                typeColor = 'bg-blue-100 text-blue-800 border-blue-300';
                typeIcon  = '🔄'; typeLabel = 'Re-submitted';
                break;
            default:
                typeColor = 'bg-green-100 text-green-800 border-green-300';
                typeIcon  = '✅'; typeLabel = 'Submitted';
        }

        list.innerHTML += `
            <tr class="${rowTint} hover:brightness-95 transition">
                <td class="px-6 py-4 font-medium text-gray-800">
                    ${s.student_name}
                    <span class="text-xs text-gray-500 block font-mono">
                        ${s.registration_number} | ${s.student_department}, ${s.student_year} Year, Sec ${s.student_section}
                    </span>
                </td>
                <td class="px-6 py-4 text-blue-700 text-sm font-medium">${s.question_title}</td>
                <td class="px-6 py-4">
                    <span class="inline-flex items-center gap-1 px-2 py-1 border rounded text-[10px] uppercase font-bold tracking-wide ${typeColor}">
                        ${typeIcon} ${typeLabel}
                    </span>
                </td>
                <td class="px-6 py-4 font-bold text-center text-gray-600">${s.submit_count}</td>
                <td class="px-6 py-4 text-xs text-gray-500">${parseUTCDate(s.submitted_at).toLocaleString()}</td>
                <td class="px-6 py-4">
                    <button onclick="viewCode(${s.id})"
                        class="bg-gray-800 text-white hover:bg-black px-3 py-1 rounded text-xs font-bold transition">
                        View Code
                    </button>
                </td>
            </tr>
        `;
    });
}

function viewCode(id) {
    const s = lastSubmissions.find(x => x.id === id);
    if (!s) return;
    document.getElementById('codeViewContent').innerText = s.source_code || '# No code';
    openModal('codeModal');
}
