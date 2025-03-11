from flask import Flask, request
from prometheus_client import generate_latest, Counter

app = Flask(__name__)

REQUEST_COUNT = Counter('http_requests_total', 'Total number of HTTP requests', ['method', 'endpoint'])

@app.route('/')
def home():
    REQUEST_COUNT.labels(method=request.method, endpoint='/').inc()
    return "Welcome to my Python Flask Web Server. Navigate to /metrics to see the Prometheus metrics."

@app.route('/hello')
def hello():
    REQUEST_COUNT.labels(method=request.method, endpoint='/hello').inc()
    return "Hello World!"

@app.route('/metrics')
def metrics():
    return generate_latest(), 200, {'Content-Type': 'text/plain'}

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)