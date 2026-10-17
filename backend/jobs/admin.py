from django.contrib import admin
from .models import Job


@admin.register(Job)
class JobAdmin(admin.ModelAdmin):
    list_display = ('id', 'title', 'customer_name', 'status', 'helper', 'scheduled_at', 'created_at')
    list_filter = ('status', 'helper', 'scheduled_at')
    search_fields = ('title', 'customer_name', 'location', 'helper__username')
    ordering = ('scheduled_at',)
