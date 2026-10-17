from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from rest_framework import serializers
from .models import Job, JobStatus


class LoginSerializer(serializers.Serializer):
    """
    Validates username and password credentials.
    """
    username = serializers.CharField(required=True)
    password = serializers.CharField(required=True, write_only=True)

    def validate(self, attrs):
        username = attrs.get('username')
        password = attrs.get('password')

        if not username or not password:
            raise serializers.ValidationError('Must include "username" and "password".')

        user = authenticate(username=username, password=password)
        if not user:
            # Raising AuthenticationFailed will result in HTTP 401 in DRF
            from rest_framework.exceptions import AuthenticationFailed
            raise AuthenticationFailed('Invalid username or password.')

        if not user.is_active:
            from rest_framework.exceptions import AuthenticationFailed
            raise AuthenticationFailed('User account is disabled.')

        attrs['user'] = user
        return attrs


class UserSummarySerializer(serializers.ModelSerializer):
    """
    Brief user details returned on login.
    """
    name = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = ['id', 'username', 'name']

    def get_name(self, obj):
        full_name = obj.get_full_name()
        return full_name if full_name else obj.username


class JobSerializer(serializers.ModelSerializer):
    """
    Full representation of a Job.
    """
    helper = serializers.ReadOnlyField(source='helper.id')

    class Meta:
        model = Job
        fields = [
            'id',
            'title',
            'description',
            'customer_name',
            'location',
            'scheduled_at',
            'status',
            'helper',
            'created_at',
        ]
        read_only_fields = ['id', 'helper', 'created_at']


class JobStatusUpdateSerializer(serializers.Serializer):
    """
    Validates incoming status update payload.
    Stage 1 accepts any valid choice from JobStatus.
    """
    status = serializers.ChoiceField(choices=JobStatus.choices)
