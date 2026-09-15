from unittest.mock import patch

import pytest
from redis.exceptions import ConnectionError as RedisConnectionError
from sqlalchemy.exc import OperationalError


def test_ready_checks_both_dependencies(client, db_session):
    with patch('app.main.SessionLocal', db_session), patch('app.main.redis_client.ping', return_value=True) as ping:
        response = client.get('/ready')
    assert response.status_code == 200
    assert response.json() == {'status': 'ready'}
    ping.assert_called_once()


@pytest.mark.parametrize('result', [False, RedisConnectionError('private-host:6379')])
def test_ready_fails_when_redis_is_unavailable(client, db_session, result):
    options = {'side_effect': result} if isinstance(result, Exception) else {'return_value': result}
    with patch('app.main.SessionLocal', db_session), patch('app.main.redis_client.ping', **options):
        response = client.get('/ready')
        assert client.get('/health').status_code == 200
    assert response.status_code == 503
    assert 'private-host' not in response.text


def test_ready_fails_and_closes_session_when_database_is_unavailable(client):
    with patch('app.main.SessionLocal') as factory:
        factory.return_value.execute.side_effect = OperationalError('SELECT 1', {}, Exception('private-db'))
        response = client.get('/ready')
        factory.return_value.close.assert_called_once()
    assert response.status_code == 503
    assert 'private-db' not in response.text
