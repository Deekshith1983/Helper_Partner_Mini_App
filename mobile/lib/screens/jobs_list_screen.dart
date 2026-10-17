import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../providers/auth_provider.dart';
import '../providers/jobs_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_banner.dart';
import '../widgets/job_card.dart';
import 'job_details_screen.dart';
import 'login_screen.dart';

class JobsListScreen extends StatefulWidget {
  const JobsListScreen({super.key});

  @override
  State<JobsListScreen> createState() => _JobsListScreenState();
}

class _JobsListScreenState extends State<JobsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadJobs();
    });
  }

  Future<void> _loadJobs() async {
    await context.read<JobsProvider>().fetchJobs();
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(AppStrings.logoutConfirmTitle),
        content: const Text(AppStrings.logoutConfirmMessage),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadii.card),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(AppStrings.confirmDialogCancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              minimumSize: const Size(80, 40),
            ),
            child: const Text(AppStrings.logout),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final helperName = auth.currentUser?.name ?? auth.currentUser?.username ?? 'Partner';

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.jobsListTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: AppStrings.refresh,
            onPressed: _loadJobs,
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            tooltip: AppStrings.logout,
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: Consumer<JobsProvider>(
        builder: (context, jobsProvider, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary & Greeting Strip
              _buildSummaryStrip(helperName, jobsProvider),

              // Main State Area
              Expanded(
                child: _buildBody(jobsProvider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSummaryStrip(String helperName, JobsProvider provider) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenHorizontalPadding,
        vertical: 12,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.outline, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hi, $helperName',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            provider.summaryText,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(JobsProvider provider) {
    // 1. Loading State
    if (provider.isLoading && provider.jobs.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    // 2. Error State
    if (provider.errorMessage != null && provider.jobs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
          child: ErrorBanner(
            message: provider.errorMessage!,
            onRetry: _loadJobs,
          ),
        ),
      );
    }

    // 3. Empty State
    if (provider.jobs.isEmpty) {
      return EmptyState(onRefresh: _loadJobs);
    }

    // 4. Success State with Pull-to-Refresh
    return RefreshIndicator(
      onRefresh: _loadJobs,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
        itemCount: provider.jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s12),
        itemBuilder: (context, index) {
          final job = provider.jobs[index];
          return JobCard(
            job: job,
            onTap: () async {
              // Returning from Details reloads list so statuses stay fresh
              final result = await Navigator.push<bool>(
                context,
                MaterialPageRoute(
                  builder: (_) => JobDetailsScreen(jobId: job.id),
                ),
              );
              if (result == true || mounted) {
                _loadJobs();
              }
            },
          );
        },
      ),
    );
  }
}
