"""DailyLogger Backend CLI

Supports:
- log: record a daily entry with logical date attribution (00:00-04:59 belongs to previous day)
- has-logged: checks if a log exists for the current logical date (exit code 0 if exists, 1 if not)
- list: list recent logs with formatting, limits, and reverse order
"""

import argparse
import datetime
import json
import os
import sys
import uuid


def get_default_log_file() -> str:
    """Resolve default log file path.
    Precedence:
    1. DAILY_LOG_FILE environment variable
    2. %LOCALAPPDATA%\\DailyLogger\\daily_logs.txt (on Windows)
    3. ~/.dailylogger/daily_logs.txt or ./daily_logs.txt fallback
    """
    env_path = os.environ.get("DAILY_LOG_FILE")
    if env_path:
        return env_path

    local_app_data = os.environ.get("LOCALAPPDATA")
    if local_app_data:
        return os.path.join(local_app_data, "DailyLogger", "daily_logs.txt")

    # Non-Windows or fallback
    home = os.path.expanduser("~")
    return os.path.join(home, ".dailylogger", "daily_logs.txt")


def calculate_logical_date(now: datetime.datetime = None) -> datetime.date:
    """Calculate logical date where 00:00 - 04:59 belongs to the previous day."""
    if now is None:
        now = datetime.datetime.now()
    if now.hour < 5:
        return now.date() - datetime.timedelta(days=1)
    return now.date()


def read_all_logs(file_path: str) -> list[dict]:
    """Read all valid JSON Lines records from the log file."""
    if not os.path.exists(file_path):
        return []
    records = []
    with open(file_path, "r", encoding="utf-8") as f:
        for line_num, line in enumerate(f, start=1):
            line = line.strip()
            if not line:
                continue
            try:
                record = json.loads(line)
                records.append(record)
            except json.JSONDecodeError as e:
                sys.stderr.write(f"Warning: skipping invalid JSON at line {line_num}: {e}\n")
    return records


def append_log_record(file_path: str, record: dict) -> None:
    """Append a record as a single JSON line to the log file."""
    parent_dir = os.path.dirname(file_path)
    if parent_dir and not os.path.exists(parent_dir):
        os.makedirs(parent_dir, exist_ok=True)

    with open(file_path, "a", encoding="utf-8") as f:
        f.write(json.dumps(record, ensure_ascii=False) + "\n")


def cmd_log(args: argparse.Namespace) -> int:
    """Handle log command."""
    entry_text = args.text
    if entry_text is None:
        # Read from stdin if not provided on CLI
        entry_text = sys.stdin.read()

    entry_text = entry_text.strip()
    if not entry_text:
        sys.stderr.write("Error: Log entry text cannot be empty.\n")
        return 1

    now = datetime.datetime.now()
    if args.date:
        try:
            logical_date_str = datetime.datetime.strptime(args.date, "%Y-%m-%d").date().isoformat()
        except ValueError:
            sys.stderr.write(f"Error: Invalid date format '{args.date}'. Expected YYYY-MM-DD.\n")
            return 1
    else:
        logical_date_str = calculate_logical_date(now).isoformat()

    record = {
        "id": uuid.uuid4().hex[:8],
        "timestamp": now.strftime("%Y-%m-%dT%H:%M:%S"),
        "date": logical_date_str,
        "entry": entry_text,
    }

    try:
        append_log_record(args.file, record)
        print(json.dumps({"status": "success", "record": record}))
        return 0
    except Exception as e:
        sys.stderr.write(f"Error saving log entry: {e}\n")
        return 1


def cmd_has_logged(args: argparse.Namespace) -> int:
    """Handle has-logged command. Exits with code 0 if entry exists for logical date, 1 otherwise."""
    if args.date:
        try:
            target_date = datetime.datetime.strptime(args.date, "%Y-%m-%d").date().isoformat()
        except ValueError:
            sys.stderr.write(f"Error: Invalid date format '{args.date}'. Expected YYYY-MM-DD.\n")
            return 1
    else:
        target_date = calculate_logical_date().isoformat()

    records = read_all_logs(args.file)
    matching = [r for r in records if r.get("date") == target_date]
    if matching:
        print(json.dumps({"has_logged": True, "date": target_date, "count": len(matching)}))
        return 0
    else:
        print(json.dumps({"has_logged": False, "date": target_date, "count": 0}))
        return 1


def cmd_list(args: argparse.Namespace) -> int:
    """Handle list command."""
    records = read_all_logs(args.file)
    if args.reverse:
        records.reverse()
    if args.limit and args.limit > 0:
        records = records[: args.limit]

    print(json.dumps(records, indent=2 if args.pretty else None))
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description="DailyLogger Backend CLI")
    parser.add_argument(
        "--file",
        default=get_default_log_file(),
        help="Path to daily_logs.txt (default: resolved from env or %%LOCALAPPDATA%%)",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    # log
    log_parser = subparsers.add_parser("log", help="Record a daily reflection")
    log_parser.add_argument("--text", help="Reflection text content")
    log_parser.add_argument("--date", help="Explicit logical date (YYYY-MM-DD)")

    # has-logged
    has_logged_parser = subparsers.add_parser(
        "has-logged", help="Check if an entry exists for the logical date"
    )
    has_logged_parser.add_argument("--date", help="Check specific date (YYYY-MM-DD)")

    # list
    list_parser = subparsers.add_parser("list", help="List recorded entries")
    list_parser.add_argument("--limit", type=int, default=None, help="Maximum number of entries")
    list_parser.add_argument("--reverse", action="store_true", help="Reverse chronological order")
    list_parser.add_argument("--pretty", action="store_true", help="Pretty print output JSON")

    args = parser.parse_args()

    if args.command == "log":
        return cmd_log(args)
    elif args.command == "has-logged":
        return cmd_has_logged(args)
    elif args.command == "list":
        return cmd_list(args)
    return 0


if __name__ == "__main__":
    sys.exit(main())
