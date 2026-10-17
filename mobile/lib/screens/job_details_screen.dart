import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/api_client.dart';
import '../core/constants.dart';
import '../core/theme.dart';
import '../models/job.dart';
import '../models/job_status.dart';
import '../providers/jobs_provider.dart';
import '../widgets/error_banner.dart';
import '../widgets/status_chip.dart';
import '../widgets/status_stepper.dart';

class JobDetailsScreen extends StatefulWidget {
  final int jobId;

  const JobDetailsScreen({
    super.key,
    required this.jobId,
  });

  @override
  State<JobDetailsScreen> createState() => _JobDetailsScreenState();
}

class _JobDetailsScreenState extends State<JobDetailsScreen> {
  Job? _job;
  bool _isLoading = true;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchJob();
  }

  Future<void> _fetchJob() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final job = await context.read<JobsProvider>().fetchJobDetails(widget.jobId);
      if (mounted) {
        setState(() {
          _job = job;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.message;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load job details. Tap retry.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _confirmAndTransitionStatus() async {
    if (_job == null || _isUpdating) return;

    final currentStatus = _job!.status;
    final nextStatus = currentStatus.nextStatus;
    if (nextStatus == null) return;

    final actionLabel = currentStatus.nextActionLabel ?? 'Proceed';
    final dialogTitle = '$actionLabel?';
    final dialogMessage = currentStatus == JobStatus.assigned
        ? 'Are you ready to start working on this job?'
        : 'Are you sure you want to mark this job as completed?';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(dialogTitle),
        content: Text(dialogMessage),
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
              minimumSize: const Size(100, 42),
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      final updatedJob = await context.read<JobsProvider>().updateJobStatus(
            widget.jobId,
            nextStatus,
          );

      if (mounted) {
        setState(() {
          _job = updatedJob;
          _isUpdating = false;
        });

        // Show success snackbar
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Job moved to ${nextStatus.label}'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.message),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not update job status. Please try again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}, $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Job #${widget.jobId}'),
      ),
      body: _buildBody(),
      bottomNavigationBar: _job != null ? _buildStickyActionButton() : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
          child: ErrorBanner(
            message: _errorMessage!,
            onRetry: _fetchJob,
          ),
        ),
      );
    }

    if (_job == null) {
      return const Center(child: Text(AppStrings.jobNotFound));
    }

    final job = _job!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenHorizontalPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Block: Title + Status Chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  job.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    height: 1.25,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              StatusChip(status: job.status),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),

          // 2. Status Stepper
          StatusStepper(currentStatus: job.status),
          const SizedBox(height: AppSpacing.s16),

          // 3. Details Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.s16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Description', job.description.isNotEmpty ? job.description : 'No description provided.'),
                  const Divider(color: AppColors.outline, height: 24),
                  _buildInfoRow('Customer', job.customerName),
                  const Divider(color: AppColors.outline, height: 24),
                  _buildInfoRow('Location', job.location),
                  const Divider(color: AppColors.outline, height: 24),
                  _buildInfoRow('Scheduled Time', _formatDateTime(job.scheduledAt)),
                  const Divider(color: AppColors.outline, height: 24),
                  _buildInfoRow('Created At', _formatDateTime(job.createdAt)),
                  const Divider(color: AppColors.outline, height: 24),
                  _buildInfoRow('Job ID', '#${job.id}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80), // extra padding so sticky bar never obscures content
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColors.textPrimary,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildStickyActionButton() {
    final status = _job!.status;
    final nextLabel = status.nextActionLabel;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(
          top: BorderSide(color: AppColors.outline, width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: nextLabel != null
            ? ElevatedButton(
                onPressed: _isUpdating ? null : _confirmAndTransitionStatus,
                child: _isUpdating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(nextLabel),
              )
            : Container(
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.completedBg,
                  borderRadius: BorderRadius.circular(AppRadii.button),
                  border: Border.all(color: AppColors.completedText.withValues(alpha: 0.3)),
                ),
                alignment: Alignment.center,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.completedText,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      AppStrings.completedLabel,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.completedText,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
