import sys
import os
import pytest

# Add the parent directory to the path so we can import the app
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from web_server.web_server import app, REQUEST_COUNT


@pytest.fixture
def client():
    # Create a test client using Flask's built-in testing tools
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home_endpoint(client):
    response = client.get('/')
    assert response.status_code == 200
    assert b"Welcome to my Python Flask Web Server. Navigate to /metrics to see the Prometheus metrics." in response.data

def test_hello_endpoint(client):
    response = client.get('/hello')
    assert response.status_code == 200
    assert b"Hello World!" in response.data

def test_metrics_endpoint(client):
    # Call the /metrics endpoint
    response = client.get('/metrics')
    assert response.status_code == 200
    assert b"http_requests_total" in response.data

def test_request_counter(client):
    # Reset the counter for testing
    REQUEST_COUNT._metrics.clear()

    # Make some requests
    client.get('/')
    client.get('/hello')
    client.get('/hello')

    # Verify that the counter has been incremented correctly
    metrics = REQUEST_COUNT.collect()
    for metric in metrics:
        for sample in metric.samples:
            if sample.name == "http_requests_total" and sample.labels == {"method": "GET", "endpoint": "/hello"}:
                assert sample.value == 2