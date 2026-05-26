// ============================================================
// File: app/static/js/departments.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Department tab — list, create, and delete
//              departments. Also populates department dropdowns
//              inside the Session and Student modals.
// ============================================================

async function loadDepartments() {
    try {
        const res = await fetch(`${API_BASE}/departments`, { headers: getHeaders() });
        allDepts  = await res.json();

        const list = document.getElementById('deptsList');
        if (list) {
            list.innerHTML = '';
            allDepts.forEach(d => {
                list.innerHTML += `
                    <tr class="hover:bg-gray-50">
                        <td class="px-6 py-4">${d.id}</td>
                        <td class="px-6 py-4 font-medium text-gray-800">${d.name}</td>
                        <td class="px-6 py-4 font-mono">${d.code}</td>
                        <td class="px-6 py-4 text-right">
                            <button onclick="deleteDepartment(${d.id})"
                                class="text-red-600 hover:text-red-900 text-xs font-bold border border-red-200 bg-red-50 px-2 py-1 rounded shadow-sm">
                                Delete
                            </button>
                        </td>
                    </tr>
                `;
            });
        }

        // Populate dept dropdowns inside modals (session + student)
        const sDept  = document.getElementById('sDept');
        const stDept = document.getElementById('stDept');

        if (sDept && sDept.tagName === 'SELECT') {
            sDept.innerHTML  = '';
            stDept.innerHTML = '';
            allDepts.forEach(d => {
                sDept.innerHTML  += `<option value="${d.code}">${d.code}</option>`;
                stDept.innerHTML += `<option value="${d.code}">${d.code}</option>`;
            });
        } else if (sDept && sDept.tagName === 'INPUT') {
            const opts = allDepts.map(d => `<option value="${d.code}">${d.code}</option>`).join('');
            sDept.outerHTML  = `<select id="sDept"  class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">${opts}</select>`;
            stDept.outerHTML = `<select id="stDept" class="mt-1 block w-full border-gray-300 rounded-md shadow-sm">${opts}</select>`;
        }
    } catch (e) { console.error('loadDepartments error', e); }
}

async function createDepartment() {
    const payload = {
        name: document.getElementById('dName').value,
        code: document.getElementById('dCode').value.toUpperCase()
    };
    const res = await fetch(`${API_BASE}/department`, {
        method: 'POST', headers: getHeaders(), body: JSON.stringify(payload)
    });
    if (res.ok) {
        closeModal('deptModal');
        showToast('Department created');
        await loadDepartments();
        await loadInitialData();
    } else {
        showToast('Failed to create department', true);
    }
}

async function deleteDepartment(id) {
    if (!confirm('Delete this department?')) return;
    const res = await fetch(`${API_BASE}/department/${id}`, {
        method: 'DELETE', headers: getHeaders()
    });
    if (res.ok) {
        showToast('Department deleted');
        await loadDepartments();
        await loadInitialData();
    } else {
        showToast('Failed to delete department', true);
    }
}
