from datetime import timedelta
from django.contrib.auth.models import User
from django.core.management.base import BaseCommand
from django.utils import timezone
from rest_framework.authtoken.models import Token

from jobs.models import Job, JobStatus


class Command(BaseCommand):
    help = 'Seeds demo helpers and mock jobs into the database idempotently.'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE('Starting demo database seed...'))

        # Seed Helper 1
        helper1, created1 = User.objects.get_or_create(
            username='helper1',
            defaults={
                'first_name': 'Ramesh',
                'last_name': 'Kumar',
                'email': 'ramesh.helper1@example.com',
            },
        )
        helper1.set_password('Demo@1234')
        helper1.save()
        token1, _ = Token.objects.get_or_create(user=helper1)
        self.stdout.write(f"Helper 1 ready: {helper1.username} (Token: {token1.key})")

        # Seed Helper 2
        helper2, created2 = User.objects.get_or_create(
            username='helper2',
            defaults={
                'first_name': 'Suresh',
                'last_name': 'Patel',
                'email': 'suresh.helper2@example.com',
            },
        )
        helper2.set_password('Demo@1234')
        helper2.save()
        token2, _ = Token.objects.get_or_create(user=helper2)
        self.stdout.write(f"Helper 2 ready: {helper2.username} (Token: {token2.key})")

        now = timezone.now()

        # Helper 1 mock jobs (5 jobs: 2 ASSIGNED, 2 IN_PROGRESS, 1 COMPLETED)
        helper1_jobs = [
            {
                'title': 'Deep Cleaning - 2 BHK Apartment',
                'description': 'Full deep cleaning of 2 bedrooms, hall, kitchen, and 2 bathrooms. Equipment provided on site.',
                'customer_name': 'Pooja Sharma',
                'location': 'Flat 402, Green Glen Layout, Bellandur, Bengaluru',
                'scheduled_at': now + timedelta(hours=2),
                'status': JobStatus.ASSIGNED,
            },
            {
                'title': 'Sofa Shampooing & Stain Removal',
                'description': '5-seater fabric L-shape sofa shampooing and dry vacuuming. Customer requested pet stain treatment.',
                'customer_name': 'Arun Verma',
                'location': 'Villa 18, Palm Meadows, Whitefield, Bengaluru',
                'scheduled_at': now + timedelta(hours=5),
                'status': JobStatus.ASSIGNED,
            },
            {
                'title': 'Kitchen Chimney & Hob Degreasing',
                'description': 'Intensive degreasing and filter cleaning for Faber auto-clean chimney and 3-burner gas hob.',
                'customer_name': 'Deepa Nair',
                'location': 'Tower 3, Apt 1104, Prestige Shantiniketan, Bengaluru',
                'scheduled_at': now - timedelta(hours=1),
                'status': JobStatus.IN_PROGRESS,
            },
            {
                'title': 'Bathroom Floor Tile Scrubbing & Descaling',
                'description': 'Acid-free chemical descaling for master and guest bathrooms. Tap and sanitary fittings buffing.',
                'customer_name': 'Karthik Rao',
                'location': 'House 88, 12th Main, Indiranagar, Bengaluru',
                'scheduled_at': now - timedelta(hours=3),
                'status': JobStatus.IN_PROGRESS,
            },
            {
                'title': 'Balcony Wash & Pigeon Net Sanitization',
                'description': 'High-pressure wash for two balconies and bird droppings disinfection.',
                'customer_name': 'Sunita Menon',
                'location': 'Flat 204, Salarpuria Greenage, Bommanahalli, Bengaluru',
                'scheduled_at': now - timedelta(days=1),
                'status': JobStatus.COMPLETED,
            },
        ]

        # Helper 2 mock jobs (5 jobs: 2 ASSIGNED, 1 IN_PROGRESS, 2 COMPLETED)
        helper2_jobs = [
            {
                'title': 'Carpet Dry Cleaning & Dust Mite Treatment',
                'description': 'Large 9x12 Persian carpet shampooing and deodorization.',
                'customer_name': 'Vikram Malhotra',
                'location': 'Plot 45, Koramangala 4th Block, Bengaluru',
                'scheduled_at': now + timedelta(hours=3),
                'status': JobStatus.ASSIGNED,
            },
            {
                'title': 'Curtain & Upholstery Steam Pressing',
                'description': 'Steam sanitation and wrinkle removal for living room floor-length curtains.',
                'customer_name': 'Meera Sen',
                'location': 'B-301, Brigade Millennium, JP Nagar 7th Phase, Bengaluru',
                'scheduled_at': now + timedelta(hours=6),
                'status': JobStatus.ASSIGNED,
            },
            {
                'title': 'Move-In Pre-Occupancy Sanitization',
                'description': 'Sanitizing cabinets, wardrobes, kitchen counters before new tenant move-in.',
                'customer_name': 'Nikhil Reddy',
                'location': 'Row House 14, HSR Layout Sector 2, Bengaluru',
                'scheduled_at': now - timedelta(hours=2),
                'status': JobStatus.IN_PROGRESS,
            },
            {
                'title': 'Full Villa Glass Window Polishing',
                'description': 'Exterior and interior window pane cleaning with streak-free glass treatment.',
                'customer_name': 'Anita Desai',
                'location': 'Villa 7, Adarsh Palm Retreat, Outer Ring Road, Bengaluru',
                'scheduled_at': now - timedelta(days=1),
                'status': JobStatus.COMPLETED,
            },
            {
                'title': 'Refrigerator & Microwave Internal Detailing',
                'description': 'Food-grade sanitizing spray clean for double door fridge and convection microwave.',
                'customer_name': 'Rohan Mukherjee',
                'location': 'Flat 602, Sobha Iris, Marathahalli, Bengaluru',
                'scheduled_at': now - timedelta(days=2),
                'status': JobStatus.COMPLETED,
            },
        ]

        # Idempotently seed or update helper 1 jobs
        for job_data in helper1_jobs:
            job, _ = Job.objects.update_or_create(
                helper=helper1,
                title=job_data['title'],
                defaults=job_data,
            )

        # Idempotently seed or update helper 2 jobs
        for job_data in helper2_jobs:
            job, _ = Job.objects.update_or_create(
                helper=helper2,
                title=job_data['title'],
                defaults=job_data,
            )

        h1_count = Job.objects.filter(helper=helper1).count()
        h2_count = Job.objects.filter(helper=helper2).count()
        self.stdout.write(
            self.style.SUCCESS(
                f'Successfully seeded demo data: helper1 has {h1_count} jobs, helper2 has {h2_count} jobs.'
            )
        )
