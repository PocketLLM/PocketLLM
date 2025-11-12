/// File Overview:
/// - Purpose: Settings hub that links to theming, profile, model, and API key
///   configuration screens.
/// - Backend Migration: Keep but audit sections that reference local-only
///   features (e.g., direct model saves) as backend ownership grows.
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../component/appearance_settings_popup.dart';
import '../models/user_profile.dart';
import '../services/auth_state.dart';
import '../services/model_service.dart';
import '../services/theme_service.dart';
import 'auth/auth_flow_screen.dart';
import 'settings/profile/profile_settings.dart';
import 'api_keys_page.dart';
import 'config_page.dart';
import 'docs_page.dart';
import 'library_page.dart';
import 'model_settings_page.dart';
import 'referral_center_page.dart';
import 'search_settings_page.dart';
import 'app_info_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final ModelService _modelService = ModelService();

  @override
  Widget build(BuildContext context) {
    final colorScheme = ThemeService().colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      appBar: AppBar(
        backgroundColor: colorScheme.background,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onBackground, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: colorScheme.onBackground,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Appearance'),
          _buildSettingsItem(
            icon: Icons.palette_outlined,
            iconColor: ThemeService().colorScheme.primary,
            title: 'Theme Settings',
            // subtitle: 'Configure app appearance and dark mode',
            onTap: () => _showThemeSettings(context),
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('Account'),
          _buildSettingsItem(
            icon: Icons.person_outline,
            iconColor: Colors.blue,
            title: 'Profile Settings',
            // subtitle: 'Manage your account and preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.card_giftcard,
            iconColor: Colors.pinkAccent,
            title: 'Referral Center',
            // subtitle: 'Share invites and track rewards',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReferralCenterPage()),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            title: 'Notifications',
            // subtitle: 'Configure app notifications',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('AI Configuration'),
          _buildSettingsItem(
            icon: Icons.psychology,
            iconColor: Colors.purple,
            title: 'Model Settings',
            // subtitle: 'Configure AI models and parameters',
            showActionButtons: false, // Removed the + button
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ModelSettingsPage()),
              ).then((_) {
                // Refresh the state when returning from the model settings page
                setState(() {});
              });
            },
          ),
          _buildSettingsItem(
            icon: Icons.search,
            iconColor: Colors.green,
            title: 'Search Configuration',
            // subtitle: 'Customize search behavior and sources',
            showActionButtons: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SearchConfigPage()),
              );
            },
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('Database'),
          _buildSettingsItem(
            icon: Icons.schema,
            iconColor: Colors.indigo,
            title: 'Vector Databases',
            // subtitle: 'Manage embeddings and vector storage',
          ),
          _buildSettingsItem(
            icon: Icons.share,
            iconColor: Colors.blue,
            title: 'Graph Databases',
            // subtitle: 'Configure knowledge graph settings',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('Security'),
          _buildSettingsItem(
            icon: Icons.security,
            iconColor: Colors.green,
            title: 'Privacy',
            // subtitle: 'Manage data and privacy settings',
          ),
          _buildSettingsItem(
            icon: Icons.key,
            iconColor: Colors.orange,
            title: 'API Keys',
            // subtitle: 'Manage API keys and authentication',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ApiKeysPage()),
              );
            },
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('Advanced'),
          _buildSettingsItem(
            icon: Icons.memory,
            iconColor: Colors.deepPurple,
            title: 'Memory Management',
            // subtitle: 'Configure context and history settings',
          ),
          _buildSettingsItem(
            icon: Icons.terminal,
            iconColor: Colors.grey[800]!,
            title: 'Developer Options',
            // subtitle: 'Advanced configuration and debugging',
          ),
          _buildSettingsItem(
            icon: Icons.backup,
            iconColor: Colors.teal,
            title: 'Backup & Sync',
            // subtitle: 'Manage data backup and synchronization',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('About'),
          _buildSettingsItem(
            icon: Icons.info_outline,
            iconColor: Colors.blue,
            title: 'App Information',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AppInfoPage()),
              );
            },
          ),
          
          SizedBox(height: 40),
          _buildLogoutButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final colorScheme = ThemeService().colorScheme;
    
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: colorScheme.onBackground,
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    // required String subtitle,
    bool showActionButtons = false,
    VoidCallback? onTap,
    VoidCallback? onAddPressed,
  }) {
    final colorScheme = ThemeService().colorScheme;
    
    // Check if this is one of the implemented features
    bool isImplemented = [
      'Theme Settings',
      'Profile Settings',
      'Model Settings',
      'Search Configuration',
      'API Keys',
      'App Information',
    ].contains(title);

    return Card(
      elevation: 0,
      color: colorScheme.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.cardBorder),
      ),
      child: InkWell(
        onTap: isImplemented 
            ? onTap 
            : () {
                // Show "Coming Soon" alert for unimplemented features
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: ThemeService().colorScheme.surface,
                    title: Text(
                      'Coming Soon',
                      style: TextStyle(color: ThemeService().colorScheme.onSurface),
                    ),
                    content: Text(
                      'This feature is currently under development and will be available in a future update.',
                      style: TextStyle(color: ThemeService().colorScheme.onSurface),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'OK',
                          style: TextStyle(color: ThemeService().colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                );
              },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    SizedBox(height: 4),
                    // Text(
                    //   subtitle,
                    //   style: TextStyle(
                    //     fontSize: 14,
                    //     color: colorScheme.onSurface.withOpacity(0.7),
                    //   ),
                    // ),
                  ],
                ),
              ),
              if (showActionButtons && isImplemented)
                Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface.withOpacity(0.4), size: 16)
              else if (isImplemented)
                Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface.withOpacity(0.4), size: 16)
              else
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Coming Soon',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber[800],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeSettings(BuildContext context) {
    final themeService = ThemeService();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width,
      ),
      builder: (BuildContext buildContext) {
        return Container(
          width: double.infinity,
          child: DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder: (BuildContext buildContext, ScrollController scrollController) {
              return AppearanceSettingsPopup(themeService: themeService);
            },
          ),
        );
      },
    );
  }
  
  String _getThemeModeLabel(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
      case AppThemeMode.highContrast:
        return 'High Contrast';
    }
  }
  
  String _getColorSchemeLabel(ColorSchemeType type) {
    switch (type) {
      case ColorSchemeType.standard:
        return 'Standard';
      case ColorSchemeType.highContrast:
        return 'High Contrast';
      case ColorSchemeType.custom:
        return 'Custom';
    }
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ElevatedButton(
        onPressed: () async {
          // Show confirmation dialog
          final shouldLogout = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: ThemeService().colorScheme.surface,
              title: Text(
                'Logout',
                style: TextStyle(color: ThemeService().colorScheme.onSurface),
              ),
              content: Text(
                'Are you sure you want to logout?',
                style: TextStyle(color: ThemeService().colorScheme.onSurface),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: ThemeService().colorScheme.onSurface.withOpacity(0.7)),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(
                    'Logout',
                    style: TextStyle(color: ThemeService().colorScheme.primary),
                  ),
                ),
              ],
            ),
          );
          
          if (shouldLogout == true) {
            final authState = context.read<AuthState>();
            await authState.signOut();
            if (!mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const AuthFlowScreen()),
              (route) => false,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeService().colorScheme.primary,
          foregroundColor: ThemeService().colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: ThemeService().colorScheme.onPrimary),
            SizedBox(width: 8),
            Text(
              'Logout',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: ThemeService().colorScheme.onPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
