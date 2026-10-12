import 'package:flutter/material.dart';
import '../services/input_validator.dart';
import '../theme/app_theme.dart';
import '../widgets/ambient_background.dart';
import 'actions_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});
  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _controller = TextEditingController();
  bool _rtl = false;
  String? _error;
  static bool _containsArabic(String text) =>
      RegExp(r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF]').hasMatch(text);
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _continue() {
    final text = _controller.text.trim();
    if (text.length < 20 || text.length > 300) {
      setState(() => _error = 'Write between 20 and 300 characters.');
      return;
    }
    final validation = InputValidator.validate(text);
    if (!validation.isValid) {
      setState(() => _error = validation.reason);
      return;
    }
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => ActionsScreen(dreamText: text)));
  }

  @override
  Widget build(BuildContext context) => AmbientBackground(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.accent.withAlpha(22),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.accent.withAlpha(32),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: const Icon(Icons.nightlight_round, color: AppTheme.rose),
              ),
              const SizedBox(height: 18),
              Text('What is your dream?', style: AppTheme.titleMedium(context)),
              const SizedBox(height: 8),
              Text(
                'Give it enough detail to make it yours.',
                style: AppTheme.bodySmall(context),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Directionality(
                  textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                  child: TextField(
                    controller: _controller,
                    maxLength: 300,
                    minLines: 5,
                    maxLines: 8,
                    onChanged: (v) => setState(() {
                      _rtl = _containsArabic(v);
                      _error = null;
                    }),
                    textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
                    decoration: InputDecoration(
                      hintText: _rtl
                          ? 'اكتب حلمك هنا…'
                          : 'I want to become a nurse and work in my community…',
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
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppTheme.accent),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
