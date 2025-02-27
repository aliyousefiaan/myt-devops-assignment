import os
from flask import Flask, jsonify, request
import prometheus_client

app = Flask(__name__)

# Define Prometheus metrics
REQUEST_COUNT = prometheus_client.Counter(
    "flask_app_requests_total",
    "Total number of requests",
    ["method", "endpoint", "http_status"]
)
REQUEST_LATENCY = prometheus_client.Histogram(
    "flask_app_request_duration_seconds",
    "Histogram of request processing time",
    ["method", "endpoint"]
)

# Default route
@app.route("/")
def home():
    # Increment request count for this endpoint
    REQUEST_COUNT.labels(method=request.method, endpoint="/", http_status=200).inc()
    # Measure request processing time
    with REQUEST_LATENCY.labels(method=request.method, endpoint="/").time():
        return "Hello, this is a message from your Python app!"

# New route that uses secrets and configuration from environment variables
@app.route("/config")
def config():
    # Increment request count for this endpoint
    REQUEST_COUNT.labels(method=request.method, endpoint="/config", http_status=200).inc()
    # Measure request processing time
    with REQUEST_LATENCY.labels(method=request.method, endpoint="/config").time():
        # Retrieve sensitive and config values from environment variables
        secret_key = os.getenv("SECRET_KEY")
        db_password = os.getenv("DB_PASSWORD")

        # Retrieve non-sensitive config values from environment variables
        api_base_url = os.getenv("API_BASE_URL")
        log_level = os.getenv("LOG_LEVEL")
        max_connections = os.getenv("MAX_CONNECTIONS")

        # Return the config information
        return jsonify({
            "message": "Config and secrets accessed",
            "SECRET_KEY": secret_key,
            "DB_PASSWORD": db_password,
            "API_BASE_URL": api_base_url,
            "LOG_LEVEL": log_level,
            "MAX_CONNECTIONS": max_connections
        })

# Prometheus metrics endpoint
@app.route("/metrics")
def metrics():
    """Exposes Prometheus metrics."""
    return prometheus_client.generate_latest(), 200, {
        "Content-Type": prometheus_client.CONTENT_TYPE_LATEST
    }

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
