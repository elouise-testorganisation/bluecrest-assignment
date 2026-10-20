import pandas as pd


def load_data(path: str) -> pd.DataFrame:
    """Load a CSV with a date column and one or more numeric series."""
    return pd.read_csv(path, parse_dates=["date"])
