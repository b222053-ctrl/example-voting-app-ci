FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY app.py .

# Expose port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD python -c "import urllib.request; import sys; urllib.request.urlopen('http://localhost:5000/health', timeout=2); sys.exit(0)" || exit 1

# Start application
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
