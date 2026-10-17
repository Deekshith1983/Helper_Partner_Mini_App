from datetime import timedelta
import pytest
from django.contrib.auth.models import User
from django.utils import timezone
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.test import APIClient

from jobs.models import Job, JobStatus


@pytest.fixture
def api_client():
    return APIClient()


@pytest.fixture
def helper1(db):
    user = User.objects.create_user(
        username='helper1',
        password='Demo@1234',
        first_name='Ramesh',
        last_name='Kumar',
    )
    Token.objects.create(user=user)
    return user


@pytest.fixture
def helper2(db):
    user = User.objects.create_user(
        username='helper2',
        password='Demo@1234',
        first_name='Suresh',
        last_name='Patel',
    )
    Token.objects.create(user=user)
    return user


@pytest.fixture
def job_helper1(db, helper1):
    return Job.objects.create(
        title='Deep Cleaning - 2 BHK',
        description='Cleaning test',
        customer_name='Pooja Sharma',
        location='Bellandur, Bangalore',
        scheduled_at=timezone.now() + timedelta(hours=2),
        status=JobStatus.ASSIGNED,
        helper=helper1,
    )


@pytest.fixture
def job_helper2(db, helper2):
    return Job.objects.create(
        title='Carpet Shampooing',
        description='Carpet test',
        customer_name='Vikram Malhotra',
        location='Koramangala, Bangalore',
        scheduled_at=timezone.now() + timedelta(hours=4),
        status=JobStatus.ASSIGNED,
        helper=helper2,
    )


@pytest.mark.django_db
class TestAuthAPI:
    def test_login_success(self, api_client, helper1):
        response = api_client.post(
            '/api/auth/login/',
            {'username': 'helper1', 'password': 'Demo@1234'},
            format='json',
        )
        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert 'token' in data
        assert data['token'] == helper1.auth_token.key
        assert data['user']['id'] == helper1.id
        assert data['user']['username'] == 'helper1'
        assert data['user']['name'] == 'Ramesh Kumar'

    def test_login_invalid_password(self, api_client, helper1):
        response = api_client.post(
            '/api/auth/login/',
            {'username': 'helper1', 'password': 'WrongPassword'},
            format='json',
        )
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert 'detail' in response.json()

    def test_login_missing_fields(self, api_client):
        response = api_client.post(
            '/api/auth/login/',
            {'username': 'helper1'},
            format='json',
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert 'detail' in response.json()


@pytest.mark.django_db
class TestJobsAPI:
    def test_list_jobs_unauthenticated(self, api_client):
        response = api_client.get('/api/jobs/')
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_jobs_only_own_jobs(self, api_client, helper1, job_helper1, job_helper2):
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.get('/api/jobs/')

        assert response.status_code == status.HTTP_200_OK
        jobs = response.json()
        assert len(jobs) == 1
        assert jobs[0]['id'] == job_helper1.id
        assert jobs[0]['helper'] == helper1.id
        assert jobs[0]['title'] == 'Deep Cleaning - 2 BHK'

    def test_get_job_detail_own_job(self, api_client, helper1, job_helper1):
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.get(f'/api/jobs/{job_helper1.id}/')

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data['id'] == job_helper1.id
        assert data['customer_name'] == 'Pooja Sharma'
        assert data['status'] == JobStatus.ASSIGNED

    def test_get_job_detail_other_helper_job_returns_404(self, api_client, helper1, job_helper2):
        # Ownership enforcement: accessing another helper's job returns 404
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.get(f'/api/jobs/{job_helper2.id}/')

        assert response.status_code == status.HTTP_404_NOT_FOUND
        assert response.json()['detail'] == 'Job not found.'

    def test_get_job_detail_nonexistent_returns_404(self, api_client, helper1):
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.get('/api/jobs/99999/')

        assert response.status_code == status.HTTP_404_NOT_FOUND
        assert response.json()['detail'] == 'Job not found.'

    def test_patch_job_status_success(self, api_client, helper1, job_helper1):
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {'status': JobStatus.IN_PROGRESS},
            format='json',
        )
        assert response.status_code == status.HTTP_200_OK
        assert response.json()['status'] == JobStatus.IN_PROGRESS

        job_helper1.refresh_from_db()
        assert job_helper1.status == JobStatus.IN_PROGRESS

    def test_patch_job_status_other_helper_job_returns_404(self, api_client, helper1, job_helper2):
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper2.id}/status/',
            {'status': JobStatus.IN_PROGRESS},
            format='json',
        )
        assert response.status_code == status.HTTP_404_NOT_FOUND

    def test_patch_job_status_invalid_value(self, api_client, helper1, job_helper1):
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {'status': 'UNKNOWN_STATUS'},
            format='json',
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert 'detail' in response.json()
