/// File Overview:
/// - Purpose: Profile management screen allowing users to update personal info
///   and avatars directly.
/// - Backend Migration: Keep but ensure all operations call backend endpoints
///   (no local shared preference fallbacks).
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_page.dart';
import '../auth/user_survey_page.dart';
import '../../models/user_profile.dart';
import '../../services/auth_state.dart';
import '../../services/theme_service.dart';
import '../../theme/app_colors.dart';

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

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
      final image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600);
      if (image == null) return;

      setState(() => _isProcessing = true);
      final file = File(image.path);
      final avatarUrl = await authState.uploadProfileImage(file);
      await authState.updateProfileFields({'avatar_url': avatarUrl});
      await authState.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated'), backgroundColor: Color(0xFF8B5CF6)),
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

  Future<void> _updateField(AuthState authState, String field, String currentValue) async {
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
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
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
          const SnackBar(content: Text('Profile updated'), backgroundColor: Color(0xFF8B5CF6)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e'), backgroundColor: Colors.redAccent),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _selectDate(AuthState authState) async {
    final profile = authState.profile;
    final initial = profile?.dateOfBirth ?? DateTime.now().subtract(const Duration(days: 365 * 18));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _isProcessing = true);
      try {
        await authState.updateProfileFields({'date_of_birth': picked.toIso8601String()});
        await authState.refreshProfile();
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _changePassword(AuthState authState) async {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'New Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newPassword = newPasswordController.text.trim();
              if (newPassword.length < 8) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password must be at least 8 characters'), backgroundColor: Colors.redAccent),
                );
                return;
              }
              if (newPassword != confirmPasswordController.text.trim()) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.redAccent),
                );
                return;
              }
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF8B5CF6), foregroundColor: Colors.white),
            child: const Text('Update'),
          ),
        ],
      ),
    );

    if (result == true) {
      setState(() => _isProcessing = true);
      try {
        await authState.updatePassword(newPasswordController.text.trim());
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password updated'), backgroundColor: Color(0xFF8B5CF6)),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating password: $e'), backgroundColor: Colors.redAccent),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleSignOut(AuthState authState) async {
    setState(() => _isProcessing = true);
    try {
      await authState.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('authSkipped', true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed out')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleDeleteAccount(AuthState authState) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Deleting your account will schedule removal in 30 days. You can cancel by logging in before then.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isProcessing = true);
      try {
        await authState.requestAccountDeletion();
        await authState.refreshProfile();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account scheduled for deletion in 30 days'), backgroundColor: Colors.orange),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error scheduling deletion: $e'), backgroundColor: Colors.redAccent),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _cancelDeletion(AuthState authState) async {
    setState(() => _isProcessing = true);
    try {
      await authState.cancelAccountDeletion();
      await authState.refreshProfile();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Deletion cancelled'), backgroundColor: Color(0xFF8B5CF6)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error cancelling deletion: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Widget _buildProfileContent(AuthState authState) {
    final profile = authState.profile;
    if (profile == null) {
      return const Center(child: CircularProgressIndicator());
    }

    ImageProvider? avatarProvider;
    if (profile.avatarUrl != null && profile.avatarUrl!.isNotEmpty) {
      if (profile.avatarUrl!.startsWith('http')) {
        avatarProvider = NetworkImage(profile.avatarUrl!);
      } else {
        final file = File(profile.avatarUrl!);
        if (file.existsSync()) {
          avatarProvider = FileImage(file);
        }
      }
    }

    return AnimatedBuilder(
      animation: ThemeService(),
      builder: (context, _) {
        final colorScheme = ThemeService().colorScheme;
        final accent = colorScheme.primary;
        final softBackground = _tintWithSurface(accent, colorScheme.surface);

        return Container(
          color: softBackground,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withOpacity(0.18),
                        blurRadius: 40,
                        offset: const Offset(0, 24),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: _isProcessing ? null : () => _pickImage(authState),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  CircleAvatar(
                                    radius: 46,
                                    backgroundColor: colorScheme.cardBorder.withOpacity(0.3),
                                    backgroundImage: avatarProvider,
                                    child: avatarProvider == null
                                        ? Icon(Icons.person, size: 48, color: colorScheme.onSurface.withOpacity(0.35))
                                        : null,
                                  ),
                                  Positioned(
                                    right: -2,
                                    bottom: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: accent,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: accent.withOpacity(0.35),
                                            blurRadius: 10,
                                          ),
                                        ],
                                      ),
                                      child: Icon(Icons.edit, color: colorScheme.onPrimary, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    profile.fullName?.isNotEmpty == true
                                        ? profile.fullName!
                                        : (profile.username ?? 'Your profile'),
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    profile.email,
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: colorScheme.onSurface.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: profile.hasPendingDeletion
                              ? _buildPendingDeletionCard(colorScheme, authState, profile)
                              : const SizedBox.shrink(key: ValueKey('no-deletion-card')),
                        ),
                        if (!profile.hasPendingDeletion) const SizedBox(height: 4),
                        _buildMenuTile(
                          colorScheme: colorScheme,
                          icon: Icons.assignment_ind_outlined,
                          title: 'Account details',
                          subtitle: 'Update your personal information',
                          onTap: () => _showAccountDetailsSheet(authState, profile),
                        ),
                        _buildMenuTile(
                          colorScheme: colorScheme,
                          icon: Icons.lock_outline,
                          title: 'Change password',
                          subtitle: 'Keep your account secure',
                          onTap: () => _changePassword(authState),
                        ),
                        _buildMenuTile(
                          colorScheme: colorScheme,
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Receive important updates',
                          trailing: _buildNotificationSwitch(colorScheme, authState, profile),
                        ),
                        _buildMenuTile(
                          colorScheme: colorScheme,
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: _languageLabels[_resolveLanguage(profile)] ?? 'English',
                          onTap: () => _showLanguagePicker(authState, profile),
                        ),
                        _buildMenuTile(
                          colorScheme: colorScheme,
                          icon: Icons.dark_mode_outlined,
                          title: 'Theme mode',
                          subtitle: 'Match PocketLLM to your preference',
                          trailing: _buildThemeToggle(colorScheme),
                        ),
                        _buildMenuTile(
                          colorScheme: colorScheme,
                          icon: Icons.flag_outlined,
                          title: 'Onboarding',
                          subtitle: profile.surveyCompleted
                              ? 'Update your onboarding answers'
                              : 'Finish getting started',
                          onTap: _isProcessing
                              ? null
                              : () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => UserSurveyPage(
                                        onComplete: () {},
                                      ),
                                    ),
                                  );
                                  if (mounted) {
                                    await authState.refreshProfile();
                                  }
                                },
                        ),
                        const SizedBox(height: 12),
                        Divider(color: colorScheme.cardBorder.withOpacity(0.6)),
                        const SizedBox(height: 12),
                        _buildMenuTile(
                          colorScheme: colorScheme,
                          icon: Icons.delete_outline,
                          title: 'Delete account',
                          subtitle: 'Schedule removal after a 30-day grace period',
                          onTap: () => _handleDeleteAccount(authState),
                          isDestructive: true,
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : () => _handleSignOut(authState),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Logout'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accent,
                              foregroundColor: colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPendingDeletionCard(
    AppColorScheme colorScheme,
    AuthState authState,
    UserProfile profile,
  ) {
    return Container(
      key: const ValueKey('pending-deletion-card'),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2E7),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFFFB680)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account scheduled for deletion',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.deepOrange.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account will be removed on ${_formatDateDisplay(profile.deletionScheduledFor)} unless you cancel beforehand.',
            style: TextStyle(
              color: Colors.deepOrange.shade600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isProcessing ? null : () => _cancelDeletion(authState),
              icon: const Icon(Icons.restore_rounded),
              label: const Text('Cancel deletion'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.deepOrange.shade700,
                side: BorderSide(color: Colors.deepOrange.shade300),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSwitch(AppColorScheme colorScheme, AuthState authState, UserProfile profile) {
    final isEnabled = _readNotificationsPreference(profile);
    return Switch(
      value: isEnabled,
      onChanged: _isProcessing
          ? null
          : (value) async {
              setState(() => _isProcessing = true);
              try {
                final updatedOnboarding = Map<String, dynamic>.from(profile.onboarding ?? {});
                updatedOnboarding['notifications_enabled'] = value;
                await authState.updateProfileFields({'onboarding': updatedOnboarding});
                await authState.refreshProfile();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Unable to update notifications: $e')),
                );
              } finally {
                if (mounted) setState(() => _isProcessing = false);
              }
            },
      activeColor: colorScheme.primary,
    );
  }

  Widget _buildThemeToggle(AppColorScheme colorScheme) {
    final themeService = ThemeService();
    final isHighContrast = themeService.colorSchemeType == ColorSchemeType.highContrast;
    return Switch(
      value: isHighContrast,
      activeColor: colorScheme.primary,
      onChanged: (value) async {
        if (_isProcessing) return;
        setState(() => _isProcessing = true);
        try {
          if (value) {
            await themeService.setColorSchemeType(ColorSchemeType.highContrast);
          } else {
            await themeService.setColorSchemeType(ColorSchemeType.standard);
          }
        } finally {
          if (mounted) setState(() => _isProcessing = false);
        }
      },
    );
  }

  Future<void> _showAccountDetailsSheet(AuthState authState, UserProfile profile) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
        return AnimatedBuilder(
          animation: ThemeService(),
          builder: (context, _) {
            final sheetColors = ThemeService().colorScheme;
            return Padding(
              padding: EdgeInsets.only(bottom: bottomPadding),
              child: Container(
                decoration: BoxDecoration(
                  color: sheetColors.surface,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [
                    BoxShadow(
                      color: sheetColors.shadow.withOpacity(0.25),
                      blurRadius: 30,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Account details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: sheetColors.onSurface,
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close, color: sheetColors.onSurface.withOpacity(0.6)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildEditableField(
                          colorScheme,
                          'Full Name',
                          profile.fullName ?? '',
                          () => _updateField(authState, 'full_name', profile.fullName ?? ''),
                        ),
                        _buildEditableField(
                          colorScheme,
                          'Username',
                          profile.username ?? '',
                          () => _updateField(authState, 'username', profile.username ?? ''),
                        ),
                        _buildEditableField(
                          colorScheme,
                          'Bio',
                          profile.bio ?? '',
                          () => _updateField(authState, 'bio', profile.bio ?? ''),
                        ),
                        _buildEditableField(
                          colorScheme,
                          'Date of Birth',
                          _formatDateDisplay(profile.dateOfBirth),
                          () => _selectDate(authState),
                        ),
                        _buildEditableField(
                          colorScheme,
                          'Profession',
                          profile.profession ?? '',
                          () => _updateField(authState, 'profession', profile.profession ?? ''),
                        ),
                        _buildEditableField(
                          colorScheme,
                          'How you heard about us',
                          profile.heardFrom ?? '',
                          () => _updateField(authState, 'heard_from', profile.heardFrom ?? ''),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showLanguagePicker(AuthState authState, UserProfile profile) async {
    final currentCode = _resolveLanguage(profile);
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return AnimatedBuilder(
          animation: ThemeService(),
          builder: (context, _) {
            final colors = ThemeService().colorScheme;
            return Container(
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.25),
                    blurRadius: 30,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shrinkWrap: true,
                  children: _languageLabels.entries.map((entry) {
                    final isSelected = entry.key == currentCode;
                    return ListTile(
                      leading: Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                        color: isSelected ? colors.primary : colors.onSurface.withOpacity(0.4),
                      ),
                      title: Text(entry.value),
                      onTap: () => Navigator.pop(context, entry.key),
                    );
                  }).toList(),
                ),
              ),
            );
          },
        );
      },
    );

    if (selected == null || selected == currentCode) {
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final onboarding = Map<String, dynamic>.from(profile.onboarding ?? {});
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

  String _resolveLanguage(UserProfile profile) {
    final onboarding = profile.onboarding;
    if (onboarding == null) {
      return 'en';
    }
    final value = onboarding['language'];
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'en';
  }

  bool _readNotificationsPreference(UserProfile profile) {
    final onboarding = profile.onboarding;
    if (onboarding == null) {
      return false;
    }
    final value = onboarding['notifications_enabled'];
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final normalized = value.toLowerCase();
      return normalized == 'true' || normalized == '1';
    }
    return false;
  }

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  Widget _buildEditableField(
    AppColorScheme colorScheme,
    String label,
    String value,
    VoidCallback onEdit,
  ) {
    final isEmpty = value.isEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: colorScheme.inputBackground,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colorScheme.cardBorder),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isEmpty ? 'Not set' : value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isEmpty
                            ? colorScheme.onSurface.withOpacity(0.35)
                            : colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit_outlined, color: colorScheme.onSurface.withOpacity(0.4), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuTile({
    required AppColorScheme colorScheme,
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
    Widget? trailing,
    bool isDestructive = false,
  }) {
    final iconBackground = colorScheme.primary.withOpacity(0.12);
    final textColor = isDestructive ? Colors.red.shade600 : colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            color: colorScheme.cardBackground,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: colorScheme.cardBorder.withOpacity(0.7)),
          ),
          child: Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: isDestructive ? Colors.red.shade50 : iconBackground,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(12),
                child: Icon(
                  icon,
                  color: isDestructive ? Colors.red.shade500 : colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: textColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              trailing ?? Icon(
                Icons.chevron_right,
                color: colorScheme.onSurface.withOpacity(0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _tintWithSurface(Color base, Color surface) {
    final hsl = HSLColor.fromColor(base);
    final lightened = hsl.withLightness((hsl.lightness + 0.52).clamp(0.0, 1.0));
    final tinted = Color.alphaBlend(lightened.toColor().withOpacity(0.7), surface);
    return tinted;
  }

  Widget _buildLoginView() {
    return AuthPage(
      onLoginSuccess: (_) => context.read<AuthState>().refreshProfile(),
      showAppBar: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthState>(
      builder: (context, authState, _) {
        if (!authState.isServiceAvailable) {
          return AnimatedBuilder(
            animation: ThemeService(),
            builder: (context, _) {
              final colorScheme = ThemeService().colorScheme;
              return Scaffold(
                backgroundColor: _tintWithSurface(colorScheme.primary, colorScheme.surface),
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 28),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: Text(
                    'Profile',
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Text(
                      'Authentication services are currently unavailable. Please try again later.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                    ),
                  ),
                ),
              );
            },
          );
        }

        return AnimatedBuilder(
          animation: ThemeService(),
          builder: (context, _) {
            final colorScheme = ThemeService().colorScheme;
            final content = authState.isAuthenticated
                ? _buildProfileContent(authState)
                : _buildLoginView();
            return Scaffold(
              backgroundColor: _tintWithSurface(colorScheme.primary, colorScheme.surface),
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: colorScheme.onSurface, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                title: Text(
                  'Profile',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              body: Stack(
                children: [
                  Positioned.fill(child: content),
                  if (_isProcessing)
                    Positioned.fill(
                      child: Container(
                        color: colorScheme.overlay,
                        child: Center(
                          child: CircularProgressIndicator(color: colorScheme.primary),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
