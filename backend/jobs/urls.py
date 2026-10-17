from django.urls import path
from .views import JobDetailView, JobListView, JobStatusUpdateView, LoginView

urlpatterns = [
    # Auth endpoints
    path('auth/login/', LoginView.as_view(), name='auth-login'),
    # Job endpoints
    path('jobs/', JobListView.as_view(), name='job-list'),
    path('jobs/<int:pk>/', JobDetailView.as_view(), name='job-detail'),
    path('jobs/<int:pk>/status/', JobStatusUpdateView.as_view(), name='job-status-update'),
]
