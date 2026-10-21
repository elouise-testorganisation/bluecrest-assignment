# Tests

The tests in `test_app.py` check that:

- CSV data with date and numeric columns is loaded and sorted by date.
- Malformed CSV data is cleaned up while keeping usable values and missing values where appropriate.
- A CSV without a `date` header returns a clear validation error.
- A missing CSV file raises a file-not-found error.
- The Streamlit app can still render a chart and data table when the dataset contains malformed values, without raising an app exception.
