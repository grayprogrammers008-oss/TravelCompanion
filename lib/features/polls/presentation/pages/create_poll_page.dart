import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/theme_access.dart';
import '../../../../core/theme/theme_extensions.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../trips/data/services/trip_notification_service.dart';
import '../../../trips/presentation/providers/trip_providers.dart';
import '../providers/poll_providers.dart';

class CreatePollPage extends ConsumerStatefulWidget {
  const CreatePollPage({super.key, required this.tripId});

  final String tripId;

  @override
  ConsumerState<CreatePollPage> createState() => _CreatePollPageState();
}

class _CreatePollPageState extends ConsumerState<CreatePollPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _optionControllers = <TextEditingController>[
    TextEditingController(),
    TextEditingController(),
  ];
  int _defaultIndex = 0;
  DateTime _deadline = DateTime.now().add(const Duration(days: 1));

  @override
  void dispose() {
    _questionController.dispose();
    for (final c in _optionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length >= 8) return;
    setState(() => _optionControllers.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_optionControllers.length <= 2) return;
    setState(() {
      _optionControllers.removeAt(i).dispose();
      if (_defaultIndex >= _optionControllers.length) {
        _defaultIndex = _optionControllers.length - 1;
      } else if (_defaultIndex > i) {
        _defaultIndex -= 1;
      }
    });
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_deadline),
    );
    if (time == null) return;
    setState(() {
      _deadline = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_deadline.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deadline must be in the future')),
      );
      return;
    }

    final labels = _optionControllers
        .map((c) => c.text.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (labels.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least two options')),
      );
      return;
    }
    final safeDefaultIndex =
        _defaultIndex.clamp(0, labels.length - 1).toInt();

    final controller = ref.read(pollControllerProvider.notifier);
    final pollId = await controller.createPoll(
      tripId: widget.tripId,
      question: _questionController.text.trim(),
      optionLabels: labels,
      defaultIndex: safeDefaultIndex,
      deadline: _deadline,
    );

    if (!mounted) return;

    if (pollId == null) {
      final err = ref.read(pollControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err ?? 'Could not create poll')),
      );
      return;
    }

    // Fire-and-forget notification to trip members.
    unawaited(_notifyMembers(pollId));

    Navigator.of(context).pop(pollId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Poll created')),
    );
  }

  Future<void> _notifyMembers(String pollId) async {
    try {
      final trip = await ref.read(tripProvider(widget.tripId).future);
      final userId = ref.read(authStateProvider).value ?? '';
      final user = await ref.read(currentUserProvider.future);
      final service = TripNotificationService(SupabaseClientWrapper.client);
      await service.notifyPollCreated(
        tripId: widget.tripId,
        tripName: trip.trip.name,
        pollId: pollId,
        question: _questionController.text.trim(),
        creatorId: userId,
        creatorName: user?.fullName ?? 'Organizer',
      );
    } catch (_) {
      // notifications are best-effort — never fail the poll create on this
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeData = context.appThemeData;
    final isLoading = ref.watch(pollControllerProvider).isLoading;
    final deadlineLabel = DateFormat('EEE, MMM d • h:mm a').format(_deadline);

    return Scaffold(
      backgroundColor: context.backgroundColor,
      appBar: AppBar(
        title: const Text('New Poll',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        backgroundColor: themeData.primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: BoxDecoration(gradient: themeData.primaryGradient),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          children: [
            Text('Question',
                style: context.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppTheme.spacingSm),
            TextFormField(
              controller: _questionController,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: 'Where should we go?',
                border: OutlineInputBorder(),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Add a question'
                  : null,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Row(
              children: [
                Text('Options',
                    style: context.titleSmall
                        .copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                Text(
                  'Star = default if someone doesn\'t vote',
                  style: context.bodySmall.copyWith(
                    color: context.textColor.withValues(alpha: 0.55),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingSm),
            ..._optionControllers.asMap().entries.map((entry) {
              final i = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Make default',
                      icon: Icon(
                        _defaultIndex == i ? Icons.star : Icons.star_border,
                        color: _defaultIndex == i
                            ? Colors.amber
                            : context.textColor.withValues(alpha: 0.5),
                      ),
                      onPressed: () => setState(() => _defaultIndex = i),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: controller,
                        maxLength: 100,
                        decoration: InputDecoration(
                          hintText: 'Option ${i + 1}',
                          border: const OutlineInputBorder(),
                          counterText: '',
                        ),
                        validator: (v) {
                          if (i < 2 && (v == null || v.trim().isEmpty)) {
                            return 'Required';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove',
                      icon: const Icon(Icons.close),
                      onPressed: _optionControllers.length <= 2
                          ? null
                          : () => _removeOption(i),
                    ),
                  ],
                ),
              );
            }),
            if (_optionControllers.length < 8)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _addOption,
                  icon: const Icon(Icons.add),
                  label: const Text('Add option'),
                ),
              ),
            const SizedBox(height: AppTheme.spacingLg),
            Text('Deadline',
                style:
                    context.titleSmall.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: AppTheme.spacingSm),
            InkWell(
              onTap: _pickDeadline,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  border: Border.all(
                    color: context.textColor.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.event,
                        color: themeData.primaryColor),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        deadlineLabel,
                        style: context.bodyLarge.copyWith(
                          color: context.textColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right,
                        color: context.textColor.withValues(alpha: 0.5)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              'Anyone who hasn\'t voted by then will be counted as voting for your default.',
              style: context.bodySmall.copyWith(
                color: context.textColor.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXl),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeData.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Start Poll',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

