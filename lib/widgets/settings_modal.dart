import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../utils/game_assets.dart';

class SettingsModal extends StatefulWidget {
  const SettingsModal({super.key});

  @override
  State<SettingsModal> createState() => _SettingsModalState();
}

class _SettingsModalState extends State<SettingsModal> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _notificationsEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _soundEnabled = prefs.getBool('setting_sound') ?? true;
      _musicEnabled = prefs.getBool('setting_music') ?? true;
      _notificationsEnabled = prefs.getBool('setting_notifications') ?? true;
    });
  }

  Future<void> _toggleSetting(String key, bool currentValue) async {
    final prefs = await SharedPreferences.getInstance();
    bool newValue = !currentValue;
    await prefs.setBool(key, newValue);
    if (key == 'setting_sound') {
      AudioService().updateSettings(sound: newValue);
    } else if (key == 'setting_music') {
      AudioService().updateSettings(music: newValue);
    } else if (key == 'setting_notifications') {
      NotificationService().setNotificationsEnabled(newValue);
    }
    _loadSettings();
  }


  Future<void> _clearData() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF16251A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppTheme.coral, width: 2),
        ),
        title: Text('CLEAR DATA?', style: AppTheme.worldTitle.copyWith(color: AppTheme.coral, fontSize: 18)),
        content: Text('Are you sure you want to erase all your progress? This cannot be undone.', style: AppTheme.body.copyWith(color: Colors.white, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('CANCEL', style: AppTheme.smallSecondary.copyWith(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('ERASE', style: AppTheme.smallSecondary.copyWith(color: AppTheme.coral)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress erased. Please restart the game.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 420),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF16251A).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFFD9A62E).withValues(alpha: 0.65),
            width: 2.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Row with Back Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => Navigator.pop(context),
                  child: Image.asset(
                    GameAssets.backButton,
                    width: 44,
                    height: 44,
                    fit: BoxFit.contain,
                  ),
                ),
                Text(
                  'SETTINGS',
                  style: AppTheme.worldTitle.copyWith(fontSize: 18, letterSpacing: 2, color: AppTheme.gold),
                ),
                const SizedBox(width: 44),
              ],
            ),

            const SizedBox(height: 16),

            _buildSectionHeader('PREFERENCES'),
            const SizedBox(height: 10),
            _buildToggleSetting('Sound Effects', Icons.volume_up_rounded, _soundEnabled, () => _toggleSetting('setting_sound', _soundEnabled)),
            _buildToggleSetting('Music', Icons.music_note_rounded, _musicEnabled, () => _toggleSetting('setting_music', _musicEnabled)),
            _buildToggleSetting('Notifications', Icons.notifications_rounded, _notificationsEnabled, () => _toggleSetting('setting_notifications', _notificationsEnabled)),

            const SizedBox(height: 16),
            _buildSectionHeader('DANGER ZONE'),
            const SizedBox(height: 10),
            _buildActionSetting('Clear Progress', Icons.delete_forever_rounded, _clearData, isDanger: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: AppTheme.worldTitle.copyWith(color: const Color(0xFFF2C14E), fontSize: 13, letterSpacing: 1.5),
    );
  }

  Widget _buildToggleSetting(String label, IconData icon, bool value, VoidCallback onToggle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF203626).withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF5B7A42).withValues(alpha: 0.40)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.gold, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTheme.body.copyWith(color: Colors.white, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                color: value ? AppTheme.success : Colors.black45,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: value ? const Color(0xFF1B9954) : Colors.white24, width: 1.5),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionSetting(String label, IconData icon, VoidCallback onTap, {bool isDanger = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDanger ? AppTheme.coral.withValues(alpha: 0.15) : const Color(0xFF203626).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDanger ? AppTheme.coral.withValues(alpha: 0.5) : const Color(0xFF5B7A42).withValues(alpha: 0.40)),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDanger ? AppTheme.coral : AppTheme.gold, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTheme.body.copyWith(
                  color: isDanger ? AppTheme.coral : Colors.white,
                  fontSize: 13,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDanger ? AppTheme.coral : Colors.white54, size: 20),
          ],
        ),
      ),
    );
  }
}
