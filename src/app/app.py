from pathlib import Path

import pandas as pd
import streamlit as st

from data_loader import load_data

DATA_FILE = Path("/data/data.csv")

st.set_page_config(page_title="Bluecrest time series", layout="wide")
st.title("Bluecrest time series viewer")
st.caption("Data is loaded from the mounted CSV file at startup.")

if not DATA_FILE.exists():
    st.error(f"CSV file not found: {DATA_FILE}")
    st.stop()

try:
    data = load_data(str(DATA_FILE))
except pd.errors.EmptyDataError:
    st.info("data.csv is empty. Add a CSV with a 'date' column and at least one numeric column.")
    st.stop()
except (ValueError, pd.errors.ParserError) as exc:
    st.error(f"Could not read data.csv: {exc}")
    st.stop()

if "date" not in data.columns:
    st.error("CSV must contain a 'date' column.")
    st.stop()

value_columns = [c for c in data.columns if c != "date" and pd.api.types.is_numeric_dtype(data[c])]
if not value_columns:
    st.warning("No numeric series found. Add one or more numeric columns alongside 'date'.")
    st.stop()

data = data.sort_values("date").set_index("date")
selected = st.multiselect("Series to plot", value_columns, default=value_columns[:1])
if selected:
    st.line_chart(data[selected])
else:
    st.info("Select at least one series to display.")
st.dataframe(data.reset_index(), use_container_width=True)
