import 'package:flutter/material.dart';
import 'dart:ui';
import 'settings/profile_settings.dart';
import '../component/model_config_dialog.dart';
import 'model_settings_page.dart';
import 'api_keys_page.dart';
import '../services/model_service.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'search_settings_page.dart';
import '../services/local_db_service.dart';
import '../component/models.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _authService = AuthService();
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
            subtitle: 'Configure app appearance and dark mode',
            onTap: () => _showThemeSettings(context),
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('Account'),
          _buildSettingsItem(
            icon: Icons.person_outline,
            iconColor: Colors.blue,
            title: 'Profile Settings',
            subtitle: 'Manage your account and preferences',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.notifications_outlined,
            iconColor: Colors.orange,
            title: 'Notifications',
            subtitle: 'Configure app notifications',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('AI Configuration'),
          _buildSettingsItem(
            icon: Icons.psychology,
            iconColor: Colors.purple,
            title: 'Model Settings',
            subtitle: 'Configure AI models and parameters',
            showActionButtons: true,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ModelSettingsPage()),
              ).then((_) {
                // Refresh the state when returning from the model settings page
                setState(() {});
              });
            },
            onAddPressed: () {
              showDialog(
                context: context,
                builder: (context) => ModelConfigDialog(
                  onSave: (config) async {
                    await _modelService.saveModel(config);
                    // If this is the first model, set it as selected
                    final configs = await _modelService.getSavedModels();
                    if (configs.length == 1) {
                      await _modelService.setDefaultModel(config.id);
                    }
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Model configuration saved')),
                    );
                  },
                ),
              );
            },
          ),
          _buildSettingsItem(
            icon: Icons.search,
            iconColor: Colors.green,
            title: 'Search Configuration',
            subtitle: 'Customize search behavior and sources',
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
            subtitle: 'Manage embeddings and vector storage',
          ),
          _buildSettingsItem(
            icon: Icons.share,
            iconColor: Colors.blue,
            title: 'Graph Databases',
            subtitle: 'Configure knowledge graph settings',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('Security'),
          _buildSettingsItem(
            icon: Icons.security,
            iconColor: Colors.green,
            title: 'Privacy',
            subtitle: 'Manage data and privacy settings',
          ),
          _buildSettingsItem(
            icon: Icons.key,
            iconColor: Colors.orange,
            title: 'API Keys',
            subtitle: 'Manage API keys and authentication',
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
            subtitle: 'Configure context and history settings',
          ),
          _buildSettingsItem(
            icon: Icons.terminal,
            iconColor: Colors.grey[800]!,
            title: 'Developer Options',
            subtitle: 'Advanced configuration and debugging',
          ),
          _buildSettingsItem(
            icon: Icons.backup,
            iconColor: Colors.teal,
            title: 'Backup & Sync',
            subtitle: 'Manage data backup and synchronization',
          ),
          
          SizedBox(height: 32),
          _buildSectionTitle('About'),
          _buildSettingsItem(
            icon: Icons.info_outline,
            iconColor: Colors.blue,
            title: 'App Information',
            subtitle: 'Version, licenses, and documentation',
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
    required String subtitle,
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
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (showActionButtons && isImplemented)
                Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.add, color: ThemeService().colorScheme.primary),
                      onPressed: onAddPressed,
                    ),
                    Icon(Icons.arrow_forward_ios, color: colorScheme.onSurface.withOpacity(0.4), size: 16),
                  ],
                )
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
    final colorScheme = themeService.colorScheme;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            'Theme Settings',
            style: TextStyle(color: ThemeService().colorScheme.onSurface),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Theme Mode',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ThemeService().colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...AppThemeMode.values.map((mode) => RadioListTile<AppThemeMode>(
                title: Text(
                  _getThemeModeLabel(mode),
                  style: TextStyle(color: ThemeService().colorScheme.onSurface),
                ),
                value: mode,
                groupValue: themeService.themeMode,
                onChanged: (value) async {
                  if (value != null) {
                    await themeService.setThemeMode(value);
                    setState(() {});
                    // Update the parent widget
                    this.setState(() {});
                  }
                },
                activeColor: ThemeService().colorScheme.primary,
              )),
              const SizedBox(height: 16),
              Text(
                'Color Scheme',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: ThemeService().colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              ...ColorSchemeType.values.map((type) => RadioListTile<ColorSchemeType>(
                title: Text(
                  _getColorSchemeLabel(type),
                  style: TextStyle(color: ThemeService().colorScheme.onSurface),
                ),
                value: type,
                groupValue: themeService.colorSchemeType,
                onChanged: (value) async {
                  if (value != null) {
                    await themeService.setColorSchemeType(value);
                    setState(() {});
                    // Update the parent widget
                    this.setState(() {});
                  }
                },
                activeColor: ThemeService().colorScheme.primary,
              )),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Done',
                style: TextStyle(color: ThemeService().colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
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
            // Perform logout
            await _authService.signOut();
            // Navigate to login screen
            Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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