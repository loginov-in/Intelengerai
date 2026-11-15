FROM python:3.12-slim AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Runtime image
FROM python:3.12-slim

LABEL maintainer="dev@example.com"
LABEL description="Fast deployment Dockerfile for CloudAI Panel Flask application"
LABEL version="1.0"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    PORT=5000 \
    FLASK_APP=app.py \
    WORKERS=1 \
    THREADS=8 \
    TIMEOUT=120

WORKDIR /app

# Create non-root user for security
RUN groupadd --gid 10001 app && \
    useradd --uid 10001 --gid 10001 --no-create-home --shell /bin/false app

# Copy virtual environment from builder stage
COPY --from=builder /opt/venv /opt/venv

# Copy application code, static files, and templates
COPY --chown=app:app . /app

# Create data directory
RUN mkdir -p /app/data && \
    chown -R app:app /app/data

# Switch to non-root user
USER 10001

EXPOSE 5000

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')" || exit 1

ENTRYPOINT ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT} --workers ${WORKERS} --threads ${THREADS} --timeout ${TIMEOUT} --access-logfile - app:app"]
