# Build dependencies in a builder stage; keep the runtime layer small.
FROM python:3.12-slim AS builder

ENV PIP_NO_CACHE_DIR=1
WORKDIR /build
COPY app/requirements.txt ./requirements.txt
RUN python -m pip install --no-cache-dir --prefix=/install -r requirements.txt

FROM python:3.12-slim AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    STREAMLIT_BROWSER_GATHER_USAGE_STATS=false \\\n    HOME=/tmp \\\n    STREAMLIT_CONFIG_DIR=/tmp/.streamlit

RUN groupadd --system --gid 10001 app \
    && useradd --system --uid 10001 --gid app --home-dir /nonexistent \
       --shell /usr/sbin/nologin --no-create-home app \
    && mkdir -p /app /data \
    && chown -R 10001:10001 /app /data

COPY --from=builder /install/ /usr/local/
COPY --chown=10001:10001 app/ /app/
WORKDIR /app

USER 10001:10001
EXPOSE 8501
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8501/_stcore/health', timeout=2)" || exit 1
ENTRYPOINT ["python", "-m", "streamlit"]
CMD ["run", "/app/app.py", "--server.address=0.0.0.0", "--server.port=8501", "--server.headless=true"]
