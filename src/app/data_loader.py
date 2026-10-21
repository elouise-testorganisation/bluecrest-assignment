from pathlib import Path

import pandas as pd


def load_data(path: str | Path) -> pd.DataFrame:
    """Load and clean a time-series CSV while retaining usable observations.

    Header matching is case-insensitive. Empty header columns are discarded;
    date values and numeric series are coerced so isolated malformed cells do
    not prevent the rest of the dataset from being plotted. A series or row
    with fewer than half of its expected datapoints is discarded.
    """
    raw = pd.read_csv(path, dtype=str, skip_blank_lines=False)

    # Normalise whitespace/case and discard unnamed columns (including a
    # common trailing comma in CSV headers).
    normalised = [str(column).strip().lower() for column in raw.columns]
    keep = [i for i, name in enumerate(normalised) if name and not name.startswith("unnamed:")]
    raw = raw.iloc[:, keep].copy()
    raw.columns = [normalised[i] for i in keep]

    if "date" not in raw.columns:
        raise ValueError("CSV must contain a 'date' header.")

    # Keep the first date column if duplicate/case-variant headers occur.
    if raw.columns.tolist().count("date") > 1:
        raw = raw.loc[:, ~pd.Index(raw.columns).duplicated(keep="first")]

    raw["date"] = pd.to_datetime(raw["date"].astype("string").str.strip(), errors="coerce")
    raw = raw.loc[raw["date"].notna()].copy()
    if raw.empty:
        raise ValueError("CSV has no rows with valid dates.")

    numeric_columns: list[str] = []
    for column in raw.columns:
        if column == "date":
            continue
        values = pd.to_numeric(raw[column].astype("string").str.strip(), errors="coerce")
        # A numeric series must have usable values in at least half of the
        # dated rows. Retain NaNs within otherwise useful series for plotting.
        if values.notna().sum() * 2 >= len(raw):
            raw[column] = values
            numeric_columns.append(column)

    if not numeric_columns:
        raise ValueError("CSV must contain at least one numeric series with usable datapoints.")

    # Rows need a date and at least half of the retained series datapoints.
    required_series = len(numeric_columns)
    minimum_values = (required_series + 1) // 2
    enough_values = raw[numeric_columns].notna().sum(axis=1) >= minimum_values
    cleaned = raw.loc[enough_values, ["date", *numeric_columns]].copy()
    if cleaned.empty:
        raise ValueError("CSV has no rows with enough usable datapoints to plot.")

    return cleaned.sort_values("date").reset_index(drop=True)
