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
    def test_login_success_returns_token(self, api_client, helper1):
        """Valid credentials return auth token and user profile."""
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
        """Invalid credentials return HTTP 401 with detail message."""
        response = api_client.post(
            '/api/auth/login/',
            {'username': 'helper1', 'password': 'WrongPassword'},
            format='json',
        )
        assert response.status_code == status.HTTP_401_UNAUTHORIZED
        assert 'detail' in response.json()

    def test_login_missing_fields(self, api_client):
        """Missing required fields return HTTP 400 with detail message."""
        response = api_client.post(
            '/api/auth/login/',
            {'username': 'helper1'},
            format='json',
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert 'detail' in response.json()


@pytest.mark.django_db
class TestJobsAPI:
    def test_list_unauthenticated_rejected(self, api_client):
        """Unauthenticated GET /api/jobs/ returns 401."""
        response = api_client.get('/api/jobs/')
        assert response.status_code == status.HTTP_401_UNAUTHORIZED

    def test_list_returns_only_own_jobs(self, api_client, helper1, job_helper1, job_helper2):
        """Helper only sees jobs assigned to them, never other helpers' jobs."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.get('/api/jobs/')

        assert response.status_code == status.HTTP_200_OK
        jobs = response.json()
        assert len(jobs) == 1
        assert jobs[0]['id'] == job_helper1.id
        assert jobs[0]['helper'] == helper1.id
        assert jobs[0]['title'] == 'Deep Cleaning - 2 BHK'

    def test_get_own_job_detail_succeeds(self, api_client, helper1, job_helper1):
        """Helper can view full details of their own assigned job."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.get(f'/api/jobs/{job_helper1.id}/')

        assert response.status_code == status.HTTP_200_OK
        data = response.json()
        assert data['id'] == job_helper1.id
        assert data['customer_name'] == 'Pooja Sharma'
        assert data['status'] == JobStatus.ASSIGNED

    def test_cannot_get_another_helper_job(self, api_client, helper1, job_helper2):
        """Accessing another helper's job returns 404 (ownership enforced)."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.get(f'/api/jobs/{job_helper2.id}/')

        assert response.status_code == status.HTTP_404_NOT_FOUND
        assert response.json()['detail'] == 'Job not found.'

    def test_get_nonexistent_job_returns_404(self, api_client, helper1):
        """Accessing non-existent job ID returns 404."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.get('/api/jobs/99999/')

        assert response.status_code == status.HTTP_404_NOT_FOUND
        assert response.json()['detail'] == 'Job not found.'

    def test_cannot_patch_another_helper_job(self, api_client, helper1, job_helper2):
        """Attempting to update another helper's job returns 404."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper2.id}/status/',
            {'status': JobStatus.IN_PROGRESS},
            format='json',
        )
        assert response.status_code == status.HTTP_404_NOT_FOUND
        assert response.json()['detail'] == 'Job not found.'


@pytest.mark.django_db
class TestStatusTransitions:
    def test_lifecycle_in_order_succeeds(self, api_client, helper1, job_helper1):
        """Valid transition sequence: ASSIGNED -> IN_PROGRESS -> COMPLETED."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')

        # Step 1: ASSIGNED -> IN_PROGRESS
        res1 = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {'status': JobStatus.IN_PROGRESS},
            format='json',
        )
        assert res1.status_code == status.HTTP_200_OK
        assert res1.json()['status'] == JobStatus.IN_PROGRESS
        job_helper1.refresh_from_db()
        assert job_helper1.status == JobStatus.IN_PROGRESS

        # Step 2: IN_PROGRESS -> COMPLETED
        res2 = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {'status': JobStatus.COMPLETED},
            format='json',
        )
        assert res2.status_code == status.HTTP_200_OK
        assert res2.json()['status'] == JobStatus.COMPLETED
        job_helper1.refresh_from_db()
        assert job_helper1.status == JobStatus.COMPLETED

    def test_skip_transition_assigned_to_completed_rejected(self, api_client, helper1, job_helper1):
        """Skipping status (ASSIGNED -> COMPLETED) is rejected with 400."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {'status': JobStatus.COMPLETED},
            format='json',
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert 'Invalid status transition' in response.json()['detail']
        job_helper1.refresh_from_db()
        assert job_helper1.status == JobStatus.ASSIGNED

    def test_backward_transition_inprogress_to_assigned_rejected(self, api_client, helper1, job_helper1):
        """Moving backward (IN_PROGRESS -> ASSIGNED) is rejected with 400."""
        job_helper1.status = JobStatus.IN_PROGRESS
        job_helper1.save()

        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {'status': JobStatus.ASSIGNED},
            format='json',
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert 'Invalid status transition' in response.json()['detail']
        job_helper1.refresh_from_db()
        assert job_helper1.status == JobStatus.IN_PROGRESS

    def test_backward_transition_completed_to_inprogress_rejected(self, api_client, helper1, job_helper1):
        """Moving backward from terminal state (COMPLETED -> IN_PROGRESS) is rejected with 400."""
        job_helper1.status = JobStatus.COMPLETED
        job_helper1.save()

        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {'status': JobStatus.IN_PROGRESS},
            format='json',
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert 'Invalid status transition' in response.json()['detail']
        job_helper1.refresh_from_db()
        assert job_helper1.status == JobStatus.COMPLETED

    def test_same_status_transition_rejected(self, api_client, helper1, job_helper1):
        """Attempting transition to same status (ASSIGNED -> ASSIGNED) is rejected with 400."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {'status': JobStatus.ASSIGNED},
            format='json',
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert 'already in status' in response.json()['detail']

    def test_missing_status_field_rejected(self, api_client, helper1, job_helper1):
        """PATCH without 'status' field returns 400."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {},
            format='json',
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert response.json()['detail'] == "Field 'status' is required."

    def test_invalid_status_value_rejected(self, api_client, helper1, job_helper1):
        """PATCH with non-existent status choice returns 400 listing valid choices."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {'status': 'FOO'},
            format='json',
        )
        assert response.status_code == status.HTTP_400_BAD_REQUEST
        assert "Invalid status 'FOO'" in response.json()['detail']
        assert 'ASSIGNED' in response.json()['detail']

    def test_patch_changes_only_status_ignores_other_fields(self, api_client, helper1, job_helper1):
        """PATCH must only update 'status'; other fields in request body are ignored."""
        api_client.credentials(HTTP_AUTHORIZATION=f'Token {helper1.auth_token.key}')
        response = api_client.patch(
            f'/api/jobs/{job_helper1.id}/status/',
            {
                'status': JobStatus.IN_PROGRESS,
                'title': 'Hacked Title',
                'customer_name': 'Hacked Name',
                'location': 'Hacked Location',
            },
            format='json',
        )
        assert response.status_code == status.HTTP_200_OK
        job_helper1.refresh_from_db()
        assert job_helper1.status == JobStatus.IN_PROGRESS
        # Original title and customer remain unchanged
        assert job_helper1.title == 'Deep Cleaning - 2 BHK'
        assert job_helper1.customer_name == 'Pooja Sharma'
