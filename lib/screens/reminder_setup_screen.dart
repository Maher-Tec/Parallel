import 'package:flutter/material.dart';
import '../models/dream.dart';
import '../services/reminder_service.dart';
import '../storage/local_store.dart';
import '../theme/app_theme.dart';

class ReminderSetupScreen extends StatefulWidget {
  final Dream dream;
  const ReminderSetupScreen({super.key, required this.dream});
  @override
  State<ReminderSetupScreen> createState() => _ReminderSetupScreenState();
}

class _ReminderSetupScreenState extends State<ReminderSetupScreen> {
  late bool _enabled = widget.dream.reminder.enabled;
  late String _days = widget.dream.reminder.days;
  late int _weeklyDay =
      widget.dream.reminder.weeklyDay ?? widget.dream.createdAt.weekday;
  late TimeOfDay _time = _parseTime(widget.dream.reminder.time);
  final _store = LocalStore();
  static TimeOfDay _parseTime(String value) {
    final p = value.split(':');
    return TimeOfDay(
      hour: int.tryParse(p[0]) ?? 9,
      minute: p.length > 1 ? int.tryParse(p[1]) ?? 0 : 0,
    );
  }

  Future<void> _finish() async {
    final reminder = DreamReminder(
      enabled: _enabled,
      days: _days,
      weeklyDay: _weeklyDay,
      time:
          '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
    );
    final updated = widget.dream.copyWith(reminder: reminder);
    if (_enabled) {
      final allowed = await ReminderService.instance.requestPermission();
      if (!allowed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification permission is needed to send reminders.',
            ),
          ),
        );
        return;
      }
    } else {
      await ReminderService.instance.cancel(widget.dream.id);
    }
    await _store.saveDream(updated);
    await ReminderService.instance.schedule(updated);
    if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppTheme.background,
    appBar: AppBar(
      backgroundColor: AppTheme.background,
      title: const Text('Dream reminder'),
    ),
    body: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A small nudge, when it suits you.',
            style: AppTheme.titleSmall(context),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Remind me'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
          ),
          if (_enabled) ...[
            DropdownButtonFormField<String>(
              initialValue: _days,
              decoration: const InputDecoration(labelText: 'Days'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekdays', child: Text('Weekdays')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
              ],
              onChanged: (v) => setState(() => _days = v ?? 'daily'),
            ),
            if (_days == 'weekly')
              DropdownButtonFormField<int>(
                initialValue: _weeklyDay,
                decoration: const InputDecoration(labelText: 'Day of week'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Monday')),
                  DropdownMenuItem(value: 2, child: Text('Tuesday')),
                  DropdownMenuItem(value: 3, child: Text('Wednesday')),
                  DropdownMenuItem(value: 4, child: Text('Thursday')),
                  DropdownMenuItem(value: 5, child: Text('Friday')),
                  DropdownMenuItem(value: 6, child: Text('Saturday')),
                  DropdownMenuItem(value: 7, child: Text('Sunday')),
                ],
                onChanged: (v) => setState(() => _weeklyDay = v ?? _weeklyDay),
              ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Time'),
              trailing: TextButton(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _time,
                  );
                  if (picked != null) setState(() => _time = picked);
                },
                child: Text(_time.format(context)),
              ),
            ),
          ],
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _finish, child: const Text('Done')),
          ),
        ],
      ),
    ),
  );
}
