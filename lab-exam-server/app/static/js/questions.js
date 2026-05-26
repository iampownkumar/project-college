// ============================================================
// File: app/static/js/questions.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Questions tab — accordion question cards,
//              single-question add modal, bulk CSV upload,
//              and per-question sandbox file attach / delete
//              (Phase 2 of next_phase.md).
//              File API: POST/DELETE/GET /admin/question/{id}/files
// ============================================================

// ── Question list ─────────────────────────────────────────────

async function loadQuestionsForSession(sid) {
    const list = document.getElementById('questionsList');
    if (!sid) { list.innerHTML = ''; return; }

    const res  = await fetch(`${API_BASE}/session/${sid}/questions`, { headers: getHeaders() });
    const data = await res.json();
    list.innerHTML = '';

    if (data.length === 0) {
        list.innerHTML = '<p class="text-gray-500">No questions for this session.</p>';
        return;
    }

    data.forEach(q => {
        const filesBadge = q.file_count && q.file_count > 0
            ? `<span class="ml-2 inline-flex items-center gap-1 text-[11px] bg-indigo-50 text-indigo-700 border border-indigo-200 px-2 py-0.5 rounded-full font-semibold"
                  title="${q.file_count} file(s) attached — students will see these in their sandbox">
                  📎 ${q.file_count}
               </span>`
            : '';

        const tcBadge = q.test_case_count > 0
            ? `<span class="text-[11px] bg-green-50 text-green-700 border border-green-100 px-2 py-0.5 rounded-full font-semibold">${q.test_case_count} test cases</span>`
            : '<span class="text-[11px] bg-red-50 text-red-500 border border-red-100 px-2 py-0.5 rounded-full">no test cases</span>';

        list.innerHTML += `
            <div class="bg-white rounded-xl border border-gray-200 shadow-sm overflow-hidden" id="qcard-${q.id}">
                <!-- ── Collapsed header row ── -->
                <div class="flex justify-between items-center px-5 py-4 cursor-pointer hover:bg-gray-50 transition"
                     onclick="toggleQuestion(${q.id})">
                    <div class="flex items-center gap-3 min-w-0">
                        <span id="qcard-chevron-${q.id}" class="text-gray-400 text-xs transition-transform duration-200">▶</span>
                        <div>
                            <h4 class="font-bold text-gray-800 flex items-center gap-1">
                                ${q.title} ${filesBadge}
                            </h4>
                            <p class="text-xs text-gray-500 mt-0.5 truncate max-w-xl">${q.statement.substring(0, 100)}${q.statement.length > 100 ? '…' : ''}</p>
                        </div>
                    </div>
                    <div class="flex items-center gap-2 shrink-0 ml-4">
                        ${tcBadge}
                        <span class="text-xs bg-blue-100 text-blue-800 font-bold px-2 py-1 rounded uppercase">${q.language}</span>
                        <button onclick="event.stopPropagation(); deleteQuestion(${q.id})"
                            class="text-red-600 hover:text-red-900 text-xs font-bold border border-red-200 bg-red-50 px-2 py-1 rounded shadow-sm">
                            Delete
                        </button>
                    </div>
                </div>

                <!-- ── Expanded panel ── -->
                <div id="qpanel-${q.id}" class="hidden border-t border-gray-100">
                    <!-- Statement -->
                    <div class="px-5 py-4 bg-gray-50 border-b border-gray-100">
                        <p class="text-sm font-medium text-gray-600 mb-1">Problem Statement</p>
                        <p class="text-sm text-gray-800 whitespace-pre-wrap">${q.statement}</p>
                        ${q.starter_code ? `<div class="mt-3"><p class="text-xs text-gray-500 mb-1 font-medium">Starter Code</p><pre class="text-xs bg-gray-900 text-green-400 p-3 rounded-lg overflow-auto max-h-32">${q.starter_code}</pre></div>` : ''}
                    </div>

                    <!-- Attached Files -->
                    <div class="px-5 py-4">
                        <div class="flex items-center justify-between mb-3">
                            <p class="text-sm font-semibold text-gray-700">📎 Attached Files</p>
                            <label class="cursor-pointer bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold px-3 py-1.5 rounded-lg shadow-sm transition flex items-center gap-1">
                                <svg class="w-3 h-3" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M12 4v16m8-8H4"/></svg>
                                Attach File
                                <input type="file" class="hidden"
                                    accept=".csv,.json,.txt,.png,.jpg,.jpeg,.dat,.bmp"
                                    onchange="uploadQuestionFile(${q.id}, this)">
                            </label>
                        </div>
                        <div id="qfiles-${q.id}" class="space-y-2 min-h-[2rem]">
                            <p class="text-xs text-gray-400 italic">Loading files…</p>
                        </div>
                        <p class="text-xs text-gray-400 mt-2">Max 5 files · 10 MB each · .csv .json .txt .png .jpg .jpeg .dat .bmp</p>
                    </div>
                </div>
            </div>
        `;
    });
}

// ── Accordion toggle ──────────────────────────────────────────

function toggleQuestion(qid) {
    const panel   = document.getElementById(`qpanel-${qid}`);
    const chevron = document.getElementById(`qcard-chevron-${qid}`);
    const isOpen  = !panel.classList.contains('hidden');

    if (isOpen) {
        panel.classList.add('hidden');
        chevron.style.transform = 'rotate(0deg)';
    } else {
        panel.classList.remove('hidden');
        chevron.style.transform = 'rotate(90deg)';
        loadQuestionFiles(qid); // lazy-load file list on expand
    }
}

// ── File management ───────────────────────────────────────────

async function loadQuestionFiles(qid) {
    const container = document.getElementById(`qfiles-${qid}`);
    if (!container) return;
    container.innerHTML = '<p class="text-xs text-gray-400 italic">Loading…</p>';

    try {
        const res   = await fetch(`${API_BASE}/question/${qid}/files`, { headers: getHeaders() });
        const files = await res.json();

        if (files.length === 0) {
            container.innerHTML = '<p class="text-xs text-gray-400 italic">No files attached. Students will only see the problem statement.</p>';
            return;
        }

        container.innerHTML = files.map(f => {
            const sizeLabel = f.size_bytes < 1024
                ? `${f.size_bytes} B`
                : f.size_bytes < 1048576
                    ? `${(f.size_bytes / 1024).toFixed(1)} KB`
                    : `${(f.size_bytes / 1048576).toFixed(1)} MB`;
            return `
                <div class="flex items-center justify-between bg-gray-50 border border-gray-200 rounded-lg px-3 py-2">
                    <div class="flex items-center gap-2 min-w-0">
                        <span class="text-base">${fileIcon(f.filename)}</span>
                        <span class="text-sm font-medium text-gray-800 truncate">${f.filename}</span>
                        <span class="text-xs text-gray-400 shrink-0">${sizeLabel}</span>
                    </div>
                    <button onclick="deleteQuestionFile(${qid}, '${f.filename}')"
                        class="text-red-500 hover:text-red-700 text-xs font-bold ml-3 shrink-0 transition" title="Remove file">
                        ✕
                    </button>
                </div>
            `;
        }).join('');
    } catch (e) {
        container.innerHTML = '<p class="text-xs text-red-500">Failed to load files.</p>';
    }
}

function fileIcon(filename) {
    const ext = filename.split('.').pop().toLowerCase();
    const icons = { csv: '📊', json: '📋', txt: '📄', png: '🖼️', jpg: '🖼️', jpeg: '🖼️', dat: '📦', bmp: '🖼️' };
    return icons[ext] || '📁';
}

async function uploadQuestionFile(qid, input) {
    const file = input.files[0];
    if (!file) return;
    input.value = ''; // reset picker

    const form = new FormData();
    form.append('file', file);

    const container = document.getElementById(`qfiles-${qid}`);
    container.innerHTML = '<p class="text-xs text-indigo-500 animate-pulse">Uploading…</p>';

    try {
        const res = await fetch(`${API_BASE}/question/${qid}/files`, {
            method : 'POST',
            headers: { 'X-Admin-Key': adminKey }, // no Content-Type — browser sets multipart boundary
            body   : form
        });
        if (res.ok) {
            showToast(`${file.name} attached`);
            await loadQuestionFiles(qid);
            // Refresh file count badge in collapsed header
            refreshQuestionFileBadge(qid);
        } else {
            const err = await res.json().catch(() => ({}));
            showToast(err.detail || 'Upload failed', true);
            await loadQuestionFiles(qid);
        }
    } catch {
        showToast('Upload failed — check connection', true);
        await loadQuestionFiles(qid);
    }
}

async function deleteQuestionFile(qid, filename) {
    if (!confirm(`Remove "${filename}" from this question?`)) return;
    const res = await fetch(`${API_BASE}/question/${qid}/files/${encodeURIComponent(filename)}`, {
        method: 'DELETE', headers: getHeaders()
    });
    if (res.ok) {
        showToast(`${filename} removed`);
        await loadQuestionFiles(qid);
        refreshQuestionFileBadge(qid);
    } else {
        showToast('Failed to delete file', true);
    }
}

async function refreshQuestionFileBadge(qid) {
    // Silently refetch the file count and update the badge in the collapsed header
    try {
        const res   = await fetch(`${API_BASE}/question/${qid}/files`, { headers: getHeaders() });
        const files = await res.json();
        const sid   = document.getElementById('qSessionSelect').value;
        if (sid) loadQuestionsForSession(sid); // full re-render keeps it simple
    } catch { /* best-effort */ }
}

// ── Add single question ───────────────────────────────────────

function addTestCaseRow() {
    const container = document.getElementById('testCasesContainer');
    const div = document.createElement('div');
    div.className = 'grid grid-cols-2 gap-2 p-3 bg-gray-50 border border-gray-200 rounded-lg relative';
    div.innerHTML = `
        <div>
            <label class="text-xs text-gray-500 font-medium">Input (stdin)</label>
            <textarea class="tc-input w-full border-gray-300 rounded text-xs font-mono p-1.5 mt-0.5"
                rows="2" placeholder="leave blank if none"></textarea>
        </div>
        <div>
            <label class="text-xs text-gray-500 font-medium">Expected Output <span class="text-red-400">*</span></label>
            <textarea class="tc-output w-full border-gray-300 rounded text-xs font-mono p-1.5 mt-0.5"
                rows="2" placeholder="expected stdout"></textarea>
        </div>
        <div class="col-span-2 flex items-center gap-3">
            <label class="text-xs text-gray-500">Marks:</label>
            <input type="number" class="tc-marks border-gray-300 rounded text-xs w-16 p-1" value="10" min="0">
            <label class="text-xs text-gray-500 ml-3 flex items-center gap-1">
                <input type="checkbox" class="tc-visible"> Visible example
            </label>
            <button type="button" onclick="this.closest('div.grid').remove()"
                class="ml-auto text-xs text-red-500 hover:text-red-700 border border-red-200 bg-red-50 px-2 py-1 rounded">
                ✕ Remove
            </button>
        </div>
    `;
    container.appendChild(div);
}

async function createQuestion() {
    const sid  = document.getElementById('mqSession').value;
    if (!sid)  return showToast('Select session first', true);
    const title = document.getElementById('qTitle').value.trim();
    if (!title) return showToast('Title is required', true);
    const stmt  = document.getElementById('qStmt').value.trim();
    if (!stmt)  return showToast('Problem statement is required', true);

    const tcRows = document.querySelectorAll('#testCasesContainer > div');
    if (tcRows.length === 0) return showToast('Add at least one test case', true);

    const testCases      = [];
    const visibleExamples = [];
    let valid = true;

    tcRows.forEach((row, i) => {
        const out = row.querySelector('.tc-output').value.trim();
        if (!out) { showToast(`Test case ${i + 1}: expected output is required`, true); valid = false; }
        const inp       = row.querySelector('.tc-input').value;
        const marks     = parseInt(row.querySelector('.tc-marks').value) || 10;
        const isVisible = row.querySelector('.tc-visible').checked;
        testCases.push({ input: inp, expected_output: out, marks });
        if (isVisible) visibleExamples.push({ input: inp, output: out, explanation: '' });
    });
    if (!valid) return;

    const payload = {
        session_id      : parseInt(sid),
        title,
        statement       : stmt,
        starter_code    : document.getElementById('qStarter').value,
        test_cases      : testCases,
        visible_examples: visibleExamples,
        language        : 'python',
        constraints     : []
    };

    const res = await fetch(`${API_BASE}/question`, {
        method: 'POST', headers: getHeaders(), body: JSON.stringify(payload)
    });

    if (res.ok) {
        document.getElementById('qTitle').value = '';
        document.getElementById('qStmt').value  = '';
        document.getElementById('qStarter').value = '';
        document.getElementById('testCasesContainer').innerHTML = '';
        closeModal('questionModal');
        await loadInitialData();
        loadQuestionsForSession(document.getElementById('qSessionSelect').value);
        showToast('Question added');
    } else {
        const err = await res.json().catch(() => ({}));
        showToast('Failed: ' + (err.detail || err.message || 'Unknown error'), true);
    }
}

async function deleteQuestion(id) {
    if (!confirm('Permanently delete this question?')) return;
    const res = await fetch(`${API_BASE}/question/${id}`, {
        method: 'DELETE', headers: getHeaders()
    });
    if (res.ok) {
        await loadInitialData();
        loadQuestionsForSession(document.getElementById('qSessionSelect').value);
        showToast('Question deleted');
    } else {
        showToast('Failed to delete question', true);
    }
}

// ── Bulk CSV upload ───────────────────────────────────────────

function openBulkQuestionModal() {
    const bqSel    = document.getElementById('bqSession');
    const currentSid = document.getElementById('qSessionSelect').value;

    bqSel.innerHTML = '<option value="">-- Select Session --</option>';
    filteredSessions.forEach(s => {
        bqSel.innerHTML += `<option value="${s.id}">[${s.id}] ${s.title} (${s.status})</option>`;
    });
    if (currentSid) bqSel.value = currentSid;

    document.getElementById('bqFile').value = '';
    openModal('bulkQuestionModal');
}

async function submitBulkQuestionsCsv() {
    const sid       = document.getElementById('bqSession').value;
    const fileInput = document.getElementById('bqFile');
    if (!sid)                return showToast('Select a session', true);
    if (!fileInput.files.length) return showToast('Select a CSV file', true);

    const reader = new FileReader();
    reader.onload = async function (e) {
        try {
            const rows = parseCsv(e.target.result);
            if (rows.length < 2) return showToast('CSV must have a header and at least one row', true);

            const header = rows[0].map(h => h.toLowerCase().trim());
            const questionsArray = [];

            for (let i = 1; i < rows.length; i++) {
                const row = rows[i];
                const q = {
                    session_id      : parseInt(sid),
                    visible_examples: [],
                    test_cases      : [],
                    language        : 'python',
                    constraints     : []
                };

                for (let j = 0; j < header.length; j++) {
                    const col = header[j];
                    const val = row[j] || '';

                    if      (col === 'title')       q.title        = val;
                    else if (col === 'statement')   q.statement    = val.replaceAll('\\n', '\n');
                    else if (col === 'starter_code') q.starter_code = val.replaceAll('\\n', '\n');
                    else if (col.startsWith('ex') && col.endsWith('_input')) {
                        const idx    = col.match(/\d+/)[0];
                        const outIdx = header.indexOf(`ex${idx}_output`);
                        if (outIdx !== -1 && row[outIdx]) {
                            q.visible_examples.push({
                                input : val.replaceAll('|', '\n'),
                                output: row[outIdx].replaceAll('|', '\n')
                            });
                        }
                    } else if (col.startsWith('test') && col.endsWith('_input')) {
                        const idx      = col.match(/\d+/)[0];
                        const outIdx   = header.indexOf(`test${idx}_output`);
                        const marksIdx = header.indexOf(`test${idx}_marks`);
                        if (outIdx !== -1 && row[outIdx]) {
                            q.test_cases.push({
                                input          : val.replaceAll('|', '\n'),
                                expected_output: row[outIdx].replaceAll('|', '\n'),
                                marks          : marksIdx !== -1 && row[marksIdx] ? parseInt(row[marksIdx]) : 10
                            });
                        }
                    }
                }
                if (q.title && q.statement) questionsArray.push(q);
            }

            if (questionsArray.length === 0)
                return showToast('No valid questions found in CSV', true);

            const res = await fetch(`${API_BASE}/questions/bulk`, {
                method : 'POST',
                headers: getHeaders(),
                body   : JSON.stringify({ session_id: parseInt(sid), questions: questionsArray })
            });

            const data = await res.json();
            if (res.ok) {
                showToast(`Uploaded! Created: ${data.created}, Skipped: ${data.skipped}`);
                if (data.errors && data.errors.length > 0)
                    showToast(`${data.errors.length} errors — check console`, true);
                closeModal('bulkQuestionModal');
                loadQuestionsForSession(sid);
            } else {
                showToast(data.detail || 'Failed to upload', true);
            }
        } catch {
            showToast('Failed to parse CSV file', true);
        }
    };
    reader.readAsText(fileInput.files[0]);
}
