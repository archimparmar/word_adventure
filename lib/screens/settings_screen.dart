import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/theme.dart';
import '../utils/game_assets.dart';
import '../widgets/responsive_screen.dart';
import '../widgets/game_button.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _soundEnabled = true;
  bool _musicEnabled = true;
  bool _notificationsEnabled = false;

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
      _notificationsEnabled = prefs.getBool('setting_notifications') ?? false;
    });
  }

  Future<void> _toggleSetting(String key, bool currentValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, !currentValue);
    _loadSettings();
  }

  Future<void> _clearData() async {
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.deepIndigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: const BorderSide(color: AppTheme.coral, width: 2)),
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
    return ResponsiveScreen(
      backgroundAsset: GameAssets.profileBackground,
      child: Column(
        children: [
          _buildAppBar(context),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSectionHeader('PREFERENCES'),
                  const SizedBox(height: 16),
                  _buildToggleSetting('Sound Effects', Icons.volume_up_rounded, _soundEnabled, () => _toggleSetting('setting_sound', _soundEnabled)),
                  _buildToggleSetting('Music', Icons.music_note_rounded, _musicEnabled, () => _toggleSetting('setting_music', _musicEnabled)),
                  _buildToggleSetting('Notifications', Icons.notifications_rounded, _notificationsEnabled, () => _toggleSetting('setting_notifications', _notificationsEnabled)),
                  
                  const SizedBox(height: 40),
                  _buildSectionHeader('SUPPORT'),
                  const SizedBox(height: 16),
                  _buildActionSetting('Privacy Policy', Icons.privacy_tip_rounded, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Privacy Policy...')));
                  }),
                  _buildActionSetting('Terms of Service', Icons.description_rounded, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Terms of Service...')));
                  }),
                  _buildActionSetting('Contact Us', Icons.mail_rounded, () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Opening Mail Client...')));
                  }),
                  
                  const SizedBox(height: 40),
                  _buildSectionHeader('DANGER ZONE'),
                  const SizedBox(height: 16),
                  _buildActionSetting('Clear Progress', Icons.delete_forever_rounded, _clearData, isDanger: true),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GameButton(
          width: 48,
          height: 48,
          isRounded: true,
          baseColor: AppTheme.deepIndigo.withValues(alpha: 0.8),
          shadowColor: Colors.black45,
          onPressed: () => Navigator.pop(context),
          child: Image.asset(GameAssets.backButton, width: 24, height: 24, color: Colors.white, errorBuilder: (c,e,s) => const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20)),
        ),
        Text(
          'SETTINGS',
          style: AppTheme.worldTitle.copyWith(fontSize: 18, letterSpacing: 1.5),
        ),
        const SizedBox(width: 48), // Balances the row
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Text(
        title,
        style: AppTheme.worldTitle.copyWith(color: AppTheme.gold, fontSize: 14, letterSpacing: 1.5),
      ),
    );
  }

  Widget _buildToggleSetting(String label, IconData icon, bool value, VoidCallback onToggle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.deepIndigo.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: AppTheme.body.copyWith(color: Colors.white, fontSize: 14),
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 56,
              height: 32,
              decoration: BoxDecoration(
                color: value ? AppTheme.success : Colors.black45,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: value ? const Color(0xFF1B9954) : Colors.white24, width: 2),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    width: 20,
                    height: 20,
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
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDanger ? AppTheme.coral.withValues(alpha: 0.1) : AppTheme.deepIndigo.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDanger ? AppTheme.coral.withValues(alpha: 0.5) : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, color: isDanger ? AppTheme.coral : Colors.white70, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: AppTheme.body.copyWith(
                  color: isDanger ? AppTheme.coral : Colors.white,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: isDanger ? AppTheme.coral : Colors.white54),
          ],
        ),
      ),
    );
  }
}
