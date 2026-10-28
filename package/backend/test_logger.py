import datetime
import json
import os
import shutil
import tempfile
import unittest

from backend.logger import (
    calculate_logical_date,
    read_all_logs,
    append_log_record,
    get_default_log_file,
)


class TestDailyLogger(unittest.TestCase):
    def setUp(self):
        self.test_dir = tempfile.mkdtemp()
        self.log_file = os.path.join(self.test_dir, "daily_logs.txt")

    def tearDown(self):
        shutil.rmtree(self.test_dir, ignore_errors=True)

    def test_logical_date_calculation(self):
        # 04:59 AM should be attributed to previous day
        dt_night_owl = datetime.datetime(2026, 10, 28, 4, 59, 59)
        self.assertEqual(
            calculate_logical_date(dt_night_owl),
            datetime.date(2026, 10, 27),
        )

        # 05:00 AM should belong to current day
        dt_morning = datetime.datetime(2026, 10, 28, 5, 0, 0)
        self.assertEqual(
            calculate_logical_date(dt_morning),
            datetime.date(2026, 10, 28),
        )

        # Midnight should belong to previous day
        dt_midnight = datetime.datetime(2026, 10, 28, 0, 0, 0)
        self.assertEqual(
            calculate_logical_date(dt_midnight),
            datetime.date(2026, 10, 27),
        )

    def test_append_and_read_records(self):
        record1 = {
            "id": "11111111",
            "timestamp": "2026-10-28T09:00:00",
            "date": "2026-10-28",
            "entry": "First reflection",
        }
        record2 = {
            "id": "22222222",
            "timestamp": "2026-10-28T21:00:00",
            "date": "2026-10-28",
            "entry": "Second reflection",
        }

        append_log_record(self.log_file, record1)
        append_log_record(self.log_file, record2)

        records = read_all_logs(self.log_file)
        self.assertEqual(len(records), 2)
        self.assertEqual(records[0]["entry"], "First reflection")
        self.assertEqual(records[1]["entry"], "Second reflection")

    def test_read_malformed_json_skips_cleanly(self):
        with open(self.log_file, "w", encoding="utf-8") as f:
            f.write('{"id": "valid", "entry": "Valid entry"}\n')
            f.write("MALFORMED JSON LINE\n")
            f.write('{"id": "valid2", "entry": "Second valid"}\n')

        records = read_all_logs(self.log_file)
        self.assertEqual(len(records), 2)
        self.assertEqual(records[0]["id"], "valid")
        self.assertEqual(records[1]["id"], "valid2")

    def test_nested_directory_creation(self):
        nested_file = os.path.join(self.test_dir, "nested", "deep", "logs.txt")
        record = {
            "id": "abc12345",
            "timestamp": "2026-10-28T10:00:00",
            "date": "2026-10-28",
            "entry": "Nested write",
        }
        append_log_record(nested_file, record)
        self.assertTrue(os.path.exists(nested_file))
        records = read_all_logs(nested_file)
        self.assertEqual(len(records), 1)


if __name__ == "__main__":
    unittest.main()
