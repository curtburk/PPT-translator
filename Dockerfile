FROM python:3.12-slim

WORKDIR /app

# Install curl for healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends curl && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Application code
COPY server.py .
COPY templates/ templates/
COPY static/ static/

# Create runtime directories
RUN mkdir -p uploads output

EXPOSE 8092
CMD ["uvicorn", "server:app", "--host", "0.0.0.0", "--port", "8092", "--log-level", "info"]
