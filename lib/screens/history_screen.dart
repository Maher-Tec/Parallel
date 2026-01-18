import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/decision_entry.dart';
import '../storage/local_store.dart';
import 'result_screen.dart';

/// S4 — History Screen
/// Personal archive of past decisions
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final LocalStore _store = LocalStore();
  List<DecisionEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final entries = await _store.getHistory();
    if (mounted) {
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    }
  }

  void _openEntry(DecisionEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          decision: entry.decision,
          tone: entry.tone,
          resultIfAct: entry.resultIfAct,
          resultIfNot: entry.resultIfNot,
          existingEntry: entry,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textSecondary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'History',
          style: AppTheme.titleSmall(context),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.textSecondary),
                ),
              )
            : _entries.isEmpty
                ? _buildEmptyState()
                : _buildList(),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'No decisions yet.',
              style: AppTheme.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Your saved explorations will appear here.',
              style: AppTheme.bodySmall(context),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      itemCount: _entries.length,
      separatorBuilder: (_, __) => const Divider(
        color: AppTheme.divider,
        height: 1,
      ),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        return _HistoryItem(
          entry: entry,
          onTap: () => _openEntry(entry),
        );
      },
    );
  }
}

/// History item widget
class _HistoryItem extends StatelessWidget {
  final DecisionEntry entry;
  final VoidCallback onTap;

  const _HistoryItem({
    required this.entry,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.shortDecision,
              style: AppTheme.bodyMedium(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              '${entry.formattedDate} · ${entry.displayTone}',
              style: AppTheme.bodySmall(context),
            ),
          ],
        ),
      ),
    );
  }
}
