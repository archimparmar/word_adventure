import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../utils/theme.dart';
import '../services/audio_service.dart';
import '../services/notification_service.dart';
import '../utils/game_assets.dart';
import '../widgets/responsive_screen.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
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
    if (!mounted) return;
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
        title: Text(
          'CLEAR DATA?',
          style: AppTheme.worldTitle.copyWith(color: AppTheme.coral, fontSize: 18),
        ),
        content: Text(
          'Are you sure you want to erase all your progress? This cannot be undone.',
          style: AppTheme.body.copyWith(color: Colors.white, fontSize: 14),
        ),
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
    return Consumer<UserProvider>(
      builder: (context, user, child) {
        return ResponsiveScreen(
          backgroundAsset: GameAssets.profileBackground,
          hasBottomNav: false,
          blurBackground: true,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final w = constraints.maxWidth;
              final h = constraints.maxHeight;

              final isSmall = w < 340 || h < 500;

              return Column(
                children: [
                  // ── 1. HEADER BAR (BACK BUTTON & WOODEN ADVENTURER TITLE BANNER) ──
                  _buildHeader(context, isSmall),

                  SizedBox(height: isSmall ? 10 : 16),

                  // ── SCROLLABLE PROFILE CONTENT (EXPANDED PROPORTIONS) ──
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. PLAYER CHARACTER SECTION
                          _buildPlayerCard(user, isSmall),

                          SizedBox(height: isSmall ? 12 : 16),

                          // 2. ACHIEVEMENTS (PROMINENT GREEN ADVENTURE CARD)
                          _buildAchievementsButton(context, isSmall),

                          SizedBox(height: isSmall ? 14 : 20),

                          // 3. STATISTICS SECTION HEADER
                          _buildSectionHeader('STATISTICS', isSmall),

                          SizedBox(height: isSmall ? 8 : 10),

                          // 4. STATISTICS GRID (2 COLUMNS x 3 ROWS)
                          _buildStatsGrid(user, isSmall),

                          SizedBox(height: isSmall ? 14 : 20),

                          // 5. SETTINGS SECTION HEADER
                          _buildSectionHeader('SETTINGS', isSmall),

                          SizedBox(height: isSmall ? 8 : 10),

                          // 6. SETTINGS CARDS (INLINE TOGGLES & CLEAR PROGRESS DANGER CARD)
                          _buildInlineSettingsContent(isSmall),

                          SizedBox(height: isSmall ? 16 : 24),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ── 1. TOP HEADER WITH BACK BUTTON & WOODEN ADVENTURER TITLE BANNER ──────────
  Widget _buildHeader(BuildContext context, bool isSmall) {
    final btnSize = isSmall ? 36.0 : 42.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Back Button
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Image.asset(
            GameAssets.backButton,
            width: btnSize,
            height: btnSize,
            fit: BoxFit.contain,
          ),
        ),

        // Centered Wooden Title Banner (ADVENTURER)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: isSmall ? 20 : 28,
            vertical: isSmall ? 6 : 8,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFF3D2312).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFFFD21C),
              width: 2.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.45),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            'ADVENTURER',
            style: AppTheme.worldTitle.copyWith(
              fontSize: isSmall ? 15.0 : 18.0,
              letterSpacing: isSmall ? 1.5 : 2.5,
              color: const Color(0xFFFFD21C),
              shadows: const [
                Shadow(color: Colors.black87, blurRadius: 6, offset: Offset(0, 2)),
              ],
            ),
          ),
        ),

        // Balancing Spacer Box
        SizedBox(width: btnSize, height: btnSize),
      ],
    );
  }

  // ── 2. PLAYER CHARACTER CARD ───────────────────────────────────────────────
  Widget _buildPlayerCard(UserProvider user, bool isSmall) {
    final avatarSize = isSmall ? 68.0 : 84.0;
    final levelFontSize = isSmall ? 18.0 : 22.0;
    final xpFontSize = isSmall ? 12.0 : 14.0;

    int requiredXp =
        (100 * (user.userData.playerLevel * user.userData.playerLevel) * 0.5 + 100).toInt();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 16,
        vertical: isSmall ? 12 : 16,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1830).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFFFD21C),
          width: 1.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD21C).withValues(alpha: 0.15),
            blurRadius: 10,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar Image
          Image.asset(
            GameAssets.defaultAvatar,
            width: avatarSize,
            height: avatarSize,
            fit: BoxFit.contain,
          ),
          SizedBox(width: isSmall ? 12 : 16),

          // Player Level & XP Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'LEVEL ${user.userData.playerLevel}',
                  style: AppTheme.worldTitle.copyWith(
                    fontSize: levelFontSize,
                    color: AppTheme.gold,
                    letterSpacing: 1.2,
                    shadows: const [
                      Shadow(color: Colors.black87, blurRadius: 4, offset: Offset(0, 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 6),

                // XP Summary Row
                Row(
                  children: [
                    Image.asset(
                      GameAssets.xpGem,
                      width: isSmall ? 16 : 18,
                      height: isSmall ? 16 : 18,
                      fit: BoxFit.contain,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.star, color: AppTheme.gold, size: 16),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'XP: ${user.userData.xp} / $requiredXp',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTheme.smallSecondary.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: xpFontSize,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // XP Progress Bar
                Container(
                  height: isSmall ? 10 : 12,
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: AppTheme.gold.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: user.xpProgress,
                      backgroundColor: Colors.transparent,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppTheme.success),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 3. ACHIEVEMENTS BUTTON CARD ───────────────────────────────────────────
  Widget _buildAchievementsButton(BuildContext context, bool isSmall) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AchievementsScreen()),
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 16,
          vertical: isSmall ? 10 : 14,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0F1E13).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF5B7A42),
            width: 1.8,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              GameAssets.openedChest,
              width: isSmall ? 40 : 48,
              height: isSmall ? 40 : 48,
              fit: BoxFit.contain,
              errorBuilder: (c, e, s) =>
                  const Icon(Icons.emoji_events, color: Color(0xFFF2C14E), size: 32),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'ACHIEVEMENTS',
                    style: AppTheme.worldTitle.copyWith(
                      color: Colors.white,
                      fontSize: isSmall ? 13.5 : 15.5,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View your achievements and milestones',
                    style: TextStyle(
                      fontFamily: AppTheme.body.fontFamily,
                      color: Colors.white70,
                      fontSize: isSmall ? 10.5 : 12.0,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFF2C14E),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. WOODEN SECTION HEADER ──────────────────────────────────────────────
  Widget _buildSectionHeader(String title, bool isSmall) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 14 : 18,
          vertical: isSmall ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF38200E).withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF8B5A2B), width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 4, offset: Offset(0, 2)),
          ],
        ),
        child: Text(
          title,
          style: AppTheme.worldTitle.copyWith(
            color: const Color(0xFFF2C14E),
            fontSize: isSmall ? 12.0 : 13.5,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  // ── 5. STATISTICS GRID (2 COLUMNS x 2 ROWS) ───────────────────────────────
  Widget _buildStatsGrid(UserProvider user, bool isSmall) {
    final stats = [
      _StatItem('Bonus Words', '${user.userData.bonusWordsFound}', Icons.star_rounded, const Color(0xFFFFCA28)),
      _StatItem('Hard Words', '${user.userData.hardWordsFound}', Icons.landscape_rounded, const Color(0xFFB0BEC5)),
      _StatItem('Current Streak', '${user.userData.streak}', Icons.local_fire_department_rounded, const Color(0xFFFF7043)),
      _StatItem('Best Streak', '${user.userData.bestStreak}', Icons.emoji_events_rounded, const Color(0xFFFFD54F)),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _buildStatCard(stats[0], isSmall)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(stats[1], isSmall)),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _buildStatCard(stats[2], isSmall)),
            const SizedBox(width: 8),
            Expanded(child: _buildStatCard(stats[3], isSmall)),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(_StatItem item, bool isSmall) {
    return Container(
      height: isSmall ? 58 : 66,
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 10 : 14,
        vertical: isSmall ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E33).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF2C3E6B).withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(item.icon, color: item.iconColor, size: isSmall ? 24 : 30),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.value,
                  style: AppTheme.worldTitle.copyWith(
                    fontSize: isSmall ? 16.0 : 19.0,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: AppTheme.body.fontFamily,
                    color: Colors.white70,
                    fontSize: isSmall ? 10.0 : 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 6. SETTINGS CONTENT (INLINE TOGGLES & CLEAR PROGRESS DANGER CARD) ────
  Widget _buildInlineSettingsContent(bool isSmall) {
    return Column(
      children: [
        _buildToggleSetting(
          'Sound Effects',
          'Play amazing sound effects',
          Icons.volume_up_rounded,
          _soundEnabled,
          () => _toggleSetting('setting_sound', _soundEnabled),
          isSmall,
        ),
        const SizedBox(height: 8),
        _buildToggleSetting(
          'Music',
          'Background adventure music',
          Icons.music_note_rounded,
          _musicEnabled,
          () => _toggleSetting('setting_music', _musicEnabled),
          isSmall,
        ),
        const SizedBox(height: 8),
        _buildToggleSetting(
          'Notifications',
          'Get updates and reminders',
          Icons.notifications_rounded,
          _notificationsEnabled,
          () => _toggleSetting('setting_notifications', _notificationsEnabled),
          isSmall,
        ),
        const SizedBox(height: 8),
        _buildActionSetting(
          'Clear Progress',
          'Reset all game progress and statistics',
          Icons.delete_forever_rounded,
          _clearData,
          isSmall,
          isDanger: true,
        ),
      ],
    );
  }

  Widget _buildToggleSetting(
    String title,
    String subtitle,
    IconData icon,
    bool value,
    VoidCallback onToggle,
    bool isSmall,
  ) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 12 : 16,
        vertical: isSmall ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1E33).withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF2C3E6B).withValues(alpha: 0.8),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Colors.black38,
            blurRadius: 6,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3050),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.gold, size: isSmall ? 22 : 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTheme.body.copyWith(
                    color: Colors.white,
                    fontSize: isSmall ? 13.5 : 15.0,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: AppTheme.body.fontFamily,
                    color: Colors.white70,
                    fontSize: isSmall ? 10.5 : 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: isSmall ? 46 : 52,
              height: isSmall ? 26 : 28,
              decoration: BoxDecoration(
                color: value ? AppTheme.success : Colors.black45,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: value ? const Color(0xFF1B9954) : Colors.white24,
                  width: 1.5,
                ),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: Container(
                    width: isSmall ? 18 : 20,
                    height: isSmall ? 18 : 20,
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

  Widget _buildActionSetting(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
    bool isSmall, {
    bool isDanger = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 16,
          vertical: isSmall ? 10 : 12,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF3B181A).withValues(alpha: 0.90),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE74C3C).withValues(alpha: 0.8),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Colors.black38,
              blurRadius: 6,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF522023),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFFE74C3C), size: isSmall ? 22 : 26),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTheme.body.copyWith(
                      color: const Color(0xFFE74C3C),
                      fontSize: isSmall ? 13.5 : 15.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontFamily: AppTheme.body.fontFamily,
                      color: Colors.white70,
                      fontSize: isSmall ? 10.5 : 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFFE74C3C),
              size: 26,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  const _StatItem(this.label, this.value, this.icon, this.iconColor);
}
