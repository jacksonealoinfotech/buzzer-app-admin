import 'package:buzzer_app_admin/features/dashboard/presenation/screen/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Shared bottom nav from the dashboard file (keep all files in the same folder)

// ======================================================================
// Models  (replace sample data with your API models later)
// ======================================================================

enum SettingsSection { general, notifications, security, api }

class SettingsEntry {
  const SettingsEntry({
    required this.section,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final SettingsSection section;
  final IconData icon;
  final String title;
  final String subtitle;
}

class AdminActivity {
  const AdminActivity({
    required this.name,
    required this.action,
    required this.timeAgo,
    this.avatar,
  });

  final String name;
  final String action;
  final String timeAgo; // already formatted, e.g. "2m ago"
  final ImageProvider? avatar;
}

const List<SettingsEntry> defaultSettingsEntries = [
  SettingsEntry(
    section: SettingsSection.general,
    icon: Icons.tune_rounded,
    title: 'General Settings',
    subtitle: 'App configuration & branding',
  ),
  SettingsEntry(
    section: SettingsSection.notifications,
    icon: Icons.notifications_none_rounded,
    title: 'Notification Settings',
    subtitle: 'Email & in-app notifications',
  ),
  SettingsEntry(
    section: SettingsSection.security,
    icon: Icons.shield_outlined,
    title: 'Security Settings',
    subtitle: 'MFA, session & access control',
  ),
  SettingsEntry(
    section: SettingsSection.api,
    icon: Icons.hub_outlined,
    title: 'API & Integrations',
    subtitle: 'Webhooks and external services',
  ),
];

const List<AdminActivity> sampleActivity = [
  AdminActivity(
    name: 'Rahul Johnson',
    action: 'Updated game settings',
    timeAgo: '2m ago',
  ),
  AdminActivity(
    name: 'Priya Desai',
    action: 'Resolved report #284',
    timeAgo: '14m ago',
  ),
  AdminActivity(
    name: 'Rahul Mehta',
    action: 'Added new host',
    timeAgo: '1h ago',
  ),
];

// ======================================================================
// Screen
// ======================================================================

/// Uses ONLY `Theme.of(context).colorScheme` -> light/dark works automatically.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    this.entries = defaultSettingsEntries,
    this.activity = sampleActivity,
    this.currentTab = 4,
    this.onTabSelected,
    this.onBack,
    this.onRefresh,
    this.onSectionTap,
    this.onViewAllActivity,
    this.onActivityTap,
    this.themeMode,
    this.onThemeModeChanged,
    this.onSignOut,
    this.auditLogsTab,
    this.adminRolesTab,
  });

  final List<SettingsEntry> entries;
  final List<AdminActivity> activity;
  final int currentTab;
  final ValueChanged<int>? onTabSelected;
  final VoidCallback? onBack;
  final Future<void> Function()? onRefresh;
  final ValueChanged<SettingsSection>? onSectionTap;
  final VoidCallback? onViewAllActivity;
  final ValueChanged<AdminActivity>? onActivityTap;

  /// Optional Appearance card (shows only when [onThemeModeChanged] is given).
  /// Wire it to the ThemeMode of your MaterialApp for instant light/dark switching.
  final ThemeMode? themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;

  /// Optional "Sign out" button (shows only when given).
  final VoidCallback? onSignOut;

  /// Plug your other tab contents in here later (placeholders shown until then).
  final Widget? auditLogsTab;
  final Widget? adminRolesTab;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  static const _tabs = ['System', 'Audit Logs', 'Admin Roles'];

  late final TabController _tabController;
  int _index = 0;
  int _previous = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this)
      ..addListener(() {
        if (_tabController.index != _index) {
          HapticFeedback.selectionClick();
          setState(() {
            _previous = _index;
            _index = _tabController.index;
          });
        }
      });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Widget _tabContent(int i) {
    switch (i) {
      case 0:
        return _SystemTab(
          key: const ValueKey('system'),
          entries: widget.entries,
          activity: widget.activity,
          onSectionTap: widget.onSectionTap,
          onViewAllActivity: widget.onViewAllActivity,
          onActivityTap: widget.onActivityTap,
          themeMode: widget.themeMode,
          onThemeModeChanged: widget.onThemeModeChanged,
          onSignOut: widget.onSignOut,
        );
      case 1:
        return widget.auditLogsTab ??
            const _ComingSoon(key: ValueKey('audit'), label: 'Audit Logs');
      default:
        return widget.adminRolesTab ??
            const _ComingSoon(key: ValueKey('roles'), label: 'Admin Roles');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final forward = _index >= _previous;

    return Scaffold(
      backgroundColor: cs.surface,
      // bottomNavigationBar: AdminBottomNav(
      //   currentIndex: widget.currentTab,
      //   onSelected: widget.onTabSelected,
      // ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ---- App bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Back',
                    onPressed:
                        widget.onBack ?? () => Navigator.maybePop(context),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 20,
                    ),
                  ),
                  Text(
                    'Settings',
                    style: text.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),

            // ---- Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: _Entry(index: 0, child: _buildTabBar(cs)),
            ),

            // ---- Content
            Expanded(
              child: RefreshIndicator(
                color: cs.primary,
                backgroundColor: cs.surfaceContainerHigh,
                onRefresh:
                    widget.onRefresh ??
                    () =>
                        Future<void>.delayed(const Duration(milliseconds: 900)),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  children: [
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.topCenter,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        switchInCurve: Curves.easeOutCubic,
                        transitionBuilder: (child, anim) => FadeTransition(
                          opacity: anim,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: Offset(forward ? 0.06 : -0.06, 0),
                              end: Offset.zero,
                            ).animate(anim),
                            child: child,
                          ),
                        ),
                        child: _tabContent(_index),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar(ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
      ),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        splashBorderRadius: BorderRadius.circular(12),
        indicator: BoxDecoration(
          color: cs.primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        labelColor: cs.onPrimary,
        unselectedLabelColor: cs.onSurface.withValues(alpha: 0.65),
        labelStyle: Theme.of(context).textTheme.labelMedium
            ?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: Theme.of(context).textTheme.labelMedium,
        tabs: [for (final t in _tabs) Tab(height: 38, text: t)],
      ),
    );
  }
}

// ======================================================================
// System tab
// ======================================================================

class _SystemTab extends StatelessWidget {
  const _SystemTab({
    super.key,
    required this.entries,
    required this.activity,
    this.onSectionTap,
    this.onViewAllActivity,
    this.onActivityTap,
    this.themeMode,
    this.onThemeModeChanged,
    this.onSignOut,
  });

  final List<SettingsEntry> entries;
  final List<AdminActivity> activity;
  final ValueChanged<SettingsSection>? onSectionTap;
  final VoidCallback? onViewAllActivity;
  final ValueChanged<AdminActivity>? onActivityTap;
  final ThemeMode? themeMode;
  final ValueChanged<ThemeMode>? onThemeModeChanged;
  final VoidCallback? onSignOut;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    var step = 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- Platform settings
        _Entry(
          index: step++,
          child: const _SectionHeader(title: 'Platform Settings'),
        ),
        const SizedBox(height: 8),
        _Entry(
          index: step++,
          child: _Card(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  if (i > 0)
                    Divider(
                      height: 1,
                      indent: 66,
                      endIndent: 16,
                      color: cs.outlineVariant.withValues(alpha: 0.5),
                    ),
                  _SettingsRow(
                    entry: entries[i],
                    onTap: onSectionTap == null
                        ? null
                        : () => onSectionTap!(entries[i].section),
                  ),
                ],
              ],
            ),
          ),
        ),

        // ---- Appearance (optional)
        if (onThemeModeChanged != null) ...[
          const SizedBox(height: 20),
          _Entry(
            index: step++,
            child: const _SectionHeader(title: 'Appearance'),
          ),
          const SizedBox(height: 8),
          _Entry(
            index: step++,
            child: _Card(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded, size: 18),
                      label: Text('System'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                      label: Text('Light'),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                      label: Text('Dark'),
                    ),
                  ],
                  selected: {themeMode ?? ThemeMode.system},
                  onSelectionChanged: (s) {
                    HapticFeedback.selectionClick();
                    onThemeModeChanged!(s.first);
                  },
                ),
              ),
            ),
          ),
        ],

        // ---- Recent admin activity
        const SizedBox(height: 20),
        _Entry(
          index: step++,
          child: _SectionHeader(
            title: 'Recent Admin Activity',
            actionLabel: 'View all',
            onAction: onViewAllActivity,
          ),
        ),
        const SizedBox(height: 8),
        _Entry(
          index: step++,
          child: _Card(
            padding: EdgeInsets.zero,
            child: activity.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        'No recent activity',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      for (var i = 0; i < activity.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            indent: 66,
                            endIndent: 16,
                            color: cs.outlineVariant.withValues(alpha: 0.5),
                          ),
                        _ActivityRow(
                          item: activity[i],
                          onTap: onActivityTap == null
                              ? null
                              : () => onActivityTap!(activity[i]),
                        ),
                      ],
                    ],
                  ),
          ),
        ),

        // ---- Sign out (optional)
        if (onSignOut != null) ...[
          const SizedBox(height: 24),
          _Entry(
            index: step++,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  onSignOut!();
                },
                icon: const Icon(Icons.logout_rounded, size: 20),
                label: const Text('Sign out'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: cs.error,
                  side: BorderSide(color: cs.error.withValues(alpha: 0.5)),
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.entry, this.onTap});
  final SettingsEntry entry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              onTap!();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: cs.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(entry.icon, size: 22, color: cs.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.title,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    entry.subtitle,
                    style: text.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.item, this.onTap});
  final AdminActivity item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: cs.primaryContainer,
              backgroundImage: item.avatar,
              child: item.avatar == null
                  ? Text(
                      item.name.isEmpty ? '?' : item.name[0].toUpperCase(),
                      style: TextStyle(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.action,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              item.timeAgo,
              style: text.labelSmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ======================================================================
// Small shared bits
// ======================================================================

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: Row(
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const Spacer(),
          if (actionLabel != null)
            TextButton(
              onPressed: onAction,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 32),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withValues(alpha: 0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Material(
          color: Colors.transparent,
          child: Padding(
            padding: padding ?? const EdgeInsets.all(14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.index, required this.child});
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 350 + index.clamp(0, 7) * 80),
      curve: Curves.easeOutCubic,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - v)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

class _ComingSoon extends StatelessWidget {
  const _ComingSoon({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.construction_rounded,
              size: 40,
              color: cs.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              '$label coming soon',
              style: text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Plug your $label content into this tab.',
              style: text.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
