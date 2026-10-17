from django.conf import settings
from django.db import models


class JobStatus(models.TextChoices):
    """Available job lifecycle statuses."""
    ASSIGNED = 'ASSIGNED', 'Assigned'
    IN_PROGRESS = 'IN_PROGRESS', 'In Progress'
    COMPLETED = 'COMPLETED', 'Completed'


# Strict state machine: allowed transitions between job lifecycle statuses
ALLOWED_TRANSITIONS = {
    JobStatus.ASSIGNED: [JobStatus.IN_PROGRESS],
    JobStatus.IN_PROGRESS: [JobStatus.COMPLETED],
    JobStatus.COMPLETED: [],
}


class Job(models.Model):
    """
    Represents a service job assigned to a specific helper.
    """
    title = models.CharField(max_length=255)
    description = models.TextField(blank=True)
    customer_name = models.CharField(max_length=150)
    location = models.CharField(max_length=255)
    scheduled_at = models.DateTimeField()
    status = models.CharField(
        max_length=20,
        choices=JobStatus.choices,
        default=JobStatus.ASSIGNED,
    )
    helper = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name='jobs',
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['scheduled_at']

    def __str__(self):
        return f"{self.title} ({self.status}) - {self.helper.username}"
