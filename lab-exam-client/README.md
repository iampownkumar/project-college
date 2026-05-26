# Lab Exam Client

**Flutter Desktop App** — Student-side client for the Korelium Labs Exam System.

## Project Layout

```
lab-exam-client/
  lib/
    main.dart                    ← entry point (config load, window init)
    app/
      app.dart                   ← root MaterialApp + routing
      routes.dart                ← named routes
      theme.dart                 ← dark / light themes
    core/
      config/                    ← AppConfig model + loader
      constants/                 ← API paths, app constants
      utils/                     ← machine name/IP
      errors/                    ← custom exception types
    data/
      models/                    ← LoginResponse, Question, RunnerResult
      services/                  ← ApiService, PythonRunnerService, AutosaveService
    features/
      auth/                      ← AuthProvider + LoginScreen
      exam/                      ← ExamProvider + ExamScreen + widgets
      editor/                    ← CodeEditorWidget (re_editor)
      theme/                     ← ThemeProvider
  config/
    app_config.json              ← server URL, intervals, Python path
  runtime/
    runner/
      execute_student_code.py    ← Python wrapper script
    requirements.txt             ← pandas, numpy, matplotlib, seaborn
```

## Configuration

Edit `config/app_config.json` before distributing to students:

```json
{
  "server": {
    "base_url": "http://<SERVER_LAN_IP>:8000/api/v1",
    "heartbeat_interval_seconds": 15
  },
  "python": {
    "executable_path": "./runtime/python/python.exe",
    "runner_script": "./runtime/runner/execute_student_code.py",
    "timeout_seconds": 30
  },
  "exam": {
    "autosave_interval_seconds": 15,
    "fullscreen": true,
    "default_duration_minutes": 120
  }
}
```

## Development (macOS)

```bash
# Install dependencies
flutter pub get

# Run on macOS for local dev/testing
flutter run -d macos
```

> **Note:** The Python runner will fall back to system `python3` automatically
> when `./runtime/python/python.exe` doesn't exist (dev mode).

## Build for Windows (on a Windows machine)

```cmd
flutter pub get
flutter build windows --release
```

The output will be in `build\windows\runner\Release\`.

Copy the full folder including:
- `lab_exam_client.exe`
- All DLLs in the release folder
- `config/app_config.json`
- `runtime/` directory (bundled Python + runner script)

## Bundling Python (Windows)

1. Download Python embeddable package for Windows:
   `https://www.python.org/downloads/`
2. Extract to `runtime/python/`
3. Install required packages offline:
   ```cmd
   runtime\python\python.exe -m pip install -r runtime\requirements.txt --no-index --find-links runtime\wheels\
   ```

## Server API Endpoints Used

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/health` | Connectivity check |
| POST | `/auth/login` | Student login |
| GET | `/question/assigned/{reg_no}` | Fetch question |
| POST | `/heartbeat` | Live status ping |
| POST | `/run-log` | Code run history |
| POST | `/submission` | Final submission |
