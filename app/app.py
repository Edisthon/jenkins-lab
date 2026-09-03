import os
import time
import json
import logging
import random
import requests
from flask import Flask, jsonify, request, Response
from prometheus_client import Counter, Histogram, generate_latest, CONTENT_TYPE_LATEST

# ... (I need to be careful with replace_file_content if I don't know the exact lines, let me view app.py first)
from opentelemetry import trace
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter
from opentelemetry.sdk.resources import Resource
from opentelemetry.instrumentation.flask import FlaskInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor

# ---------------------------------------------------------------------------
# 1. OpenTelemetry Initialization
# ---------------------------------------------------------------------------
# Tell OTel to send traces to the Jaeger OTLP receiver
otlp_endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://3.254.59.76:4317")
resource = Resource.create({"service.name": "flask-ecommerce-api"})
provider = TracerProvider(resource=resource)
processor = BatchSpanProcessor(OTLPSpanExporter(endpoint=otlp_endpoint, insecure=True))
provider.add_span_processor(processor)
trace.set_tracer_provider(provider)

# ---------------------------------------------------------------------------
# 2. Custom JSON Logger (Injects trace_id)
# ---------------------------------------------------------------------------
class JsonFormatter(logging.Formatter):
    def format(self, record):
        span = trace.get_current_span()
        trace_id = trace.format_trace_id(span.get_span_context().trace_id) if span else "0"
        span_id = trace.format_span_id(span.get_span_context().span_id) if span else "0"
        
        log_obj = {
            "timestamp": self.formatTime(record, self.datefmt),
            "level": record.levelname,
            "message": record.getMessage(),
            "trace_id": trace_id,
            "span_id": span_id
        }
        return json.dumps(log_obj)

logger = logging.getLogger(__name__)
logger.setLevel(logging.INFO)
handler = logging.StreamHandler()
handler.setFormatter(JsonFormatter())
logger.addHandler(handler)

# Disable default flask logging so it doesn't double-print
logging.getLogger('werkzeug').disabled = True

# ---------------------------------------------------------------------------
# 3. Flask Initialization & Instrumentation
# ---------------------------------------------------------------------------
app = Flask(__name__)
FlaskInstrumentor().instrument_app(app)
RequestsInstrumentor().instrument()
tracer = trace.get_tracer(__name__)

# ---------------------------------------------------------------------------
# 4. Prometheus Metrics Definitions
# ---------------------------------------------------------------------------
REQUEST_COUNT = Counter(
    'http_requests_total', 
    'Total HTTP requests', 
    ['method', 'endpoint', 'http_status']
)

REQUEST_LATENCY = Histogram(
    'http_request_duration_seconds', 
    'HTTP request latency', 
    ['method', 'endpoint'],
    buckets=[0.1, 0.25, 0.5, 1.0, 2.0, 5.0]
)

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    req_time = time.time() - request.start_time
    REQUEST_COUNT.labels(request.method, request.path, response.status_code).inc()
    REQUEST_LATENCY.labels(request.method, request.path).observe(req_time)
    return response

@app.route('/metrics')
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

# ---------------------------------------------------------------------------
# 5. Application Routes (Mock E-Commerce)
# ---------------------------------------------------------------------------
@app.route('/')
def home():
    logger.info("Home page accessed")
    return jsonify(message="Welcome to the E-Commerce API!"), 200

@app.route('/health')
def health():
    return jsonify(status="healthy"), 200

@app.route('/checkout')
def checkout():
    logger.info("Starting checkout process")
    
    # Simulate processing delay
    time.sleep(0.5)
    
    # Simulate random 500 error (5% chance)
    if random.random() < 0.05:
        logger.error("Checkout failed! Database connection lost.")
        return jsonify(error="Internal Server Error"), 500
        
    logger.info("Checkout completed successfully")
    return jsonify(message="Order processed successfully!"), 200

@app.route('/search')
def search():
    query = request.args.get('q', 'default')
    logger.info(f"Searching for product: {query}")
    
    # Simulate an external HTTP call to a separate Inventory Microservice
    with tracer.start_as_current_span("inventory_api_call"):
        try:
            # httpbin delay simulates a slow external API
            res = requests.get("https://httpbin.org/delay/1", timeout=3)
            logger.info("Successfully fetched inventory from external API")
            return jsonify(results=[f"Result 1 for {query}", f"Result 2 for {query}"]), 200
        except Exception as e:
            logger.error(f"Failed to reach inventory API: {str(e)}")
            return jsonify(error="Inventory service unavailable"), 503

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)
