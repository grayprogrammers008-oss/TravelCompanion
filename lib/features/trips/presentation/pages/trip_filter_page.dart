import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class TripFilterPage extends StatefulWidget {
  final double? initialMinBudget;
  final double? initialMaxBudget;
  final DateTime? initialCreatedAfter;
  final DateTime? initialCreatedBefore;

  const TripFilterPage({
    super.key,
    this.initialMinBudget,
    this.initialMaxBudget,
    this.initialCreatedAfter,
    this.initialCreatedBefore,
  });

  @override
  State<TripFilterPage> createState() => _TripFilterPageState();
}

class _TripFilterPageState extends State<TripFilterPage> {
  late TextEditingController _minBudgetController;
  late TextEditingController _maxBudgetController;
  DateTime? _createdAfter;
  DateTime? _createdBefore;

  @override
  void initState() {
    super.initState();
    _minBudgetController = TextEditingController(
      text: widget.initialMinBudget?.toStringAsFixed(0) ?? '',
    );
    _maxBudgetController = TextEditingController(
      text: widget.initialMaxBudget?.toStringAsFixed(0) ?? '',
    );
    _createdAfter = widget.initialCreatedAfter;
    _createdBefore = widget.initialCreatedBefore;
  }

  @override
  void dispose() {
    _minBudgetController.dispose();
    _maxBudgetController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    final filters = {
      'minBudget': _minBudgetController.text.isNotEmpty
          ? double.tryParse(_minBudgetController.text)
          : null,
      'maxBudget': _maxBudgetController.text.isNotEmpty
          ? double.tryParse(_maxBudgetController.text)
          : null,
      'createdAfter': _createdAfter,
      'createdBefore': _createdBefore,
    };
    context.pop(filters);
  }

  void _clearAllFilters() {
    final clearedFilters = {
      'minBudget': null,
      'maxBudget': null,
      'createdAfter': null,
      'createdBefore': null,
    };
    context.pop(clearedFilters);
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilters = widget.initialMinBudget != null ||
        widget.initialMaxBudget != null ||
        widget.initialCreatedAfter != null ||
        widget.initialCreatedBefore != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Filter Trips'),
        actions: [
          if (hasActiveFilters)
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text(
                'Clear All',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget Filter Section
            Row(
              children: [
                const Icon(Icons.attach_money, size: 20, color: AppTheme.success),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  'Budget Range',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Min Budget',
                      hintText: '0',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: TextField(
                    controller: _maxBudgetController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Budget',
                      hintText: '100000',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingMd,
                        vertical: AppTheme.spacingSm,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXl),

            // Date Created Filter Section
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: AppTheme.info),
                const SizedBox(width: AppTheme.spacingXs),
                Text(
                  'Date Created',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _createdAfter ?? DateTime.now(),
                        firstDate: DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _createdAfter = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingMd,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.neutral300),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 18),
                          const SizedBox(width: AppTheme.spacingXs),
                          Expanded(
                            child: Text(
                              _createdAfter != null
                                  ? '${_createdAfter!.day.toString().padLeft(2, '0')}/${_createdAfter!.month.toString().padLeft(2, '0')}/${_createdAfter!.year}'
                                  : 'From Date',
                              style: TextStyle(
                                color: _createdAfter != null
                                    ? AppTheme.neutral900
                                    : AppTheme.neutral500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          if (_createdAfter != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _createdAfter = null;
                                });
                              },
                              child: const Icon(
                                Icons.clear,
                                size: 16,
                                color: AppTheme.neutral600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _createdBefore ?? DateTime.now(),
                        firstDate: _createdAfter ?? DateTime(2020),
                        lastDate: DateTime.now(),
                      );
                      if (date != null) {
                        setState(() {
                          _createdBefore = date;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: AppTheme.spacingMd,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppTheme.neutral300),
                        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, size: 18),
                          const SizedBox(width: AppTheme.spacingXs),
                          Expanded(
                            child: Text(
                              _createdBefore != null
                                  ? '${_createdBefore!.day.toString().padLeft(2, '0')}/${_createdBefore!.month.toString().padLeft(2, '0')}/${_createdBefore!.year}'
                                  : 'To Date',
                              style: TextStyle(
                                color: _createdBefore != null
                                    ? AppTheme.neutral900
                                    : AppTheme.neutral500,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                            ),
                          ),
                          if (_createdBefore != null)
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _createdBefore = null;
                                });
                              },
                              child: const Icon(
                                Icons.clear,
                                size: 16,
                                color: AppTheme.neutral600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppTheme.spacingXl),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingLg),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingMd),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                ),
              ),
              child: const Text(
                'Apply Filters',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
