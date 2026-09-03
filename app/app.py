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
otlp_endpoint = os.environ.get("OTEL_EXPORTER_OTLP_ENDPOINT", "http://3.250.99.232:4317")
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

INVENTORY = {
    "1": {"name": "Laptop", "price": 999.99},
    "2": {"name": "Smartphone", "price": 499.99},
    "3": {"name": "Headphones", "price": 149.99}
}

@app.route('/item/<item_id>')
def get_item(item_id):
    logger.info(f"Fetching item details for {item_id}")
    item = INVENTORY.get(item_id)
    if not item:
        logger.warning(f"Item {item_id} not found!")
        return jsonify(error="Item not found"), 404
    return jsonify(item=item), 200

@app.route('/cart', methods=['POST'])
def add_to_cart():
    logger.info("Adding item to cart")
    data = request.get_json()
    
    if not data or not data.get("item_id"):
        logger.error("Missing item_id in request payload")
        return jsonify(error="Bad Request: Missing item_id"), 400
        
    item_id = str(data.get("item_id"))
    item = INVENTORY.get(item_id)
    
    if not item:
        logger.warning(f"Cannot add non-existent item {item_id} to cart")
        return jsonify(error="Item not found"), 404
        
    logger.info(f"Successfully added {item['name']} to cart")
    return jsonify(message="Item added to cart successfully!", cart_total=item['price']), 201

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
