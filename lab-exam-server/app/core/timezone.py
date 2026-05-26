# ============================================================
# File: app/core/timezone.py
# Project: Local Lab Exam System - Coordinator Server
# Author: Pownkumar A (Founder of Korelium)
# Created: 2026-05-26
# Last Updated: 2026-05-26
# Location: Tamil Nadu, India
# Description: IST timezone utilities.
#              All server datetimes are stored and computed in IST.
#              These helpers ensure that naive datetimes read from
#              SQLite get IST info attached before JSON serialisation,
#              so the dashboard and client always see "+05:30" offset
#              and display the correct local time.
# ============================================================

from datetime import datetime, timezone, timedelta

# Indian Standard Time — UTC+05:30
IST = timezone(timedelta(hours=5, minutes=30))


def to_ist(dt: datetime | None) -> datetime | None:
    """
    Convert any datetime to IST-aware.
    - If dt is None            → return None
    - If dt is naive (no tzinfo) → assume it is already IST, attach offset
    - If dt is UTC-aware       → convert to IST
    - If dt is already IST     → return as-is
    """
    if dt is None:
        return None
    if dt.tzinfo is None:
        # SQLite strips timezone; the value was inserted as IST so just attach
        return dt.replace(tzinfo=IST)
    # Convert any other tz-aware datetime to IST
    return dt.astimezone(IST)


def now_ist() -> datetime:
    """Return the current moment as an IST-aware datetime."""
    return datetime.now(IST)
