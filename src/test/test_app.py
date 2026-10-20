import tempfile
import unittest
from pathlib import Path

import pandas as pd

from data_loader import load_data


class LoadDataTests(unittest.TestCase):
    def test_reads_date_and_numeric_series(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sample.csv"
            path.write_text("date,value\n2025-01-02,2.5\n2025-01-01,1.5\n", encoding="utf-8")
            result = load_data(str(path))
            self.assertTrue(pd.api.types.is_datetime64_any_dtype(result["date"]))
            self.assertEqual(result["value"].tolist(), [2.5, 1.5])

    def test_missing_file_raises(self):
        with self.assertRaises(FileNotFoundError):
            load_data("/path/that/does/not/exist.csv")


if __name__ == "__main__":
    unittest.main()
