import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../pages/vpn/dashboard_page.dart';
import '../pages/vpn/history_page.dart';
import '../pages/vpn/settings_page.dart';
import '../pages/vpn/speed_test_page.dart';
import '../services/vpn_connection_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const List<String> _pageTitles = <String>[
    'Dashboard',
    'Speed Test',
    'History',
    'Settings',
  ];

  final List<Widget> _pages = const <Widget>[
    DashboardPage(),
    SpeedTestPage(),
    HistoryPage(),
    VpnSettingsPage(),
  ];

  void _onItemTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(72),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: theme.colorScheme.primary.withOpacity(0.12),
                  ),
                  child: Icon(Icons.lock_outline, color: theme.colorScheme.primary),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'PocketLLM VPN',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _pageTitles[_currentIndex],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Consumer<VpnConnectionService>(
                  builder: (context, connection, _) {
                    final bool isConnected = connection.isConnected;
                    final Color badgeColor = isConnected
                        ? Colors.green
                        : connection.isBusy
                            ? Colors.amber
                            : Colors.redAccent;
                    final IconData badgeIcon = isConnected
                        ? Icons.verified_rounded
                        : connection.isBusy
                            ? Icons.hourglass_bottom
                            : Icons.shield_outlined;
                    final String label = isConnected
                        ? 'Connected'
                        : connection.isBusy
                            ? 'Connecting'
                            : 'Disconnected';
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(badgeIcon, size: 18, color: badgeColor),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: badgeColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: IndexedStack(
          key: ValueKey<int>(_currentIndex),
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: _GlassBottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          _NavItem(icon: Icons.shield_rounded, label: 'Home'),
          _NavItem(icon: Icons.speed_rounded, label: 'Speed'),
          _NavItem(icon: Icons.timeline_outlined, label: 'History'),
          _NavItem(icon: Icons.tune, label: 'Settings'),
        ],
      ),
    );
  }
}

class _GlassBottomNavigationBar extends StatelessWidget {
  const _GlassBottomNavigationBar({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (int index = 0; index < items.length; index++)
            _NavButton(
              item: items[index],
              isSelected: currentIndex == index,
              onTap: () => onTap(index),
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.item, required this.isSelected, required this.onTap});

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final Color activeColor = theme.colorScheme.primary;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              Text(
                item.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isSelected ? activeColor : theme.colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
