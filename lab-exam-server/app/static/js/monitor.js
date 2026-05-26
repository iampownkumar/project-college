// ============================================================
// File: app/static/js/monitor.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Live Monitor tab — real-time student card grid.
//              Shows online/offline dot, run count, submission
//              status, machine IP, and client state per student.
//              Data comes from GET /admin/session/{id}/monitor.
// ============================================================

async function refreshMonitor() {
    const sid  = document.getElementById('mSessionSelect').value;
    const grid = document.getElementById('monitorGrid');
    if (!sid) { grid.innerHTML = ''; return; }

    const res  = await fetch(`${API_BASE}/session/${sid}/monitor`, { headers: getHeaders() });
    const data = await res.json();

    document.getElementById('mTotalCount').innerText  = data.total_students;
    document.getElementById('mOnlineCount').innerText = data.online_count ?? data.online_students ?? 0;

    grid.innerHTML = '';
    if (!data.students || data.students.length === 0) {
        grid.innerHTML = '<p class="text-gray-500 col-span-3">No students assigned to this session.</p>';
        return;
    }

    data.students.forEach(s => {
        const color    = s.is_online ? 'bg-green-50 border-green-200' : 'bg-gray-50 border-gray-200';
        const dot      = s.is_online ? 'bg-green-500 animate-pulse' : 'bg-gray-300';
        const subBadge = s.has_submitted
            ? `<span class="px-2 py-1 bg-purple-100 text-purple-800 text-[10px] font-bold rounded uppercase ml-2 border border-purple-200">Submitted</span>`
            : '';
        const exitBadge = s.last_exit_code !== null && s.last_exit_code !== undefined
            ? `<span class="ml-1 px-1.5 py-0.5 rounded text-[9px] font-bold ${s.last_exit_code === 0 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'}">
                exit ${s.last_exit_code}
               </span>` : '';

        grid.innerHTML += `
            <div class="${color} border p-4 rounded-xl shadow-sm transition">
                <div class="flex justify-between items-start">
                    <div class="flex items-center space-x-3">
                        <div class="w-3 h-3 rounded-full ${dot} shadow-sm shrink-0 mt-0.5"></div>
                        <div>
                            <div class="font-bold text-gray-800 text-sm flex items-center flex-wrap gap-1">
                                ${s.name} ${subBadge}
                            </div>
                            <div class="text-xs text-gray-500 font-mono">${s.registration_number} | ${s.year} Year, Sec ${s.section}</div>
                            ${s.question_title ? `<div class="text-xs text-blue-600 mt-0.5 truncate max-w-[180px]" title="${s.question_title}">Q: ${s.question_title}</div>` : ''}
                        </div>
                    </div>
                    <div class="text-right text-[10px] text-gray-500 shrink-0 ml-2">
                        Runs: <b class="text-gray-800">${s.run_count}</b> ${exitBadge}<br>
                        IP: ${s.machine_ip || '---'}<br>
                        ${s.machine_name ? `<span class="text-gray-400">${s.machine_name}</span>` : ''}
                    </div>
                </div>
            </div>
        `;
    });
}
