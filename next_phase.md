# Next Phase: Session Auto-Start + Faculty File Attachments

**Project:** Lab Exam System — Korelium Labs  
**Author:** Pownkumar A  
**Created:** 2026-05-26  
**Status:** Architecture only — no code yet

---

## What is Already Done

Before reading further, these features are **fully implemented**:

| Feature | Status |
|---|---|
| `QuestionFile` ORM model + DB table | ✅ Done |
| `FileService` (upload, delete, list, download) | ✅ Done |
| Admin API routes (`POST/DELETE/GET /admin/question/{id}/files`) | ✅ Done |
| Student API routes (`GET /question/{id}/files/{filename}`) | ✅ Done |
| `SandboxService` (client-side file cache) | ✅ Done |
| `FilesPanel` widget (in-app file browser + previewer) | ✅ Done |
| Python runner `workingDirectory` = sandbox path | ✅ Done |
| Interactive terminal (unified buffer + inline input) | ✅ Done |
| IST timezone display fix | ✅ Done |

**What is NOT done yet** is covered below.

---

## Phase 1 — Session Auto-Start (Verify + Fix)

### Current Behaviour (Problem)

Right now the session lifecycle is **100% manual**:

```
Faculty creates session → sets start_time → clicks "Activate" manually
```

The `start_time` field is stored but **never checked** by the server.  
The dashboard has an auto-close timer (JS `setInterval`) but **no auto-activate**.

This means if a faculty forgets to click "Activate" at the right time,  
students cannot log in even though the scheduled time has passed.

### Desired Behaviour

```
Faculty creates session → sets start_time → walks away
Server auto-activates when start_time is reached
Server auto-closes when end_time is reached (already done in JS)
```

### Architecture

#### Option A — Server-side Background Task (Recommended)

Add a `APScheduler` background job that runs every **30 seconds**:

```
Server startup
  └─ scheduler.add_job(check_session_timings, 'interval', seconds=30)

check_session_timings():
  For each draft session where start_time <= now_ist():
    activate it (same logic as update_session_status('active'))
    close any previously active session first
  For each active session where end_time <= now_ist():
    close it (already done client-side but server must be source of truth)
```

**Why server-side:**
- Works even if dashboard browser is closed
- Single source of truth
- No race conditions between multiple admin browser tabs

**New dependency:** `apscheduler` (already in most FastAPI setups)

#### Option B — Dashboard JS Poll (Simpler, Less Reliable)

The existing `setInterval` in dashboard.html already polls every second.  
Add a check: if `session.status === 'draft' && new Date(session.start_time) <= new Date()` → call activate API.

**Problem:** Requires the dashboard to be open. Not reliable for real exams.

**Verdict: Use Option A (APScheduler).**

### Files to Change

| File | Change |
|---|---|
| `requirements.txt` | Add `apscheduler>=3.10.0` |
| `app/core/scheduler.py` | **NEW** — create scheduler instance |
| `app/services/session_scheduler.py` | **NEW** — `check_session_timings()` job |
| `app/main.py` | Start scheduler in lifespan startup |
| `app/services/admin_service.py` | Extract `_activate_session()` as reusable method |
| `app/static/dashboard.html` | Remove JS auto-close (move to server), show "Scheduled" badge |

### Verification Steps (Manual Test)

1. Create a session, set `start_time` = now + 1 min
2. Do NOT click Activate
3. Wait 1 min
4. Refresh dashboard → session should show `active`
5. Wait for `end_time` → session should auto-close to `closed`
6. Student client should see "Server Unreachable" after close (session locked)

---

## Phase 2 — Faculty File Attachments UI (Dashboard)

### What is Already Done

The entire backend pipeline is complete. The missing piece is  
**the dashboard HTML UI** that lets faculty upload/delete files per question.

### Desired Flow

```
Faculty opens Questions tab
  → Clicks a question row to expand it
  → Sees "Attached Files" section
  → Uploads CSV / image / JSON via file picker
  → Sees the list of uploaded files with delete buttons
  → Students automatically get the files in their sandbox on login
```

### Architecture

#### Dashboard HTML Changes Only (no server changes needed)

The dashboard needs two new UI components inside the Questions tab:

---

#### 2.1 Question Row Expansion Panel

Currently questions are shown as a flat table row. Change to **accordion/expandable rows**:

```
[+] Question 3 — Sum of Two Numbers        [Python]  [Delete]
    ↓ (expanded)
    ┌─────────────────────────────────────────────────────┐
    │  Statement: Write a program...                       │
    │                                                      │
    │  📎 Attached Files                                   │
    │  ┌──────────────────────────────────┐               │
    │  │  data.csv      12 KB   [✕]       │               │
    │  │  sample.png    45 KB   [✕]       │               │
    │  └──────────────────────────────────┘               │
    │  [+ Attach File]  (max 5 files, 10 MB each)         │
    └─────────────────────────────────────────────────────┘
```

#### 2.2 File Upload Component

- `<input type="file">` with `accept=".csv,.json,.txt,.png,.jpg,.jpeg,.png,.dat"`
- On select → `POST /api/v1/admin/question/{id}/files` (multipart form)
- On success → refresh the file list for that question
- Each file row has a `[✕]` button → `DELETE /api/v1/admin/question/{id}/files/{filename}`
- Show file size next to name

#### 2.3 Visual Indicators

- Question rows with files show a 📎 badge with file count
- Hover tooltip: "3 files attached — students will see these in their sandbox"

#### 2.4 Allowed File Types (enforced by server already)

| Extension | Use Case |
|---|---|
| `.csv` | Data analysis questions |
| `.json` | API/data structure questions |
| `.txt` | Input files, word lists |
| `.dat` | Binary data |
| `.png`, `.jpg`, `.jpeg` | Image processing questions |
| `.bmp` | Legacy image format |

> Max 5 files per question. Max 10 MB per file.  
> Server already enforces these limits — just surface them in the UI.

---

## Phase 3 — What Comes After (Backlog)

These are future items, not part of the next sprint:

### 3.1 Smart Test Case Validation

**Problem:** `c = a + b` and `c = (a-1) + (b+2)` — same result for some inputs,  
but the code is semantically different. Pure string comparison fails here.

**Architecture Idea:**
- Run student code against all hidden test cases
- Compare **output** not **code** (output-based validation — already done)
- For numerical tolerance: `abs(expected - actual) < 0.001`
- For string outputs: strip whitespace, case-insensitive compare option
- For "equivalent code" detection: run multiple random inputs and check consistency

### 3.2 Admin Dashboard File Preview

Faculty should be able to preview uploaded files in the dashboard  
(open CSV in a table, show image inline) before assigning the question.

### 3.3 Submission Code Diff View

Show a diff between the student's final submission and the starter code  
so faculty can quickly see what the student changed.

### 3.4 Student Progress Export

Export session results as CSV: student name, question, run count,  
submitted (yes/no), exit code, final code.

---

## Summary — Next Sprint Priority

| Priority | Task | Effort |
|---|---|---|
| 🔴 High | Session auto-start (APScheduler) | ~2 hours |
| 🟡 Medium | Dashboard file upload UI | ~3 hours |
| 🟢 Low | Smart test case tolerance | ~4 hours |
| 🟢 Low | Submission diff view | ~2 hours |
