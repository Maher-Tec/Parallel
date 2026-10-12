import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/dream.dart';
import '../services/reminder_service.dart';
import '../storage/local_store.dart';
import '../theme/app_theme.dart';
import '../widgets/dream_map_painter.dart';
import 'input_screen.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with SingleTickerProviderStateMixin {
  final _store = LocalStore();
  List<Dream> _dreams = [];
  int _selectedDreamIndex = 0;
  bool _isLoading = true;

  // Available serene background assets
  static const List<Map<String, String>> _realms = [
    {'name': 'Serene Twilight', 'asset': 'assets/serene_dream_bg.jpg'},
    {'name': 'Stepping Stones', 'asset': 'assets/simple_path_bg.jpg'},
    {'name': 'Floating Islands', 'asset': 'assets/dream_path_map.png'},
  ];
  int _activeRealmIndex = 0;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final PageController _pageController = PageController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final dreams = await _store.getDreams();
    if (!mounted) return;
    setState(() {
      _dreams = dreams;
      _isLoading = false;
      if (_selectedDreamIndex >= _dreams.length) {
        _selectedDreamIndex = (_dreams.length - 1).clamp(0, _dreams.length);
      }
    });
  }

  Future<void> _toggleStage(Dream dream, int stageIndex, bool isDone) async {
    final updatedActions = [...dream.actions];
    updatedActions[stageIndex] = updatedActions[stageIndex].copyWith(done: isDone);
    final updatedDream = dream.copyWith(actions: updatedActions);

    await _store.saveDream(updatedDream);
    await ReminderService.instance.refresh(updatedDream);
    await _load();
  }

  Future<void> _deleteDream(Dream dream) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF191B28),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppTheme.accent.withAlpha(60)),
        ),
        title: Text(
          'Delete Dream?',
          style: AppTheme.titleSmall(ctx).copyWith(color: AppTheme.textPrimary),
        ),
        content: Text(
          'Are you sure you want to remove "${dream.title}"? Your journey will be lost.',
          style: AppTheme.bodySmall(ctx).copyWith(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD34545),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _store.deleteDream(dream.id);
      await ReminderService.instance.cancel(dream.id);
      await _load();
    }
  }

  Future<void> _editReminder(Dream dream) async {
    var enabled = dream.reminder.enabled;
    var days = dream.reminder.days;
    var weeklyDay = dream.reminder.weeklyDay ?? dream.createdAt.weekday;
    final initial = dream.reminder.time.split(':');
    var time = TimeOfDay(
      hour: int.tryParse(initial[0]) ?? 9,
      minute: int.tryParse(initial.last) ?? 0,
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF141624),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  const Icon(Icons.notifications_active_outlined, color: AppTheme.accent),
                  const SizedBox(width: 10),
                  Text('Dream Reminder', style: AppTheme.titleSmall(context)),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeThumbColor: AppTheme.accent,
                activeTrackColor: AppTheme.accent.withAlpha(90),
                title: const Text('Enable Reminders', style: TextStyle(color: Colors.white)),
                subtitle: const Text('Stay gently anchored to your next step', style: TextStyle(color: Colors.white54, fontSize: 12)),
                value: enabled,
                onChanged: (v) => setModal(() => enabled = v),
              ),
              const Divider(color: Colors.white12),
              if (enabled) ...[
                const SizedBox(height: 8),
                Text('Frequency', style: AppTheme.bodySmall(context).copyWith(color: AppTheme.accent)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2235),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      dropdownColor: const Color(0xFF1F2235),
                      value: days,
                      items: const [
                        DropdownMenuItem(value: 'daily', child: Text('Every Day', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'weekdays', child: Text('Weekdays (Mon - Fri)', style: TextStyle(color: Colors.white))),
                        DropdownMenuItem(value: 'weekly', child: Text('Once a Week', style: TextStyle(color: Colors.white))),
                      ],
                      onChanged: (v) => setModal(() => days = v ?? 'daily'),
                    ),
                  ),
                ),
                if (days == 'weekly') ...[
                  const SizedBox(height: 12),
                  Text('On Day', style: AppTheme.bodySmall(context).copyWith(color: AppTheme.accent)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1F2235),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1F2235),
                        value: weeklyDay,
                        items: const [
                          DropdownMenuItem(value: 1, child: Text('Monday', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 2, child: Text('Tuesday', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 3, child: Text('Wednesday', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 4, child: Text('Thursday', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 5, child: Text('Friday', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 6, child: Text('Saturday', style: TextStyle(color: Colors.white))),
                          DropdownMenuItem(value: 7, child: Text('Sunday', style: TextStyle(color: Colors.white))),
                        ],
                        onChanged: (v) => setModal(() => weeklyDay = v ?? weeklyDay),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Time of Day', style: AppTheme.bodySmall(context).copyWith(color: AppTheme.accent)),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.textPrimary,
                        side: const BorderSide(color: AppTheme.accent),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () async {
                        final p = await showTimePicker(
                          context: context,
                          initialTime: time,
                        );
                        if (p != null) setModal(() => time = p);
                      },
                      icon: const Icon(Icons.access_time, size: 18),
                      label: Text(time.format(context)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.accent,
                    foregroundColor: const Color(0xFF151824),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () async {
                    final updated = dream.copyWith(
                      reminder: DreamReminder(
                        enabled: enabled,
                        days: days,
                        weeklyDay: weeklyDay,
                        time:
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                      ),
                    );
                    if (enabled) {
                      final allowed = await ReminderService.instance.requestPermission();
                      if (!allowed) return;
                    }
                    await _store.saveDream(updated);
                    await ReminderService.instance.refresh(updated);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                    await _load();
                  },
                  child: const Text('Save Reminder', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDreamDetailsModal(Dream dream) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF131524),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (ctx) {
        final completed = dream.actions.where((a) => a.done).length;
        final total = dream.actions.length;
        final pct = total == 0 ? 0 : ((completed / total) * 100).round();

        return DraggableScrollableSheet(
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          expand: false,
          builder: (context, scrollController) => ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 32),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DREAM ODYSSEY',
                          style: TextStyle(
                            color: AppTheme.accent.withAlpha(200),
                            fontSize: 11,
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          dream.title,
                          style: AppTheme.titleMedium(context).copyWith(fontSize: 22),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.accent.withAlpha(35),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppTheme.accent.withAlpha(80)),
                    ),
                    child: Text(
                      '$pct% Summit',
                      style: const TextStyle(
                        color: AppTheme.accent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Parallel Realities
              if (dream.scenarioDo.isNotEmpty || dream.scenarioNot.isNotEmpty) ...[
                const Text(
                  'PARALLEL VISIONS',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                if (dream.scenarioDo.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF13281E).withAlpha(180),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFF48A870).withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.auto_awesome, color: Color(0xFF67CF8F), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'When you achieve this dream:',
                              style: TextStyle(
                                color: Color(0xFF67CF8F),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dream.scenarioDo,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                if (dream.scenarioNot.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF28161D).withAlpha(180),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFB84860).withAlpha(80)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.hourglass_empty, color: Color(0xFFE26B7E), size: 16),
                            SizedBox(width: 8),
                            Text(
                              'If you postpone this journey:',
                              style: TextStyle(
                                color: Color(0xFFE26B7E),
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          dream.scenarioNot,
                          style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
              ],
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.accent,
                        side: BorderSide(color: AppTheme.accent.withAlpha(120)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editReminder(dream);
                      },
                      icon: const Icon(Icons.notifications_outlined, size: 18),
                      label: Text(
                        dream.reminder.enabled ? 'Reminder: ${dream.reminder.time}' : 'Set Reminder',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withAlpha(40),
                      foregroundColor: Colors.redAccent,
                      padding: const EdgeInsets.all(12),
                    ),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _deleteDream(dream);
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isRtl(String text) =>
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withAlpha(80),
                    AppTheme.accent.withAlpha(15),
                    Colors.transparent,
                  ],
                ),
              ),
              child: const Icon(
                Icons.explore_outlined,
                size: 44,
                color: AppTheme.accent,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Dreams Yet',
              style: AppTheme.titleMedium(context).copyWith(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              'Every extraordinary odyssey starts with a single step. Map your vision and watch your mountain path illuminate.',
              style: AppTheme.bodyMedium(context).copyWith(
                color: Colors.white60,
                fontSize: 14,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.accent,
                foregroundColor: const Color(0xFF141724),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              ),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InputScreen()),
                );
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Begin a New Dream', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a unified, interactive milestone station widget on the winding path
  Widget _buildStationCard({
    required int index,
    required DreamAction action,
    required bool isNext,
    required double width,
    required VoidCallback onTap,
  }) {
    final isDone = action.done;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = isNext ? _pulseController.value : 0.0;

        return ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onTap,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 260),
                  width: width,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: isDone
                        ? const Color(0xFF132219).withAlpha(225)
                        : isNext
                            ? const Color(0xFF262013).withAlpha(235)
                            : const Color(0xFF111424).withAlpha(210),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFF56C47E).withAlpha(180)
                          : isNext
                              ? const Color(0xFFFFC65C).withAlpha((180 + pulse * 75).round())
                              : Colors.white.withAlpha(45),
                      width: isNext ? 1.8 : 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDone
                            ? const Color(0xFF388E52).withAlpha(40)
                            : isNext
                                ? const Color(0xFFFFB83E).withAlpha((60 + pulse * 90).round())
                                : Colors.black.withAlpha(90),
                        blurRadius: isNext ? (14 + pulse * 10) : 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // 1. Station Medallion Node
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isDone
                              ? const Color(0xFF56C47E)
                              : isNext
                                  ? AppTheme.accent
                                  : Colors.white.withAlpha(16),
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFF8CEAB0)
                                : isNext
                                    ? const Color(0xFFFFE8A8)
                                    : Colors.white30,
                            width: 1.5,
                          ),
                          boxShadow: isDone || isNext
                              ? [
                                  BoxShadow(
                                    color: isDone
                                        ? const Color(0xFF56C47E).withAlpha(140)
                                        : AppTheme.accent.withAlpha(140),
                                    blurRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Center(
                          child: isDone
                              ? const Icon(
                                  Icons.check_rounded,
                                  color: Color(0xFF0F1A12),
                                  size: 20,
                                )
                              : Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    color: isNext ? const Color(0xFF18150B) : Colors.white70,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // 2. Step Text & Subtitle
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'STAGE ${index + 1}',
                                  style: TextStyle(
                                    color: isDone
                                        ? const Color(0xFF72E09B)
                                        : isNext
                                            ? const Color(0xFFFFDF94)
                                            : Colors.white54,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.3,
                                  ),
                                ),
                                if (isNext) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFC65C),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        color: Color(0xFF1A1608),
                                        fontSize: 7,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            Directionality(
                              textDirection: _isRtl(action.text) ? TextDirection.rtl : TextDirection.ltr,
                              child: Text(
                                action.text,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: isDone ? Colors.white60 : Colors.white,
                                  fontSize: 13,
                                  fontWeight: isNext ? FontWeight.w600 : FontWeight.w400,
                                  height: 1.25,
                                  decoration: isDone ? TextDecoration.lineThrough : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // 3. Status Action Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDone
                              ? const Color(0xFF1C3624)
                              : isNext
                                  ? AppTheme.accent.withAlpha(45)
                                  : Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isDone
                                ? const Color(0xFF56C47E).withAlpha(100)
                                : isNext
                                    ? AppTheme.accent.withAlpha(120)
                                    : Colors.white12,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isDone ? 'Done' : isNext ? 'Complete' : 'Pending',
                              style: TextStyle(
                                color: isDone
                                    ? const Color(0xFF72E09B)
                                    : isNext
                                        ? const Color(0xFFFFE092)
                                        : Colors.white38,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(
                              isDone
                                  ? Icons.check_circle_rounded
                                  : isNext
                                      ? Icons.arrow_forward_rounded
                                      : Icons.radio_button_unchecked,
                              size: 13,
                              color: isDone
                                  ? const Color(0xFF72E09B)
                                  : isNext
                                      ? const Color(0xFFFFE092)
                                      : Colors.white38,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Builds the glorious Summit flag station at the peak of the mountain
  Widget _buildSummitStation({
    required bool isAllDone,
    required int totalStages,
    required int completedCount,
    required double width,
    required VoidCallback onTap,
  }) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final pulse = _pulseController.value;

        return ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: onTap,
                child: Container(
                  width: width,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: isAllDone
                        ? const Color(0xFF2C2210).withAlpha(235)
                        : const Color(0xFF101322).withAlpha(210),
                    border: Border.all(
                      color: isAllDone
                          ? const Color(0xFFFFD575).withAlpha((190 + pulse * 65).round())
                          : Colors.white.withAlpha(60),
                      width: isAllDone ? 1.8 : 1.0,
                    ),
                    boxShadow: isAllDone
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFFB83E).withAlpha((100 + pulse * 90).round()),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 10,
                            ),
                          ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isAllDone
                              ? const Color(0xFFFFC65C)
                              : Colors.white.withAlpha(15),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.flag_rounded,
                            color: isAllDone ? const Color(0xFF1C1608) : Colors.white70,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isAllDone ? '★ SUMMIT CONQUERED ★' : 'DREAM SUMMIT',
                              style: TextStyle(
                                color: isAllDone ? const Color(0xFFFFE3A3) : Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isAllDone
                                  ? 'All milestones reached!'
                                  : '${totalStages - completedCount} milestones to summit',
                              style: TextStyle(
                                color: isAllDone ? const Color(0xFFFFD575) : Colors.white54,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isAllDone ? Icons.stars_rounded : Icons.lock_outline_rounded,
                        color: isAllDone ? const Color(0xFFFFD575) : Colors.white38,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDreamCard(BuildContext context, Dream dream) {
    final completed = dream.actions.where((action) => action.done).length;
    final total = dream.actions.length;
    final progress = total == 0 ? 0.0 : (completed / total).clamp(0.0, 1.0);
    final next = dream.nextStep;
    final isSummitReached = total > 0 && completed >= total;

    final currentRealm = _realms[_activeRealmIndex % _realms.length];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        // Journey vertical layout:
        // Top header ends around y = 115
        // Bottom dock begins around y = height - 70
        const yTop = 120.0;
        final yBottom = height - 80.0;
        final availableHeight = yBottom - yTop;

        // Station card width centered on screen
        final cardWidth = (width - 40.0).clamp(260.0, 360.0);
        final stationX = width / 2;

        // Compute Y positions of stations:
        // Summit is at top
        final summitY = yTop + 24.0;
        final summitPoint = Offset(stationX, summitY);
        final startPoint = Offset(stationX, yBottom);

        final List<Offset> stationPoints = [];
        final stationCount = dream.actions.length;

        if (stationCount == 1) {
          stationPoints.add(Offset(stationX, yTop + availableHeight * 0.55));
        } else if (stationCount == 2) {
          stationPoints.add(Offset(stationX, yTop + availableHeight * 0.78)); // Stage 1
          stationPoints.add(Offset(stationX, yTop + availableHeight * 0.44)); // Stage 2
        } else {
          // 3 or more stages
          stationPoints.add(Offset(stationX, yTop + availableHeight * 0.82)); // Stage 1
          stationPoints.add(Offset(stationX, yTop + availableHeight * 0.56)); // Stage 2
          stationPoints.add(Offset(stationX, yTop + availableHeight * 0.30)); // Stage 3
        }

        return Container(
          width: width,
          height: height,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isSummitReached
                  ? const Color(0xFFFFD575).withAlpha(160)
                  : AppTheme.accent.withAlpha(75),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: isSummitReached
                    ? const Color(0xFFFFB83E).withAlpha(60)
                    : AppTheme.accent.withAlpha(25),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // 1. Serene Night Landscape Background
              Image.asset(
                currentRealm['asset']!,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),

              // 2. Dynamic Winding Path Custom Painter
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) => CustomPaint(
                  painter: DreamMapPainter(
                    stationPoints: stationPoints,
                    summitPoint: summitPoint,
                    startPoint: startPoint,
                    completedCount: completed,
                    pulse: _pulseController.value,
                    drawLandscape: false,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),

              // 3. Cinematic Atmospheric Vignette
              const IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xD90E111F),
                        Color(0x440E111F),
                        Color(0x000E111F),
                        Color(0x350E111F),
                        Color(0xEE0E111F),
                      ],
                      stops: [0.0, 0.18, 0.45, 0.80, 1.0],
                    ),
                  ),
                ),
              ),

              // 4. Header Bar: Dream Title & Progress
              Positioned(
                top: 16,
                left: 18,
                right: 18,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.accent.withAlpha(35),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppTheme.accent.withAlpha(70)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.auto_awesome, color: AppTheme.accent, size: 12),
                              const SizedBox(width: 5),
                              Text(
                                'PATH TO YOUR DREAM',
                                style: TextStyle(
                                  color: const Color(0xFFFFE092),
                                  fontSize: 9.5,
                                  letterSpacing: 1.6,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Realm switcher button
                        InkWell(
                          onTap: () {
                            setState(() {
                              _activeRealmIndex = (_activeRealmIndex + 1) % _realms.length;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black45,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.palette_outlined, color: Colors.white70, size: 13),
                                const SizedBox(width: 4),
                                Text(
                                  currentRealm['name']!,
                                  style: const TextStyle(color: Colors.white70, fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Directionality(
                      textDirection: _isRtl(dream.title) ? TextDirection.rtl : TextDirection.ltr,
                      child: Text(
                        dream.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.titleMedium(context).copyWith(
                          fontSize: 21,
                          height: 1.25,
                          shadows: const [
                            Shadow(color: Colors.black, blurRadius: 14),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress bar
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 6,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0, end: progress),
                              duration: const Duration(milliseconds: 700),
                              curve: Curves.easeOutCubic,
                              builder: (context, val, _) => Align(
                                alignment: Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: val,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(6),
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFFFFEEB5), Color(0xFFFFB83E)],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.accent.withAlpha(150),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          isSummitReached
                              ? 'Summit Achieved!'
                              : '$completed of $total stages',
                          style: TextStyle(
                            color: isSummitReached ? const Color(0xFFFFD575) : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSummitReached ? FontWeight.bold : FontWeight.w500,
                            shadows: const [
                              Shadow(color: Colors.black, blurRadius: 8),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 5. Summit Milestone Station
              Positioned(
                left: stationX - cardWidth / 2,
                top: summitY - 24.0,
                child: _buildSummitStation(
                  isAllDone: isSummitReached,
                  totalStages: total,
                  completedCount: completed,
                  width: cardWidth,
                  onTap: () => _showDreamDetailsModal(dream),
                ),
              ),

              // 6. Interactive Milestone Stations along the Path
              ...dream.actions.asMap().entries.map((entry) {
                final index = entry.key;
                final action = entry.value;
                final isNext = !action.done && action.text == next;
                final pt = stationPoints[index.clamp(0, stationPoints.length - 1)];

                return Positioned(
                  left: pt.dx - cardWidth / 2,
                  top: pt.dy - 28.0,
                  child: _buildStationCard(
                    index: index,
                    action: action,
                    isNext: isNext,
                    width: cardWidth,
                    onTap: () => _toggleStage(dream, index, !action.done),
                  ),
                );
              }),

              // 7. Interactive Bottom Glass Drawer Dock
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF101322).withAlpha(225),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: AppTheme.accent.withAlpha(90),
                          width: 1.2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(120),
                            blurRadius: 18,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Reminder button
                          TextButton.icon(
                            style: TextButton.styleFrom(
                              foregroundColor: dream.reminder.enabled
                                  ? const Color(0xFFFFD575)
                                  : Colors.white70,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            ),
                            onPressed: () => _editReminder(dream),
                            icon: Icon(
                              dream.reminder.enabled
                                  ? Icons.notifications_active_rounded
                                  : Icons.notifications_none_rounded,
                              size: 18,
                              color: dream.reminder.enabled
                                  ? const Color(0xFFFFD575)
                                  : Colors.white60,
                            ),
                            label: Text(
                              dream.reminder.enabled ? dream.reminder.time : 'Reminder',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                          const Spacer(),
                          // Open drawer / details
                          FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppTheme.accent.withAlpha(45),
                              foregroundColor: const Color(0xFFFFE092),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => _showDreamDetailsModal(dream),
                            icon: const Icon(Icons.menu_open_rounded, size: 16),
                            label: const Text(
                              'Steps & Vision',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 4),
                          // Delete icon
                          IconButton(
                            iconSize: 19,
                            color: Colors.white54,
                            tooltip: 'Delete Dream',
                            onPressed: () => _deleteDream(dream),
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        title: Text(
          'My Dreams',
          style: AppTheme.titleSmall(context).copyWith(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_dreams.isNotEmpty)
            IconButton(
              tooltip: 'New Dream',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const InputScreen()),
                );
                _load();
              },
              icon: const Icon(Icons.add_rounded, color: AppTheme.accent),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppTheme.accent))
          : _dreams.isEmpty
              ? _buildEmptyState()
              : SafeArea(
                  child: Column(
                    children: [
                      // If multiple dreams, display horizontal selector tabs
                      if (_dreams.length > 1) ...[
                        SizedBox(
                          height: 42,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _dreams.length,
                            separatorBuilder: (_, index) => const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              final d = _dreams[index];
                              final isSelected = index == _selectedDreamIndex;
                              final doneCount = d.actions.where((a) => a.done).length;

                              return ChoiceChip(
                                label: Text(
                                  '${d.title} ($doneCount/${d.actions.length})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isSelected ? const Color(0xFF141724) : Colors.white70,
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppTheme.accent,
                                backgroundColor: const Color(0xFF191C2C),
                                showCheckmark: false,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppTheme.accent
                                        : Colors.white.withAlpha(25),
                                  ),
                                ),
                                onSelected: (val) {
                                  if (val) {
                                    setState(() => _selectedDreamIndex = index);
                                    _pageController.animateToPage(
                                      index,
                                      duration: const Duration(milliseconds: 350),
                                      curve: Curves.easeInOut,
                                    );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],
                      // Dream Carousel / Viewport
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                          child: PageView.builder(
                            controller: _pageController,
                            itemCount: _dreams.length,
                            onPageChanged: (idx) {
                              setState(() => _selectedDreamIndex = idx);
                            },
                            itemBuilder: (context, index) {
                              return _buildDreamCard(context, _dreams[index]);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
