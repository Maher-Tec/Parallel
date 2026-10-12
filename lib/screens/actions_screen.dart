import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import 'pause_screen.dart';

class ActionsScreen extends StatefulWidget {
  final String dreamText;
  const ActionsScreen({super.key, required this.dreamText});
  @override
  State<ActionsScreen> createState() => _ActionsScreenState();
}

class _ActionsScreenState extends State<ActionsScreen> {
  final _controllers = List.generate(3, (_) => TextEditingController());
  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<String> get _actions => _controllers
      .map((c) => c.text.trim())
      .where((v) => v.isNotEmpty)
      .toList();
  void _suggest() {
    final dream = widget.dreamText.toLowerCase();
    final suggestions = dream.contains('book') || dream.contains('write')
        ? [
            'Set aside 20 minutes to write this week',
            'Draft one page and ask someone for feedback',
            'Choose a realistic weekly writing time',
          ]
        : dream.contains('run') || dream.contains('fitness')
        ? [
            'Take a 20-minute walk or easy run this week',
            'Prepare comfortable clothes the night before',
            'Choose two days for movement and add them to your calendar',
          ]
        : [
            'Spend 20 minutes researching one practical first step',
            'Ask someone with experience one specific question',
            'Choose a day and time to begin a small first task',
          ];
    for (var i = 0; i < 3; i++) {
      _controllers[i].text = suggestions[i];
    }
    setState(() {});
  }

  void _continue() {
    final actions = _actions;
    if (actions.length < 2 || actions.length > 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add two or three actions.')),
      );
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PauseScreen(
          dreamText: widget.dreamText,
          actions: actions,
          isRtl: RegExp(
            r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]',
          ).hasMatch(widget.dreamText),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AmbientBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - 48,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What will you do?',
                      style: AppTheme.titleMedium(context),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Choose two or three specific steps. You can edit any suggestion.',
                      style: AppTheme.bodySmall(context),
                    ),
                    const SizedBox(height: 20),
                    ...List.generate(
                      3,
                      (i) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: TextField(
                          controller: _controllers[i],
                          minLines: 1,
                          maxLines: 2,
                          decoration: InputDecoration(
                            labelText: 'Action ${i + 1}',
                            filled: true,
                            fillColor: AppTheme.surface,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _suggest,
                      icon: const Icon(Icons.lightbulb_outline),
                      label: const Text('Suggest actions'),
                    ),
                    const Spacer(),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _continue,
                        child: const Text('Build my scenario'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
