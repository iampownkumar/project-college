// ============================================================
// File: app/static/js/common.js
// Project: Local Lab Exam System - Coordinator Server
// Author: Pownkumar A (Founder of Korelium)
// Created: 2026-05-26
// Last Updated: 2026-05-26
// Location: Tamil Nadu, India
// Description: Shared utilities for the admin dashboard.
//              Provides: API fetch wrapper, toast notifications,
//              HTML escape, time formatters, nav switcher,
//              server status indicator, and boot sequence.
// ============================================================

const BASE = '';

// ── API ───────────────────────────────────────────────────
async function api(method, path, body = null) {
  const opts = { method, headers: { 'Content-Type': 'application/json' } };
  if (body !== null) opts.body = JSON.stringify(body);
  const res = await fetch(BASE + path, opts);
  if (!res.ok) {
    const e = await res.json().catch(() => ({ detail: res.statusText }));
    throw new Error(e.detail || res.statusText);
  }
  return res.status === 204 ? null : res.json();
}

// ── Toast ─────────────────────────────────────────────────
function toast(msg, type = 'inf', ms = 3500) {
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.innerHTML = `<span>${msg}</span>`;
  document.getElementById('toasts').appendChild(el);
  setTimeout(() => el.remove(), ms);
}

// ── Escape HTML ───────────────────────────────────────────
function esc(s) {
  return String(s ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// ── Time Helpers ──────────────────────────────────────────
function fmt(iso) {
  if (!iso) return '—';
  return new Date(iso).toLocaleString('en-IN', {
    timeZone: 'Asia/Kolkata',
    day: '2-digit', month: 'short',
    hour: '2-digit', minute: '2-digit',
  });
}

function since(iso) {
  if (!iso) return '—';
  const s = Math.floor((Date.now() - new Date(iso)) / 1000);
  if (s < 60)   return `${s}s ago`;
  if (s < 3600) return `${Math.floor(s / 60)}m ago`;
  return `${Math.floor(s / 3600)}h ago`;
}

// ── Nav ───────────────────────────────────────────────────
function showView(name) {
  document.querySelectorAll('.view').forEach(v => v.classList.add('hidden'));
  document.querySelectorAll('.nav-item').forEach(b => b.classList.remove('active'));

  const viewMap = { sessions: 'view-sessions', students: 'view-students' };
  const navMap  = { sessions: 'navSessions',   students: 'navStudents'   };

  if (viewMap[name]) {
    document.getElementById(viewMap[name]).classList.remove('hidden');
    document.getElementById(navMap[name]).classList.add('active');
  }

  // Notify modules
  if (typeof stopMonitor === 'function') stopMonitor();
  if (name === 'sessions' && typeof loadSessions === 'function') loadSessions();
  if (name === 'students' && typeof loadStudentView === 'function') loadStudentView();
}

// ── Server Status ─────────────────────────────────────────
async function checkServer() {
  try {
    await fetch('/api/v1/health');
    document.getElementById('sdot').className = 'sdot on';
    document.getElementById('slabel').textContent = 'Server online';
  } catch {
    document.getElementById('sdot').className = 'sdot off';
    document.getElementById('slabel').textContent = 'Server offline';
  }
}

// ── Boot ──────────────────────────────────────────────────
document.addEventListener('DOMContentLoaded', () => {
  // Nav buttons
  document.getElementById('navSessions').addEventListener('click', () => showView('sessions'));
  document.getElementById('navStudents').addEventListener('click', () => showView('students'));

  // Modal backdrop click to close
  document.getElementById('modalBackdrop').addEventListener('click', e => {
    if (e.target === document.getElementById('modalBackdrop')) closeModal();
  });

  checkServer();
  setInterval(checkServer, 15000);

  // Default view
  showView('sessions');
});
