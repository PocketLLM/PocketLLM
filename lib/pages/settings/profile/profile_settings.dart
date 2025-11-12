import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../auth/auth_page.dart';
import '../../../models/user_profile.dart';
import '../../../services/auth_state.dart';
import '../../../services/theme_service.dart';
import '../../../theme/app_colors.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  _ProfileSettingsPageState createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;
  final _formKey = GlobalKey<FormState>();

  static const Map<String, String> _languageLabels = {
    'en': 'English',
    'fr': 'French',
    'es': 'Spanish',
    'de': 'German',
    'pt': 'Portuguese',
  };

  @override
  void initState() {
    super.initState();
    Future.microtask(() => context.read<AuthState>().refreshProfile());
  }

  Future<void> _pickImage(AuthState authState) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 600,
        maxHeight: 600,
      );
      if (image == null) return;

      setState(() => _isProcessing = true);
      final file = File(image.path);
      final avatarUrl = await authState.uploadProfileImage(file);
      await authState.updateProfileFields({'avatar_url': avatarUrl});
      await authState.refreshProfile();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating image: $e')),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _updateField(
    AuthState authState, 
    String field, 
    String currentValue
  ) async {
    final controller = TextEditingController(text: currentValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${field.replaceAll('_', ' ').capitalize()}'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter ${field.replaceAll('_', ' ')}',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          maxLines: field == 'bio' ? 3 : 1,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        await authState.updateProfileFields({field: result});
        await authState.refreshProfile();
        if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ThemeService().colorScheme;
    final authState = context.watch<AuthState>();
    final profile = authState.profile;
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = Theme.of(context).primaryColor;
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final surfaceColor = Theme.of(context).cardColor;
    final onSurfaceColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black;
    final onPrimaryColor = Colors.white;
    final primaryVariant = Theme.of(context).primaryColorLight;

    if (_isProcessing) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Profile Settings'),
          backgroundColor: surfaceColor,
          foregroundColor: onSurfaceColor,
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Profile Settings'),
        backgroundColor: surfaceColor,
        foregroundColor: onSurfaceColor,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor,
                    primaryVariant,
                  ],
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: surfaceColor,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: profile?.avatarUrl != null
                              ? Image.network(
                                  profile!.avatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildDefaultAvatar(theme),
                                )
                              : _buildDefaultAvatar(theme),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _pickImage(authState),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: primaryVariant,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: surfaceColor,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile?.fullName ?? 'No name',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: onPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (profile?.username != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '@${profile!.username!}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: onPrimaryColor.withOpacity(0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      // Main content
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
                  _buildSectionHeader('Account', context),
                  _buildEditableField(
                    context: context,
                    label: 'Display Name',
                    value: profile?.fullName ?? 'Not set',
                    icon: Icons.person_outline,
                    onTap: () => _updateField(
                      authState,
                      'full_name',
                      profile?.fullName ?? '',
                    ),
                  ),
                  _buildDivider(),
                  _buildEditableField(
                    context: context,
                    label: 'Username',
                    value: profile?.username ?? 'Not set',
                    icon: Icons.alternate_email,
                    onTap: () => _updateField(
                      authState,
                      'username',
                      profile?.username ?? '',
                    ),
                  ),
                  _buildDivider(),
                  _buildEditableField(
                    context: context,
                    label: 'Email',
                    value: profile?.email ?? 'Not set',
                    icon: Icons.email_outlined,
                    onTap: () {},
                    showTrailing: false,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Preferences', context),
                  // Theme Mode
                  _buildPreferenceTile(
                    context: context,
                    title: 'Appearance',
                    subtitle: isDark ? 'Dark Mode' : 'Light Mode',
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    trailing: Switch.adaptive(
                      value: isDark,
                      onChanged: (_) => context.read<ThemeService>().toggleDarkMode(),
                      activeColor: primaryColor,
                    ),
                  ),
                  _buildDivider(),
                  // Complete Onboarding
                  _buildPreferenceTile(
                    context: context,
                    title: 'Complete Onboarding',
                    subtitle: 'Fill out your profile details',
                    icon: Icons.person_add_alt_1_rounded,
                    onTap: () => _showOnboardingFlow(context, authState),
                  ),
                  _buildDivider(),
                  _buildPreferenceTile(
                    context: context,
                    title: 'Language',
                    subtitle: _languageLabels[_currentLanguage(profile)] ?? 'English',
                    icon: Icons.language,
                    onTap: () => _showLanguagePicker(authState, _currentLanguage(profile)),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Danger Zone', context, isDanger: true),
                  _buildDangerTile(
                    context: context,
                    title: 'Change Password',
                    icon: Icons.lock_outline,
                    onTap: () => _showChangePasswordDialog(authState),
                  ),
                  _buildDivider(),
                  _buildDangerTile(
                    context: context,
                    title: 'Sign Out',
                    icon: Icons.logout,
                    onTap: () => _showSignOutConfirmation(context, authState),
                  ),
                  _buildDivider(),
                  _buildDangerTile(
                    context: context,
                    title: 'Delete Account',
                    icon: Icons.delete_forever,
                    onTap: () => _showDeleteAccountConfirmation(context, authState),
                    isDestructive: true,
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultAvatar(ThemeData theme) {
    return Icon(
      Icons.person,
      size: 50,
      color: theme.textTheme.bodyLarge?.color?.withOpacity(0.7) ?? Colors.grey[400],
    );
  }

  String _currentLanguage(UserProfile? profile) {
    final lang = profile?.onboarding?['language'];
    if (lang is String && lang.isNotEmpty) return lang;
    return 'en';
  }

  Widget _buildSectionHeader(String title, BuildContext context, {bool isDanger = false}) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDanger 
                  ? theme.colorScheme.error 
                  : theme.textTheme.bodySmall?.color?.withOpacity(0.6) ?? Colors.grey[600],
              letterSpacing: 1.0,
            ),
      ),
    );
  }

  Widget _buildDivider() {
    return const SizedBox(height: 8);
  }

  Widget _buildEditableField({
    required BuildContext context,
    required String label,
    required String value,
    required IconData icon,
    VoidCallback? onTap,
    bool showTrailing = true,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final surfaceColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        title: Text(
          label,
          style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.8) ?? Colors.grey[600],
              ),
        ),
        subtitle: Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
        ),
        trailing: showTrailing
            ? Icon(
                Icons.chevron_right,
                color: textColor?.withOpacity(0.5) ?? Colors.grey[400],
              )
            : null,
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildPreferenceTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final surfaceColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey[600],
              ),
        ),
        trailing: trailing ?? Icon(
          Icons.chevron_right,
          color: textColor?.withOpacity(0.5) ?? Colors.grey[400],
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDangerTile({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final errorColor = theme.colorScheme.error;
    final textColor = theme.textTheme.bodyLarge?.color;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withOpacity(0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDestructive 
                ? errorColor.withOpacity(0.1)
                : primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isDestructive ? errorColor : primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: theme.textTheme.bodyLarge?.copyWith(
                color: isDestructive ? errorColor : textColor,
                fontWeight: FontWeight.w500,
              ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: isDestructive 
              ? errorColor.withOpacity(0.8)
              : (textColor?.withOpacity(0.5) ?? Colors.grey[400]),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isDestructive ? colors.error : colors.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: textColor,
                          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.w500,
                        ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: isDestructive ? colors.error : colors.onSurface.withOpacity(0.5),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showLanguagePicker(AuthState authState, String? currentLang) async {
    final colors = ThemeService().colorScheme;
    
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: colors.onSurface.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Select Language',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
            ),
            const SizedBox(height: 16),
            ..._languageLabels.entries.map((entry) => ListTile(
              leading: Radio<String>(
                value: entry.key,
                groupValue: currentLang ?? 'en',
                onChanged: (value) => Navigator.pop(context, value),
              ),
              title: Text(entry.value),
              onTap: () => Navigator.pop(context, entry.key),
            )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (selected != null && selected != currentLang) {
      setState(() => _isProcessing = true);
      try {
        final onboarding = Map<String, dynamic>.from(authState.profile?.onboarding ?? {});
        onboarding['language'] = selected;
        await authState.updateProfileFields({'onboarding': onboarding});
        await authState.refreshProfile();
        if (!mounted) return;
        
        final label = _languageLabels[selected] ?? selected;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Language updated to $label')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update language: $e')),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _showChangePasswordDialog(AuthState authState) async {
    final colors = ThemeService().colorScheme;
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Change Password',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colors.onSurface,
                    ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  labelStyle: TextStyle(color: colors.onSurface.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.onSurface.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.onSurface.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  labelStyle: TextStyle(color: colors.onSurface.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.onSurface.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.onSurface.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 8) {
                    return 'Password must be at least 8 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm New Password',
                  labelStyle: TextStyle(color: colors.onSurface.withOpacity(0.7)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.onSurface.withOpacity(0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.onSurface.withOpacity(0.1)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: colors.primary, width: 2),
                  ),
                ),
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: colors.onSurface.withOpacity(0.1)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(color: colors.onSurface),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isProcessing
                          ? null
                          : () async {
                              if (_formKey.currentState?.validate() ?? false) {
                                setState(() => _isProcessing = true);
                                try {
                                  await authState.updatePassword(
                                    currentPasswordController.text,
                                    newPasswordController.text,
                                  );
                                  if (!mounted) return;
                                  
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Password updated successfully'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: colors.error,
                                    ),
                                  );
                                } finally {
                                  if (mounted) setState(() => _isProcessing = false);
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        disabledBackgroundColor: colors.primary.withOpacity(0.5),
                      ),
                      child: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Update Password'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSignOutConfirmation(
    BuildContext context, 
    AuthState authState,
  ) async {
    final colors = ThemeService().colorScheme;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: colors.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await authState.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const AuthPage()),
        (route) => false,
      );
    }
  }

  Future<void> _showOnboardingFlow(BuildContext context, AuthState authState) async {
    // This would navigate to your onboarding flow
    // For now, we'll just show a dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Your Profile'),
        content: const Text('You will be taken through the onboarding process to complete your profile setup.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Navigate to onboarding flow
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Onboarding flow will be implemented here')),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAccountConfirmation(
    BuildContext context, 
    AuthState authState,
  ) async {
    final theme = Theme.of(context);
    final primaryColor = theme.primaryColor;
    final errorColor = theme.colorScheme.error;
    final surfaceColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color;
    final passwordController = TextEditingController();
    
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: (textColor ?? Colors.black).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: errorColor, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: errorColor,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'This action is permanent and cannot be undone. All your data will be permanently deleted. Please enter your password to confirm.',
              style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                labelStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color?.withOpacity(0.7) ?? Colors.grey[600],
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: theme.dividerColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: errorColor, width: 1),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: errorColor, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: theme.dividerColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: textColor),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isProcessing
                        ? null
                        : () async {
                            if (passwordController.text.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter your password'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                              return;
                            }

                            setState(() => _isProcessing = true);
                            try {
                              await authState.deleteAccount();
                              if (!mounted) return;
                              
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(builder: (_) => const AuthPage()),
                                (route) => false,
                              );
                            } catch (e) {
                              if (!mounted) return;
                              setState(() => _isProcessing = false);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: errorColor,
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      disabledBackgroundColor: errorColor.withOpacity(0.5),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Delete Account'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }
}
