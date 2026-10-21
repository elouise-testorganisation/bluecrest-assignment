import os
import sys
from pathlib import Path

import pandas as pd
import streamlit as st

# Streamlit's AppTest executes this file directly, so the app directory is
# not guaranteed to be on sys.path. Ensure sibling modules can be imported
# both in tests and when the app is launched from another working directory.
APP_DIR = Path(__file__).resolve().parent
if str(APP_DIR) not in sys.path:
    sys.path.insert(0, str(APP_DIR))

from data_loader import load_data

DATA_FILE = Path(os.environ.get("BLUECREST_DATA_FILE", "/data/data.csv"))

st.set_page_config(page_title="Bluecrest time series", layout="wide")
st.title("Bluecrest time series viewer")
st.caption("Data is loaded from the mounted CSV file at startup.")

if not DATA_FILE.exists():
    st.error(f"CSV file not found: {DATA_FILE}")
    st.stop()

try:
    data = load_data(DATA_FILE)
except pd.errors.EmptyDataError:
    st.info("data.csv is empty. Add a CSV with a 'date' column and at least one numeric column.")
    st.stop()
except (ValueError, pd.errors.ParserError) as exc:
    st.error(f"Could not read data.csv: {exc}")
    st.stop()

value_columns = [column for column in data.columns if column != "date"]
if not value_columns:
    st.warning("No numeric series found. Add one or more numeric columns alongside 'date'.")
    st.stop()

data = data.sort_values("date").set_index("date")
selected = st.multiselect("Series to plot", value_columns, default=value_columns[:1])
if selected:
    # Streamlit's line chart accepts NaNs, preserving gaps instead of failing
    # or fabricating values for missing observations.
    st.line_chart(data[selected])
else:
    st.info("Select at least one series to display.")
st.dataframe(data.reset_index(), width="stretch")
