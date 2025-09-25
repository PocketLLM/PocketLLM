import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../auth/auth_page.dart';
import '../../models/user_profile.dart';
import '../../services/auth_state.dart';

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

  Widget _buildPendingDeletionCard(AuthState authState, UserProfile profile) {
    return Container(
      key: const ValueKey('pending-deletion-card'),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account scheduled for deletion',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 4),
          Text(
            'Your account will be removed on ${_formatDateDisplay(profile.deletionScheduledFor)} unless you cancel.',
            style: const TextStyle(color: Colors.orange),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _isProcessing ? null : () => _cancelDeletion(authState),
              icon: const Icon(Icons.restore, size: 18),
              label: const Text('Cancel deletion'),
            ),
          ),
        ],
      ),
    );
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

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxContentWidth = constraints.maxWidth > 860 ? 860.0 : constraints.maxWidth;
        return Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Column(
                      children: [
                        GestureDetector(
                          onTap: _isProcessing ? null : () => _pickImage(authState),
                          child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: avatarProvider,
                        child: avatarProvider == null
                            ? const Icon(Icons.person, size: 60, color: Colors.grey)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFF8B5CF6), shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                        Text(profile.username ?? 'Username', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                        Text(profile.email, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                        const SizedBox(height: 12),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 280),
                          child: profile.hasPendingDeletion
                              ? _buildPendingDeletionCard(authState, profile)
                              : const SizedBox.shrink(key: ValueKey('no-deletion-card')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Personal Information'),
          const SizedBox(height: 16),
          _buildEditableField('Full Name', profile.fullName ?? '', () => _updateField(authState, 'full_name', profile.fullName ?? '')),
          _buildEditableField('Username', profile.username ?? '', () => _updateField(authState, 'username', profile.username ?? '')),
          _buildEditableField('Bio', profile.bio ?? '', () => _updateField(authState, 'bio', profile.bio ?? '')),
          _buildEditableField(
            'Date of Birth',
            _formatDateDisplay(profile.dateOfBirth),
            () => _selectDate(authState),
          ),
          _buildEditableField('Profession', profile.profession ?? '', () => _updateField(authState, 'profession', profile.profession ?? '')),
          _buildEditableField('How you heard about us', profile.heardFrom ?? '', () => _updateField(authState, 'heard_from', profile.heardFrom ?? '')),
          const SizedBox(height: 32),
          _buildSectionTitle('Account Settings'),
          const SizedBox(height: 16),
          _buildSettingsItem(Icons.lock_outline, 'Change Password', () => _changePassword(authState)),
          _buildSettingsItem(Icons.delete_outline, 'Delete Account', () => _handleDeleteAccount(authState), isDestructive: true),
          const SizedBox(height: 32),
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : () => _handleSignOut(authState),
                      icon: const Icon(Icons.logout),
                      label: const Text('Logout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)),
    );
  }

  String _formatDateDisplay(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    return '${local.month}/${local.day}/${local.year}';
  }

  Widget _buildEditableField(String label, String value, VoidCallback onEdit) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200] ?? Colors.grey),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    const SizedBox(height: 4),
                    Text(
                      value.isNotEmpty ? value : 'Not set',
                      style: TextStyle(fontSize: 16, color: value.isNotEmpty ? Colors.black : Colors.grey[400]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.edit, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap, {bool isDestructive = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[200] ?? Colors.grey),
          ),
          child: Row(
            children: [
              Icon(icon, color: isDestructive ? Colors.red : Colors.grey[700], size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontSize: 16, color: isDestructive ? Colors.red : Colors.black),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
            ],
          ),
        ),
      ),
    );
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
          return Scaffold(
            appBar: AppBar(
              backgroundColor: Colors.grey[50],
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
              title: const Text('Profile', style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold)),
            ),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'Authentication services are currently unavailable. Please try again later.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            backgroundColor: Colors.grey[50],
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
              onPressed: () => Navigator.pop(context),
            ),
            title: const Text(
              'Profile',
              style: TextStyle(color: Colors.black, fontSize: 32, fontWeight: FontWeight.bold),
            ),
          ),
          body: _isProcessing
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
              : authState.isAuthenticated
                  ? _buildProfileContent(authState)
                  : _buildLoginView(),
        );
      },
    );
  }
}
