import os
import time
import json
import logging
import random
import requests
from flask import Flask, jsonify, request, Response
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
from instrumentation import setup_telemetry, get_logger, REQUEST_COUNT, REQUEST_LATENCY

# ---------------------------------------------------------------------------
# 1. Initialization
# ---------------------------------------------------------------------------
app = Flask(__name__)
tracer = setup_telemetry(app)
logger = get_logger(__name__)

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
