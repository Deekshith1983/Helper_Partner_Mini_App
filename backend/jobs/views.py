from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.exceptions import NotFound, ValidationError
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.views import APIView

from .models import Job
from .serializers import (
    JobSerializer,
    JobStatusUpdateSerializer,
    LoginSerializer,
    UserSummarySerializer,
)


class LoginView(APIView):
    """
    POST /api/auth/login/
    Authenticates a helper and returns a DRF auth token and user summary.
    Public endpoint.
    """
    permission_classes = [AllowAny]

    def post(self, request):
        serializer = LoginSerializer(data=request.data)
        if not serializer.is_valid():
            # If authentication failed, detail is populated; otherwise return first validation error in detail
            errors = serializer.errors
            if 'detail' in errors:
                return Response({'detail': errors['detail']}, status=status.HTTP_401_UNAUTHORIZED)
            if 'non_field_errors' in errors:
                return Response({'detail': errors['non_field_errors'][0]}, status=status.HTTP_400_BAD_REQUEST)
            # Generic first error formatting for clean detail message
            first_key = next(iter(errors))
            first_val = errors[first_key]
            err_msg = first_val[0] if isinstance(first_val, list) else str(first_val)
            return Response({'detail': f"{first_key}: {err_msg}"}, status=status.HTTP_400_BAD_REQUEST)

        user = serializer.validated_data['user']
        token, _ = Token.objects.get_or_create(user=user)
        user_data = UserSummarySerializer(user).data

        return Response(
            {
                'token': token.key,
                'user': user_data,
            },
            status=status.HTTP_200_OK,
        )


class JobListView(APIView):
    """
    GET /api/jobs/
    Lists ONLY the jobs assigned to the authenticated helper.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request):
        jobs = Job.objects.filter(helper=request.user)
        serializer = JobSerializer(jobs, many=True)
        return Response(serializer.data, status=status.HTTP_200_OK)


class JobDetailView(APIView):
    """
    GET /api/jobs/<int:pk>/
    Retrieves full details of a job.
    Enforces helper ownership: if the job does not exist OR belongs to another
    helper, a 404 is returned with {"detail": "Job not found."}.
    """
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        try:
            # Query scoped to current user to enforce ownership and prevent ID enumeration
            job = Job.objects.get(pk=pk, helper=request.user)
        except Job.DoesNotExist:
            raise NotFound(detail="Job not found.")

        serializer = JobSerializer(job)
        return Response(serializer.data, status=status.HTTP_200_OK)


class JobStatusUpdateView(APIView):
    """
    PATCH /api/jobs/<int:pk>/status/
    Updates the lifecycle status of an assigned job.
    Enforces helper ownership (404 if not found or belongs to another helper).
    Stage 1 accepts any valid JobStatus value.
    """
    permission_classes = [IsAuthenticated]

    def patch(self, request, pk):
        try:
            job = Job.objects.get(pk=pk, helper=request.user)
        except Job.DoesNotExist:
            raise NotFound(detail="Job not found.")

        serializer = JobStatusUpdateSerializer(data=request.data)
        if not serializer.is_valid():
            # Format validation error cleanly as detail
            first_key = next(iter(serializer.errors))
            first_val = serializer.errors[first_key]
            err_msg = first_val[0] if isinstance(first_val, list) else str(first_val)
            return Response({'detail': f"{first_key}: {err_msg}"}, status=status.HTTP_400_BAD_REQUEST)

        new_status = serializer.validated_data['status']
        job.status = new_status
        job.save()

        return Response(JobSerializer(job).data, status=status.HTTP_200_OK)
