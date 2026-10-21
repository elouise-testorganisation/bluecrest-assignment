import os
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import pandas as pd
from streamlit.testing.v1 import AppTest

from app.data_loader import load_data


class LoadDataTests(unittest.TestCase):
    def test_reads_date_and_numeric_series(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sample.csv"
            path.write_text("date,value\n2025-01-02,2.5\n2025-01-01,1.5\n", encoding="utf-8")
            result = load_data(path)
            self.assertTrue(pd.api.types.is_datetime64_any_dtype(result["date"]))
            self.assertEqual(result["value"].tolist(), [1.5, 2.5])

    def test_cleans_malformed_csv_without_discarding_usable_values(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sample.csv"
            path.write_text(
                " Date ,A,B,C,\n"
                "2025-01-02,2.5,,4.0,\n"
                "2025-01-01,1.5,3.0,not-a-number,\n"
                "2025-01-03,,,,\n"
                "2025-01-04,4.0,5.0,6.0,\n",
                encoding="utf-8",
            )
            result = load_data(path)
            self.assertEqual(result.columns.tolist(), ["date", "a", "b", "c"])
            self.assertEqual(len(result), 3)
            self.assertTrue(pd.isna(result.loc[1, "b"]))
            self.assertEqual(result.loc[0, "a"], 1.5)

    def test_missing_date_header_is_a_clear_validation_error(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "sample.csv"
            path.write_text("value\n2.5\n", encoding="utf-8")
            with self.assertRaisesRegex(ValueError, "date"):
                load_data(path)

    def test_missing_file_raises(self):
        with self.assertRaises(FileNotFoundError):
            load_data("/path/that/does/not/exist.csv")


class ApplicationBehaviorTests(unittest.TestCase):
    def test_malformed_dataset_still_renders_chart_and_table(self):
        with tempfile.TemporaryDirectory() as directory:
            data_path = Path(directory) / "sample.csv"
            data_path.write_text(
                "Date,A,B,\n"
                "2025-01-01,1.0,,\n"
                "2025-01-02,2.0,3.0,\n"
                "2025-01-03,broken,4.0,\n",
                encoding="utf-8",
            )
            app_path = Path(__file__).parents[1] / "app" / "app.py"
            with patch.dict(os.environ, {"BLUECREST_DATA_FILE": str(data_path)}):
                app = AppTest.from_file(str(app_path)).run()

            self.assertEqual(len(app.exception), 0)
            chart_elements = (
                app.get("line_chart")
                or app.get("vega_lite_chart")
                or app.get("arrow_vega_lite_chart")
            )
            self.assertGreaterEqual(len(chart_elements), 1)

            # Streamlit 1.50 exposes st.dataframe as "arrow_data_frame".
            # Keep the older "dataframe" key as a fallback for compatibility.
            dataframe_elements = app.get("arrow_data_frame") or app.get("dataframe")
            self.assertGreaterEqual(len(dataframe_elements), 1)


if __name__ == "__main__":
    unittest.main()
