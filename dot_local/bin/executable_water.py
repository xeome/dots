#!/usr/bin/env python3
import os
import sys
import json
import time
from datetime import datetime, timedelta

CACHE_DIR = os.path.expanduser("~/.cache")
LAST_DRINK_FILE = os.path.join(CACHE_DIR, "water_last_drink")
LOG_FILE = os.path.join(CACHE_DIR, "water_log.json")
DEHYDRATION_SECONDS = 60 * 60  # 1 hour
LOG_RETENTION_DAYS = 7

def get_today_key():
    return datetime.now().strftime("%Y-%m-%d")

def load_log():
    if os.path.exists(LOG_FILE):
        try:
            with open(LOG_FILE, "r") as f:
                return json.load(f)
        except (json.JSONDecodeError, IOError):
            pass
    return {}

def save_log(log):
    cutoff = (datetime.now() - timedelta(days=LOG_RETENTION_DAYS)).strftime("%Y-%m-%d")
    log = {k: v for k, v in log.items() if k >= cutoff}
    with open(LOG_FILE, "w") as f:
        json.dump(log, f)

def drink():
    now = time.time()
    today = get_today_key()

    os.makedirs(CACHE_DIR, exist_ok=True)
    with open(LAST_DRINK_FILE, "w") as f:
        f.write(str(int(now)))

    log = load_log()
    if today not in log:
        log[today] = {"count": 0, "first": int(now)}
    log[today]["count"] = log[today].get("count", 0) + 1
    log[today]["last"] = int(now)
    save_log(log)

def get_status():
    now = time.time()
    today = get_today_key()
    today_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0)
    today_start_ts = today_start.timestamp()

    if not os.path.exists(LAST_DRINK_FILE):
        return "hydrated", "Start your day!"

    try:
        with open(LAST_DRINK_FILE, "r") as f:
            last_drink = float(f.read().strip())
    except (ValueError, IOError):
        return "hydrated", "Start your day!"

    if last_drink < today_start_ts:
        return "dehydrated", "New day - drink water!"

    elapsed = now - last_drink
    remaining = DEHYDRATION_SECONDS - elapsed

    if remaining > 0:
        mins_left = int(remaining // 60)
        hours = mins_left // 60
        mins = mins_left % 60
        if hours > 0:
            return "hydrated", f"{hours}h {mins}m until reminder"
        return "hydrated", f"{mins}m until reminder"

    overdue = int(-remaining)
    ov_minutes = overdue // 60
    return "dehydrated", f"Overdue by {ov_minutes}m - drink water!"

def get_tooltip():
    log = load_log()
    today = get_today_key()
    today_data = log.get(today, {})

    if today_data:
        count = today_data.get("count", 0)
        return f"Glasses today: {count}\nClick to log water"
    return "No water logged today\nClick to log water"

def output_json():
    status, status_text = get_status()

    log = load_log()
    today = get_today_key()
    today_data = log.get(today, {})
    count = today_data.get("count", 0)

    result = {
        "text": f"💧 {count}",
        "class": status,
        "tooltip": f"{get_tooltip()}\nStatus: {status_text}"
    }
    print(json.dumps(result))

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--drank":
        drink()
        print("Logged water!")
    else:
        output_json()
