// ============================================================
// File: app/static/js/students.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Students tab — three-level drill-down navigation
//              (Year → Section → Student table), single add,
//              bulk CSV upload, toggle enable/disable, and
//              undo-able deletion with 5-second countdown toast.
// ============================================================

// ── Drill-down state ──────────────────────────────────────────
let stuLevel          = 0;
let stuSelectedYear    = null;
let stuSelectedSection = null;

const YEAR_COLORS = {
    '1st': { bg:'bg-indigo-50', border:'border-indigo-200', badge:'bg-indigo-600', hover:'hover:bg-indigo-100', text:'text-indigo-700', icon:'1️⃣' },
    '2nd': { bg:'bg-blue-50',   border:'border-blue-200',   badge:'bg-blue-600',   hover:'hover:bg-blue-100',   text:'text-blue-700',   icon:'2️⃣' },
    '3rd': { bg:'bg-violet-50', border:'border-violet-200', badge:'bg-violet-600', hover:'hover:bg-violet-100', text:'text-violet-700', icon:'3️⃣' },
    '4th': { bg:'bg-rose-50',   border:'border-rose-200',   badge:'bg-rose-600',   hover:'hover:bg-rose-100',   text:'text-rose-700',   icon:'4️⃣' },
};

// ── Level management ──────────────────────────────────────────
function stuShowLevel(level) {
    stuLevel = level;
    document.getElementById('stuYearView').classList.toggle('hidden',    level !== 0);
    document.getElementById('stuSectionView').classList.toggle('hidden', level !== 1);
    document.getElementById('stuTableView').classList.toggle('hidden',   level !== 2);

    const backBtn = document.getElementById('stuBackBtn');
    if (level === 0) {
        backBtn.classList.add('hidden'); backBtn.classList.remove('flex');
        document.getElementById('stuHeading').textContent = 'Students';
    } else {
        backBtn.classList.remove('hidden'); backBtn.classList.add('flex');
        if (level === 1) {
            document.getElementById('stuBackLabel').textContent = 'All Years';
            document.getElementById('stuHeading').textContent  = `${stuSelectedYear} Year`;
        } else {
            document.getElementById('stuBackLabel').textContent = `${stuSelectedYear} Year`;
            document.getElementById('stuHeading').textContent  = `Section ${stuSelectedSection} — ${stuSelectedYear} Year`;
        }
    }
}

function stuNavBack() {
    if (stuLevel === 2) stuOpenYear(stuSelectedYear);
    else if (stuLevel === 1) { stuShowLevel(0); renderYearCards(); }
}

// ── Year cards ────────────────────────────────────────────────
function renderYearCards() {
    const grid  = document.getElementById('yearCardGrid');
    const YEARS = ['1st','2nd','3rd','4th'];
    grid.innerHTML = '';
    YEARS.forEach(yr => {
        const count = filteredStudents.filter(s => s.year === yr).length;
        const c     = YEAR_COLORS[yr] || YEAR_COLORS['1st'];
        grid.innerHTML += `
            <div onclick="stuOpenYear('${yr}')"
                class="cursor-pointer ${c.bg} ${c.border} border-2 rounded-2xl p-6 flex flex-col items-center gap-3 shadow-sm ${c.hover} transition-all duration-200 hover:shadow-md hover:-translate-y-0.5">
                <span class="text-4xl">${c.icon}</span>
                <div class="text-center">
                    <div class="text-sm font-semibold text-gray-500 uppercase tracking-wide">${yr} Year</div>
                    <div class="text-4xl font-extrabold ${c.text} mt-1">${count}</div>
                    <div class="text-xs text-gray-400 mt-1">students</div>
                </div>
                <span class="${c.badge} text-white text-xs font-bold px-3 py-1 rounded-full mt-1">View Sections →</span>
            </div>
        `;
    });
}

// ── Section cards ─────────────────────────────────────────────
function stuOpenYear(year) {
    stuSelectedYear = year;
    stuShowLevel(1);
    const c           = YEAR_COLORS[year] || YEAR_COLORS['1st'];
    const yearStudents = filteredStudents.filter(s => s.year === year);
    document.getElementById('stuSectionSubtitle').textContent =
        `${yearStudents.length} student${yearStudents.length !== 1 ? 's' : ''} in ${year} year — click a section to view details`;

    const groups = {};
    yearStudents.forEach(s => {
        const key = `${s.department}__${s.section}`;
        if (!groups[key]) groups[key] = { dept: s.department, section: s.section, count: 0 };
        groups[key].count++;
    });

    const grid = document.getElementById('sectionCardGrid');
    grid.innerHTML = '';
    Object.values(groups).sort((a,b) => a.section.localeCompare(b.section)).forEach(g => {
        grid.innerHTML += `
            <div onclick="stuOpenSection('${g.dept}','${g.section}')"
                class="cursor-pointer ${c.bg} ${c.border} border-2 rounded-2xl p-5 flex flex-col items-center gap-2 shadow-sm ${c.hover} transition-all duration-200 hover:shadow-md hover:-translate-y-0.5">
                <div class="w-12 h-12 rounded-full ${c.badge} flex items-center justify-center">
                    <span class="text-white font-extrabold text-lg">${g.section}</span>
                </div>
                <div class="text-center">
                    <div class="text-xs font-semibold text-gray-500 uppercase tracking-wide">${g.dept}</div>
                    <div class="text-sm font-bold text-gray-600">Section ${g.section}</div>
                </div>
                <div class="${c.badge} text-white font-extrabold text-2xl rounded-xl px-4 py-1">${g.count}</div>
                <div class="text-xs text-gray-400">students</div>
            </div>
        `;
    });
}

// ── Student table ─────────────────────────────────────────────
function stuOpenSection(dept, section) {
    stuSelectedSection = section;
    stuShowLevel(2);
    const sectionStudents = filteredStudents
        .filter(s => s.year === stuSelectedYear && s.department === dept && s.section === section)
        .sort((a,b) => a.registration_number.localeCompare(b.registration_number));

    document.getElementById('stuTableSubtitle').textContent =
        `${dept} — Section ${section} — ${stuSelectedYear} Year — ${sectionStudents.length} students`;

    const tbody = document.getElementById('stuTableBody');
    tbody.innerHTML = '';

    if (sectionStudents.length === 0) {
        tbody.innerHTML = `<tr><td colspan="8" class="px-6 py-10 text-center text-gray-400">No students found.</td></tr>`;
        return;
    }

    sectionStudents.forEach((s, idx) => {
        const isPending = pendingDeletions[s.registration_number];
        const rowClass  = isPending ? 'bg-red-50 opacity-50 pointer-events-none' : 'hover:bg-gray-50';
        tbody.innerHTML += `
            <tr class="${rowClass} transition">
                <td class="px-6 py-4 text-gray-400 text-xs">${idx + 1}</td>
                <td class="px-6 py-4 font-mono text-sm font-semibold text-gray-800">${s.registration_number}</td>
                <td class="px-6 py-4 font-medium text-gray-900">${s.name}</td>
                <td class="px-6 py-4 text-gray-600">${s.department}</td>
                <td class="px-6 py-4 text-gray-600">${s.section}</td>
                <td class="px-6 py-4 text-gray-600">${s.year}</td>
                <td class="px-6 py-4">
                    <span class="px-2 py-1 rounded-full text-xs font-semibold ${s.enabled ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800'}">
                        ${s.enabled ? 'Active' : 'Disabled'}
                    </span>
                </td>
                <td class="px-6 py-4 text-right space-x-3">
                    <button onclick="toggleStudent('${s.registration_number}', ${!s.enabled})"
                        class="text-blue-600 hover:text-blue-900 text-xs font-medium">Toggle</button>
                    <button onclick="triggerDelete('${s.registration_number}','${dept}','${section}')"
                        class="text-red-600 hover:text-red-900 text-xs font-bold">Delete</button>
                </td>
            </tr>
        `;
    });
}

// ── Top-level render (called after data reload) ───────────────
function renderStudents() {
    renderYearCards();
    if (stuLevel === 1 && stuSelectedYear) stuOpenYear(stuSelectedYear);
    if (stuLevel === 2 && stuSelectedYear && stuSelectedSection) {
        const match = filteredStudents.find(s => s.year === stuSelectedYear && s.section === stuSelectedSection);
        if (match) stuOpenSection(match.department, stuSelectedSection);
    }
}

// ── CRUD ──────────────────────────────────────────────────────
async function createStudent() {
    const res = await fetch(`${API_BASE}/student`, {
        method : 'POST',
        headers: getHeaders(),
        body   : JSON.stringify({
            registration_number: document.getElementById('stReg').value.toUpperCase(),
            name               : document.getElementById('stName').value,
            department         : document.getElementById('stDept').value,
            batch              : document.getElementById('stBatch').value,
            year               : document.getElementById('stYear').value,
            section            : document.getElementById('stSec').value.toUpperCase()
        })
    });
    if (res.ok) { closeModal('studentModal'); showToast('Student added'); await loadInitialData(); }
    else showToast('Failed to add student', true);
}

async function toggleStudent(reg, state) {
    await fetch(`${API_BASE}/student/${reg}/${state ? 'enable' : 'disable'}`, {
        method: 'PUT', headers: getHeaders()
    });
    await loadInitialData();
}

async function deleteAllStudents() {
    if (!confirm('⚠️ Delete ALL students permanently? This cannot be undone!')) return;
    if (!confirm('Are you absolutely sure? This will wipe every student from the database.')) return;
    const res  = await fetch(`${API_BASE}/students/all`, { method: 'DELETE', headers: getHeaders() });
    const data = await res.json();
    if (res.ok) { showToast(data.message || 'All students deleted'); await loadInitialData(); }
    else showToast(data.detail || 'Failed to delete', true);
}

// ── Undo-able delete ──────────────────────────────────────────
function triggerDelete(reg, dept, section) {
    if (pendingDeletions[reg]) return;
    const container = document.getElementById('undoContainer');

    const toast = document.createElement('div');
    toast.className = 'undo-toast bg-gray-900 text-white px-4 py-3 rounded-lg shadow-xl flex items-center space-x-4 border border-gray-700';
    toast.id = `undo-${reg}`;
    toast.innerHTML = `
        <div class="text-sm">Deleting <b>${reg}</b> in <span id="timer-${reg}" class="font-bold text-red-400">5</span>s</div>
        <button class="bg-gray-700 hover:bg-gray-600 px-3 py-1 rounded text-xs font-bold text-white transition">UNDO</button>
    `;
    container.appendChild(toast);

    let timeLeft = 5;
    const timerEl   = document.getElementById(`timer-${reg}`);
    const countdown = setInterval(() => {
        timeLeft--;
        timerEl.innerText = timeLeft;
        if (timeLeft <= 0) { clearInterval(countdown); commitDelete(reg, toast, dept, section); }
    }, 1000);

    toast.querySelector('button').onclick = () => {
        clearInterval(countdown);
        delete pendingDeletions[reg];
        toast.remove();
        renderStudents();
    };

    pendingDeletions[reg] = countdown;
    renderStudents();
}

async function commitDelete(reg, toastEl, dept, section) {
    try {
        await fetch(`${API_BASE}/student/${reg}`, { method: 'DELETE', headers: getHeaders() });
        toastEl.remove();
        delete pendingDeletions[reg];
        showToast(`Student ${reg} deleted.`);
        await loadInitialData();
    } catch {
        toastEl.remove();
        delete pendingDeletions[reg];
        showToast(`Failed to delete ${reg}`, true);
    }
}

// ── Bulk CSV upload ───────────────────────────────────────────
async function submitBulkStudentsCsv() {
    const fileInput = document.getElementById('bsFile');
    if (!fileInput.files.length) return showToast('Select a CSV file', true);

    const reader = new FileReader();
    reader.onload = async function (e) {
        try {
            const rows = parseCsv(e.target.result);
            if (rows.length < 2) return showToast('CSV must have a header and at least one row', true);

            const header  = rows[0].map(h => h.toLowerCase().trim());
            const deptIdx = header.findIndex(h => h.includes('dept') || h.includes('department'));
            const secIdx  = header.findIndex(h => h.includes('sec')  || h.includes('section'));
            const regIdx  = header.findIndex(h => h.includes('reg')  || h.includes('register'));
            const nameIdx = header.findIndex(h => h.includes('name'));
            const yearIdx = header.findIndex(h => h.includes('year'));

            if ([deptIdx, secIdx, regIdx, nameIdx, yearIdx].includes(-1))
                return showToast('CSV missing required columns (department, section, register number, name, year)', true);

            const studentsArray = [];
            for (let i = 1; i < rows.length; i++) {
                const row = rows[i];
                if (row.length < 5) continue;
                studentsArray.push({
                    department         : row[deptIdx],
                    section            : row[secIdx].toUpperCase(),
                    registration_number: row[regIdx].toUpperCase(),
                    name               : row[nameIdx],
                    year               : row[yearIdx],
                    batch              : '2026'
                });
            }

            if (studentsArray.length === 0) return showToast('No valid students found in CSV', true);

            const res  = await fetch(`${API_BASE}/students/bulk`, {
                method : 'POST',
                headers: getHeaders(),
                body   : JSON.stringify({ students: studentsArray })
            });
            const data = await res.json();
            if (res.ok) {
                showToast(`Uploaded! Created: ${data.created}, Skipped: ${data.skipped}`);
                if (data.errors && data.errors.length > 0)
                    showToast(`${data.errors.length} errors — check console`, true);
                closeModal('bulkStudentModal');
                loadInitialData();
            } else {
                showToast(data.detail || 'Failed to upload', true);
            }
        } catch {
            showToast('Failed to parse CSV file', true);
        }
    };
    reader.readAsText(fileInput.files[0]);
}
