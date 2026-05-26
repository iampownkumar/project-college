// ============================================================
// File: app/static/js/students.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Admin dashboard — Students module.
//              Manages: year-card overview, section drill-down,
//              full student register table, enable/disable/delete,
//              and CSV bulk upload with automatic column mapping.
// Depends on: common.js
// ============================================================

let allStudents   = [];   // cache fetched from API
let parsedRows    = [];   // rows parsed from uploaded CSV
let currentYear    = null;
let currentSection = null;

const YEAR_ORDER = ['1st', '2nd', '3rd', '4th'];

// ════════════════════════════════════════════════════════
//  STUDENT VIEW ENTRY POINT
// ════════════════════════════════════════════════════════
async function loadStudentView() {
  const grid = document.getElementById('yearCards');
  grid.innerHTML = `<div class="loading-state"><div class="spinner"></div> Loading students…</div>`;

  // Reset drill-down panels
  document.getElementById('sectionView').classList.add('hidden');
  document.getElementById('registerView').classList.add('hidden');
  currentYear    = null;
  currentSection = null;

  try {
    allStudents = await api('GET', '/api/v1/admin/students');
    renderYearCards();
  } catch (e) {
    grid.innerHTML = `<div class="loading-state" style="color:var(--red)">Failed: ${esc(e.message)}</div>`;
  }
}

// ════════════════════════════════════════════════════════
//  YEAR CARDS
// ════════════════════════════════════════════════════════
function renderYearCards() {
  const grid = document.getElementById('yearCards');

  // Count students per year
  const byYear = {};
  allStudents.forEach(s => {
    const y = (s.year || 'Unknown').trim();
    byYear[y] = (byYear[y] || 0) + 1;
  });

  const SUFFIXES = { '1st': 'st', '2nd': 'nd', '3rd': 'rd', '4th': 'th' };
  const NUMS     = { '1st': '1', '2nd': '2', '3rd': '3', '4th': '4' };

  const standardCards = YEAR_ORDER.map(y => {
    const count = byYear[y] || 0;
    const empty = count === 0;
    return `
      <div class="year-card ${empty ? 'year-card-empty' : ''}"
           ${empty ? '' : `onclick="openYear('${y}')"`}>
        <span class="year-card-num">${NUMS[y]}<sup style="font-size:16px;font-weight:600;opacity:.6">${SUFFIXES[y]}</sup></span>
        <div class="year-card-label">Year</div>
        <div class="year-card-count">${empty ? 'No students' : count + ' students'}</div>
      </div>
    `;
  }).join('');

  // Any non-standard year values
  const extras = Object.keys(byYear)
    .filter(y => !YEAR_ORDER.includes(y))
    .map(y => `
      <div class="year-card" onclick="openYear('${esc(y)}')">
        <span class="year-card-num" style="font-size:22px">${esc(y)}</span>
        <div class="year-card-label">Year</div>
        <div class="year-card-count">${byYear[y]} students</div>
      </div>
    `).join('');

  grid.innerHTML = standardCards + extras;
}

// ════════════════════════════════════════════════════════
//  SECTION DRILL-DOWN
// ════════════════════════════════════════════════════════
function openYear(year) {
  currentYear    = year;
  currentSection = null;

  const students = allStudents.filter(s => (s.year || '').trim() === year);

  // Group by section
  const bySection = {};
  students.forEach(s => {
    const sec = (s.section || '?').trim();
    if (!bySection[sec]) bySection[sec] = [];
    bySection[sec].push(s);
  });

  document.getElementById('sectionTitle').textContent = `${year} Year — Choose a Section`;

  document.getElementById('sectionCards').innerHTML = Object.keys(bySection).sort().map(sec => `
    <div class="section-card" onclick="openSection('${esc(sec)}')">
      <div class="sec-letter">Section ${esc(sec)}</div>
      <div class="sec-count">${bySection[sec].length} students</div>
    </div>
  `).join('');

  document.getElementById('registerView').classList.add('hidden');
  document.getElementById('sectionView').classList.remove('hidden');
  document.getElementById('sectionView').scrollIntoView({ behavior: 'smooth', block: 'start' });
}

function closeSectionView() {
  document.getElementById('sectionView').classList.add('hidden');
  document.getElementById('registerView').classList.add('hidden');
  currentYear    = null;
  currentSection = null;
}

// ════════════════════════════════════════════════════════
//  STUDENT REGISTER (full list for one section)
// ════════════════════════════════════════════════════════
function openSection(section) {
  currentSection = section;
  const students = allStudents.filter(
    s => (s.year || '').trim() === currentYear && (s.section || '').trim() === section
  );

  document.getElementById('registerTitle').textContent =
    `${currentYear} Year · Section ${section} — ${students.length} students`;

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
    tbody.innerHTML = `<tr><td colspan="7" class="empty-cell">No students found</td></tr>`;
    return;
  }
  tbody.innerHTML = students.map((s, i) => `
    <tr>
      <td style="color:var(--muted);min-width:36px">${i + 1}</td>
      <td class="mono">${esc(s.registration_number)}</td>
      <td>${esc(s.name)}</td>
      <td>${esc(s.department)}</td>
      <td>${esc(s.section)}</td>
      <td><span class="badge badge-${s.enabled ? 'enabled' : 'disabled'}">${s.enabled ? 'Active' : 'Disabled'}</span></td>
      <td>
        <button class="row-act ${s.enabled ? 'warn' : ''}"
          onclick="${s.enabled ? 'disableStudent' : 'enableStudent'}('${esc(s.registration_number)}')">
          ${s.enabled ? 'Disable' : 'Enable'}
        </button>
        <button class="row-act danger" onclick="deleteStudent('${esc(s.registration_number)}')">Delete</button>
      </td>
    </tr>
  `).join('');
}

// ── Student Actions ───────────────────────────────────────
async function enableStudent(reg) {
  try {
    await api('PUT', `/api/v1/admin/student/${reg}/enable`);
    toast('Student enabled', 'ok');
    await refreshStudentCache();
  } catch (e) { toast(e.message, 'err'); }
}

async function disableStudent(reg) {
  try {
    await api('PUT', `/api/v1/admin/student/${reg}/disable`);
    toast('Student disabled', 'ok');
    await refreshStudentCache();
  } catch (e) { toast(e.message, 'err'); }
}

async function deleteStudent(reg) {
  if (!confirm(`Delete student ${reg}? This cannot be undone.`)) return;
  try {
    await api('DELETE', `/api/v1/admin/student/${reg}`);
    toast('Student deleted', 'ok');
    await refreshStudentCache();
  } catch (e) { toast(e.message, 'err'); }
}

async function refreshStudentCache() {
  allStudents = await api('GET', '/api/v1/admin/students');
  renderYearCards();
  // Refresh current section view if open
  if (currentYear && currentSection) openSection(currentSection);
  else if (currentYear) openYear(currentYear);
}

// ════════════════════════════════════════════════════════
//  CSV UPLOAD
// ════════════════════════════════════════════════════════
function toggleCsvUpload() {
  const panel = document.getElementById('csvPanel');
  panel.classList.toggle('hidden');
  if (panel.classList.contains('hidden')) resetCsv();
}

function handleFile(file) {
  if (!file) return;
  if (!file.name.toLowerCase().endsWith('.csv')) {
    toast('Please select a .csv file', 'err'); return;
  }
  const reader = new FileReader();
  reader.onload = e => {
    try {
      parsedRows = parseStudentCSV(e.target.result);
      renderCsvPreview();
      toast(`Parsed ${parsedRows.length} students from CSV`, 'inf');
    } catch (err) {
      toast('CSV error: ' + err.message, 'err');
    }
  };
  reader.readAsText(file);
}

// ── CSV Parser ────────────────────────────────────────────
// Supports the college CSV format:
//   department, section, register number, name, year
// Automatically maps to API fields.
function parseStudentCSV(text) {
  const lines = text.trim().split('\n').map(l => l.trim()).filter(Boolean);
  if (lines.length < 2) throw new Error('CSV must have a header row and at least one data row');

  // Normalize header names
  const rawHeaders = lines[0].split(',').map(h => h.trim().toLowerCase().replace(/\s+/g, '_'));

  // Find column indices by flexible matching
  const find = (...keys) => rawHeaders.findIndex(h => keys.some(k => h.includes(k)));

  const idxReg  = find('register', 'reg_no', 'registration');
  const idxName = find('name');
  const idxDept = find('department', 'dept');
  const idxSec  = find('section', 'sec');
  const idxYear = find('year');

  const missing = [
    [idxReg,  'register number'],
    [idxName, 'name'],
    [idxDept, 'department'],
    [idxSec,  'section'],
    [idxYear, 'year'],
  ].filter(([i]) => i === -1).map(([, n]) => n);

  if (missing.length) throw new Error(`Missing columns: ${missing.join(', ')}`);

  const rows = [];
  for (let i = 1; i < lines.length; i++) {
    const vals = splitCsvLine(lines[i]);
    const reg  = (vals[idxReg]  || '').trim();
    const name = (vals[idxName] || '').trim();
    const dept = (vals[idxDept] || '').trim();
    const sec  = (vals[idxSec]  || '').trim();
    const year = (vals[idxYear] || '').trim();

    if (!reg || !name) continue; // skip blank rows

    rows.push({
      registration_number: reg,
      name,
      department: dept,
      section: sec,
      year,
      batch: deriveBatch(reg),
      enabled: true,
    });
  }

  if (!rows.length) throw new Error('No valid student rows found in CSV');
  return rows;
}

// Derive academic batch from register number
// e.g. 2117240020001 → digits 5-6 = "24" → joined 2024 → batch "2024-28"
function deriveBatch(reg) {
  const m = reg.match(/^\d{4}(\d{2})/);
  if (!m) return 'Unknown';
  const y = 2000 + parseInt(m[1]);
  return `${y}-${y + 4}`;
}

// Split a CSV line respecting quoted fields
function splitCsvLine(line) {
  const vals = [];
  let cur = ''; let inQ = false;
  for (const ch of line) {
    if (ch === '"') { inQ = !inQ; }
    else if (ch === ',' && !inQ) { vals.push(cur); cur = ''; }
    else cur += ch;
  }
  vals.push(cur);
  return vals;
}

// ── CSV Preview ───────────────────────────────────────────
function renderCsvPreview() {
  const COLS   = ['registration_number', 'name', 'department', 'section', 'year', 'batch'];
  const LABELS = ['Reg. No.', 'Name', 'Dept', 'Section', 'Year', 'Batch'];
  const shown  = parsedRows.slice(0, 10);

  document.getElementById('csvPreview').innerHTML = `
    <table>
      <thead><tr>${LABELS.map(l => `<th>${l}</th>`).join('')}</tr></thead>
      <tbody>
        ${shown.map(r => `<tr>${COLS.map(c => `<td>${esc(r[c] || '')}</td>`).join('')}</tr>`).join('')}
        ${parsedRows.length > 10
          ? `<tr><td colspan="${COLS.length}" style="text-align:center;color:var(--muted);padding:8px">
              …and ${parsedRows.length - 10} more students
             </td></tr>`
          : ''}
      </tbody>
    </table>
  `;
  document.getElementById('csvPreview').classList.remove('hidden');
  document.getElementById('csvConfirm').classList.remove('hidden');
}

// ── Upload ────────────────────────────────────────────────
async function doUpload() {
  if (!parsedRows.length) return;
  const btn = document.getElementById('uploadBtn');
  btn.disabled = true; btn.textContent = 'Uploading…';
  try {
    const r = await api('POST', '/api/v1/admin/students/bulk', { students: parsedRows });
    const errNote = r.errors.length ? ` · ${r.errors.length} errors` : '';
    toast(`✓ ${r.created} created, ${r.skipped} skipped${errNote}`,
          r.errors.length ? 'inf' : 'ok', 5000);
    resetCsv();
    await loadStudentView();
  } catch (e) {
    toast(e.message, 'err');
  } finally {
    btn.disabled = false; btn.textContent = 'Upload Students';
  }
}

function resetCsv() {
  parsedRows = [];
  document.getElementById('csvPanel').classList.add('hidden');
  document.getElementById('csvPreview').classList.add('hidden');
  document.getElementById('csvPreview').innerHTML = '';
  document.getElementById('csvConfirm').classList.add('hidden');
  document.getElementById('csvInput').value = '';
}

// ════════════════════════════════════════════════════════
//  EVENT LISTENERS (students module)
// ════════════════════════════════════════════════════════
document.addEventListener('DOMContentLoaded', () => {
  // CSV file input
  const inp = document.getElementById('csvInput');
  inp.addEventListener('change', () => handleFile(inp.files[0]));

  // Drag & drop
  const dz = document.getElementById('dropZone');
  dz.addEventListener('click',     () => inp.click());
  dz.addEventListener('dragover',  e => { e.preventDefault(); dz.classList.add('over'); });
  dz.addEventListener('dragleave', () => dz.classList.remove('over'));
  dz.addEventListener('drop', e => {
    e.preventDefault();
    dz.classList.remove('over');
    handleFile(e.dataTransfer.files[0]);
  });
});
