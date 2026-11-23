import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PushPreferenceTile extends StatefulWidget {
  const PushPreferenceTile({super.key});
  @override
  State<PushPreferenceTile> createState() => _PushPreferenceTileState();
}

class _PushPreferenceTileState extends State<PushPreferenceTile> {
  static const _channel = MethodChannel('chang.thai/controls');
  bool _available = false;
  bool _enabled = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) _load();
  }

  Future<void> _load() async {
    try {
      final available = await _channel.invokeMethod<bool>(
        'notificationsAvailable',
      );
      if (available != true) return;
      final enabled = await _channel.invokeMethod<bool>('notificationsEnabled');
      if (!mounted) return;
      setState(() {
        _available = true;
        _enabled = enabled == true;
      });
    } on MissingPluginException {
      // Android test environments may not expose the channel.
    } on PlatformException {
      // Startup remains usable without a push provider.
    }
  }

  Future<void> _change(bool enabled) async {
    setState(() => _busy = true);
    try {
      final current = await _channel.invokeMethod<bool>(
        'setNotificationsEnabled',
        enabled,
      );
      if (mounted) setState(() => _enabled = current == true);
    } on PlatformException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Notification ဆက်တင် မပြောင်းနိုင်သေးပါ။ ပြန်စမ်းပါ။',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => !_available
      ? const SizedBox.shrink()
      : SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Chang Thai ကြေညာချက်များ'),
          value: _enabled,
          onChanged: _busy ? null : _change,
        );
}
