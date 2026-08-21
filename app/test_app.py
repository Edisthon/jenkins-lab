import pytest
from app import app

@pytest.fixture
def client():
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client

def test_home(client):
    response = client.get('/')
    assert response.status_code == 200
    assert response.json == {"message": "Hello from Flask CI/CD Pipeline!"}

def test_health(client):
    response = client.get('/health')
    assert response.status_code == 200
    assert response.json == {"status": "healthy"}

def test_hello_dynamic(client):
    response = client.get('/hello/Jenkins')
    assert response.status_code == 200
    assert response.json == {"message": "Hello Jenkins!"}
