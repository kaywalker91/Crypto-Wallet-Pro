import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/responsive.dart';
import '../../domain/entities/transaction_entity.dart';
import '../providers/history_provider.dart';
import '../widgets/transaction_tile.dart';

enum TransactionFilter { all, received, sent }

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  TransactionFilter _filter = TransactionFilter.all;

  @override
  Widget build(BuildContext context) {
    final historyState = ref.watch(historyNotifierProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: () {
              ref.read(historyNotifierProvider.notifier).refresh();
            },
          ),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0F0C29),
              Color(0xFF302B63),
              Color(0xFF24243E),
            ],
          ),
        ),
        child: SafeArea(
          child: historyState.when(
            data: (transactions) => _buildData(context, transactions),
            loading: () => _buildLoading(context),
            error: (error, stack) => _buildError(context, error),
          ),
        ),
      ),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.error),
            const SizedBox(height: 16),
            Text(
              'Failed to load history',
              style: AppTypography.textTheme.titleMedium?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.read(historyNotifierProvider.notifier).refresh(),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildData(BuildContext context, List<TransactionEntity> transactions) {
    final sorted = [...transactions]
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    final filtered = _applyFilter(sorted);
    final items = _buildItems(filtered);

    final receivedCount = transactions.where((t) => t.type == TransactionType.received).length;
    final sentCount = transactions.where((t) => t.type == TransactionType.sent).length;

    return Column(
      children: [
        SizedBox(height: kToolbarHeight + 8),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          child: _SummaryCard(
            total: transactions.length,
            received: receivedCount,
            sent: sentCount,
          ),
        ),
        SizedBox(height: context.sectionSpacing),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.horizontalPadding),
          child: _FilterBar(
            selected: _filter,
            totalCount: transactions.length,
            receivedCount: receivedCount,
            sentCount: sentCount,
            onChanged: (value) => setState(() => _filter = value),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: context.maxContentWidth),
              child: RefreshIndicator(
                onRefresh: () => ref.read(historyNotifierProvider.notifier).refresh(),
                color: AppColors.primary,
                backgroundColor: AppColors.surface,
                child: items.isEmpty
                    ? ListView(
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalPadding,
                          40,
                          context.horizontalPadding,
                          40,
                        ),
                        children: [
                          _EmptyState(
                            message: transactions.isEmpty
                                ? 'No transactions yet'
                                : 'No results for this filter',
                          ),
                        ],
                      )
                    : ListView.builder(
                        padding: EdgeInsets.fromLTRB(
                          context.horizontalPadding,
                          8,
                          context.horizontalPadding,
                          24,
                        ),
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          if (item.isHeader) {
                            return Padding(
                              padding: EdgeInsets.only(
                                top: index == 0 ? 0 : 12,
                                bottom: 4,
                              ),
                              child: _DateHeader(date: item.date!),
                            );
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TransactionTile(
                              transaction: item.transaction!,
                              onTap: () => _showTransactionDetails(context, item.transaction!),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<TransactionEntity> _applyFilter(List<TransactionEntity> transactions) {
    switch (_filter) {
      case TransactionFilter.all:
        return transactions;
      case TransactionFilter.received:
        return transactions.where((t) => t.type == TransactionType.received).toList();
      case TransactionFilter.sent:
        return transactions.where((t) => t.type == TransactionType.sent).toList();
    }
  }

  List<_HistoryListItem> _buildItems(List<TransactionEntity> transactions) {
    final items = <_HistoryListItem>[];
    DateTime? currentDay;

    for (final transaction in transactions) {
      final day = DateUtils.dateOnly(transaction.timestamp);
      if (currentDay == null || currentDay != day) {
        items.add(_HistoryListItem.header(day));
        currentDay = day;
      }
      items.add(_HistoryListItem.transaction(transaction));
    }

    return items;
  }

  void _showTransactionDetails(BuildContext context, TransactionEntity transaction) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: context.sheetMaxWidth),
          child: _TransactionDetailSheet(transaction: transaction),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final int total;
  final int received;
  final int sent;

  const _SummaryCard({
    required this.total,
    required this.received,
    required this.sent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          _SummaryStat(label: 'All', value: total.toString(), color: AppColors.textPrimary),
          const SizedBox(width: 12),
          _SummaryStat(label: 'Received', value: received.toString(), color: AppColors.success),
          const SizedBox(width: 12),
          _SummaryStat(label: 'Sent', value: sent.toString(), color: AppColors.error),
        ],
      ),
    );
  }
}

class _SummaryStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.textTheme.titleLarge?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final TransactionFilter selected;
  final int totalCount;
  final int receivedCount;
  final int sentCount;
  final ValueChanged<TransactionFilter> onChanged;

  const _FilterBar({
    required this.selected,
    required this.totalCount,
    required this.receivedCount,
    required this.sentCount,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _HistoryFilterChip(
          label: 'All',
          count: totalCount,
          isSelected: selected == TransactionFilter.all,
          onTap: () => onChanged(TransactionFilter.all),
        ),
        _HistoryFilterChip(
          label: 'Received',
          count: receivedCount,
          isSelected: selected == TransactionFilter.received,
          color: AppColors.success,
          onTap: () => onChanged(TransactionFilter.received),
        ),
        _HistoryFilterChip(
          label: 'Sent',
          count: sentCount,
          isSelected: selected == TransactionFilter.sent,
          color: AppColors.error,
          onTap: () => onChanged(TransactionFilter.sent),
        ),
      ],
    );
  }
}

class _HistoryFilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final Color? color;
  final VoidCallback onTap;

  const _HistoryFilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? chipColor.withAlpha(51) : AppColors.cardBackground,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? chipColor : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? chipColor : AppColors.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? chipColor.withAlpha(77) : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                count.toString(),
                style: TextStyle(
                  color: isSelected ? chipColor : AppColors.textTertiary,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final label = DateFormat.yMMMMd().format(date);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            style: AppTypography.textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.history, size: 64, color: AppColors.textSecondary),
        const SizedBox(height: 16),
        Text(
          message,
          style: AppTypography.textTheme.bodyLarge?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _TransactionDetailSheet extends StatelessWidget {
  final TransactionEntity transaction;

  const _TransactionDetailSheet({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isReceived = transaction.type == TransactionType.received;
    final color = isReceived ? AppColors.success : AppColors.error;
    final amount =
        '${isReceived ? '+' : '-'} ${transaction.value.toStringAsFixed(4)} ${transaction.asset}';
    final date = DateFormat.yMMMd().add_jm().format(transaction.timestamp);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            context.horizontalPadding,
            12,
            context.horizontalPadding,
            24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Text(
                    'Transaction Details',
                    style: AppTypography.textTheme.titleLarge,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DetailRow(label: 'Type', value: isReceived ? 'Received' : 'Sent'),
              _DetailRow(label: 'Amount', value: amount, valueColor: color),
              _DetailRow(label: 'Date', value: date),
              _DetailRow(label: 'From', value: transaction.from, canCopy: true),
              _DetailRow(label: 'To', value: transaction.to, canCopy: true),
              _DetailRow(label: 'Hash', value: transaction.hash, canCopy: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool canCopy;
  final Color? valueColor;

  const _DetailRow({
    required this.label,
    required this.value,
    this.canCopy = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.textTheme.bodySmall?.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  value,
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    color: valueColor ?? AppColors.textPrimary,
                  ),
                ),
              ),
              if (canCopy)
                IconButton(
                  icon: const Icon(Icons.copy, size: 18, color: AppColors.textSecondary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied to clipboard'),
                        backgroundColor: AppColors.surface,
                      ),
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryListItem {
  final DateTime? date;
  final TransactionEntity? transaction;

  const _HistoryListItem._({this.date, this.transaction});

  bool get isHeader => date != null;

  factory _HistoryListItem.header(DateTime date) => _HistoryListItem._(date: date);

  factory _HistoryListItem.transaction(TransactionEntity transaction) =>
      _HistoryListItem._(transaction: transaction);
}
