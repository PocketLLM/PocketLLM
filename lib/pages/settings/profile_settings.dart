import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_service.dart';
import '../auth/auth_page.dart';

extension StringExtension on String {
  String capitalize() => isEmpty ? this : '${this[0].toUpperCase()}${substring(1)}';
}

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool _isLoading = false;
  File? _localAvatarFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(_refreshProfile);
  }

  Future<void> _refreshProfile() async {
    final authService = context.read<AuthService>();
    setState(() => _isLoading = true);
    await authService.refreshProfile();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  ImageProvider? _resolveAvatar(UserProfile? profile) {
    if (_localAvatarFile != null) {
      return FileImage(_localAvatarFile!);
    }
    final avatarUrl = profile?.avatarUrl;
    if (avatarUrl == null || avatarUrl.isEmpty) {
      return null;
    }
    if (avatarUrl.startsWith('asset:')) {
      return AssetImage(avatarUrl.substring(6));
    }
    if (avatarUrl.startsWith('data:image')) {
      final parts = avatarUrl.split(',');
      if (parts.length == 2) {
        try {
          final bytes = base64Decode(parts.last);
          return MemoryImage(bytes);
        } catch (_) {}
      }
    } else if (avatarUrl.startsWith('http')) {
      return NetworkImage(avatarUrl);
    } else if (File(avatarUrl).existsSync()) {
      return FileImage(File(avatarUrl));
    }
    return null;
  }

  void _showSnack(String message, {Color color = const Color(0xFF8B5CF6)}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  Future<void> _pickImage(UserProfile profile) async {
    final image = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 600, maxHeight: 600);
    if (image == null) return;
    try {
      setState(() => _isLoading = true);
      final file = File(image.path);
      final bytes = await file.readAsBytes();
      final encoded = base64Encode(bytes);
      await context.read<AuthService>().updateProfile(
            avatarUrl: 'data:image/jpeg;base64,$encoded',
          );
      await context.read<AuthService>().refreshProfile();
      setState(() {
        _localAvatarFile = file;
        _isLoading = false;
      });
      _showSnack('Profile image updated');
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
      _showSnack('Error uploading image: $error', color: Colors.red);
    }
  }

  Future<void> _updateProfile({
    String? fullName,
    String? username,
    String? bio,
    DateTime? dateOfBirth,
    String? profession,
  }) async {
    try {
      setState(() => _isLoading = true);
      await context.read<AuthService>().updateProfile(
            fullName: fullName,
            username: username,
            bio: bio,
            dateOfBirth: dateOfBirth,
            profession: profession,
          );
      await context.read<AuthService>().refreshProfile();
      setState(() => _isLoading = false);
      _showSnack('Profile updated successfully');
    } catch (error) {
      if (mounted) setState(() => _isLoading = false);
      _showSnack('Error updating profile: $error', color: Colors.red);
    }
  }

  void _promptForValue({
    required String label,
    required String initialValue,
    required Future<void> Function(String value) onSubmit,
    int maxLines = 1,
  }) {
    final controller = TextEditingController(text: initialValue);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit ${label.capitalize()}'),
          content: TextField(
            controller: controller,
            maxLines: maxLines,
            decoration: InputDecoration(
              hintText: 'Enter ${label.replaceAll('_', ' ')}',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  _showSnack('Value cannot be empty', color: Colors.red);
                  return;
                }
                Navigator.pop(context);
                await onSubmit(controller.text.trim());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(UserProfile profile) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: profile.dateOfBirth ?? DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF8B5CF6),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      await _updateProfile(dateOfBirth: picked);
    }
  }

  Future<void> _changePassword() async {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPasswordField('Current Password', currentController),
              const SizedBox(height: 12),
              _buildPasswordField('New Password', newController),
              const SizedBox(height: 12),
              _buildPasswordField('Confirm New Password', confirmController),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newController.text != confirmController.text) {
                  _showSnack('New passwords do not match', color: Colors.red);
                  return;
                }
                Navigator.pop(context);
                final result = await context.read<AuthService>().changePassword(
                      currentPassword: currentController.text,
                      newPassword: newController.text,
                    );
                _showSnack(
                  result.message ?? (result.success ? 'Password changed' : 'Password change failed'),
                  color: result.success ? const Color(0xFF8B5CF6) : Colors.red,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
              ),
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }

  TextField _buildPasswordField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      obscureText: true,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _requestDeletion() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Your account will be scheduled for deletion in 30 days. '
          'If you sign in during this period the deletion will be cancelled automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Schedule Deletion'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await context.read<AuthService>().requestAccountDeletion();
      await context.read<AuthService>().refreshProfile();
      _showSnack('Account deletion scheduled. We will remove your data in 30 days unless you sign in again.');
      setState(() {});
    }
  }

  Future<void> _cancelDeletion() async {
    await context.read<AuthService>().cancelAccountDeletion();
    await context.read<AuthService>().refreshProfile();
    _showSnack('Deletion request cancelled');
    setState(() {});
  }

  Future<void> _signOut() async {
    setState(() => _isLoading = true);
    await context.read<AuthService>().signOut();
    setState(() {
      _localAvatarFile = null;
      _isLoading = false;
    });
    _showSnack('Signed out');
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Not set';
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatDuration(Duration duration) {
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    if (days > 0) {
      return '$days day${days == 1 ? '' : 's'}${hours > 0 ? ' and $hours hour${hours == 1 ? '' : 's'}' : ''}';
    }
    if (hours > 0) {
      final minutes = duration.inMinutes % 60;
      return '$hours hour${hours == 1 ? '' : 's'}${minutes > 0 ? ' and $minutes minute${minutes == 1 ? '' : 's'}' : ''}';
    }
    final minutes = duration.inMinutes;
    return minutes > 0 ? '$minutes minute${minutes == 1 ? '' : 's'}' : 'less than a minute';
  }

  Widget _buildDeletionBanner(UserProfile profile) {
    if (!profile.hasPendingDeletion) {
      return const SizedBox.shrink();
    }
    final remaining = profile.timeUntilDeletion;
    final remainingText = remaining == null ? 'less than 30 days' : _formatDuration(remaining);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.redAccent),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account deletion scheduled',
            style: TextStyle(
              color: Colors.red[700],
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your account will be permanently deleted in $remainingText.',
            style: TextStyle(color: Colors.red[700]),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _isLoading ? null : _cancelDeletion,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red[700],
              side: BorderSide(color: Colors.red[700] ?? Colors.red),
            ),
            child: const Text('Cancel deletion'),
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: _isLoading ? null : onTap,
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
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value.isNotEmpty ? value : 'Not set',
                      style: TextStyle(
                        fontSize: 16,
                        color: value.isNotEmpty ? Colors.black : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.edit,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    VoidCallback? onTap,
    bool isDestructive = false,
  }) {
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
              Icon(
                icon,
                color: isDestructive ? Colors.red : Colors.grey[700],
                size: 24,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDestructive ? Colors.red : Colors.black,
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoggedInView(UserProfile profile) {
    final avatarImage = _resolveAvatar(profile);

    return RefreshIndicator(
      onRefresh: _refreshProfile,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _isLoading ? null : () => _pickImage(profile),
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Colors.grey[200],
                          backgroundImage: avatarImage,
                          child: avatarImage == null
                              ? const Icon(Icons.person, size: 60, color: Colors.grey)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Color(0xFF8B5CF6),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.fullName ?? profile.username ?? 'Username',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    profile.email ?? 'Email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildDeletionBanner(profile),
            const SizedBox(height: 8),
            _buildSectionTitle('Personal Information'),
            const SizedBox(height: 16),
            _buildEditableField(
              label: 'Full Name',
              value: profile.fullName ?? '',
              onTap: () => _promptForValue(
                label: 'full name',
                initialValue: profile.fullName ?? '',
                onSubmit: (value) => _updateProfile(fullName: value),
              ),
            ),
            _buildEditableField(
              label: 'Username',
              value: profile.username ?? '',
              onTap: () => _promptForValue(
                label: 'username',
                initialValue: profile.username ?? '',
                onSubmit: (value) => _updateProfile(username: value),
              ),
            ),
            _buildEditableField(
              label: 'Bio',
              value: profile.bio ?? '',
              onTap: () => _promptForValue(
                label: 'bio',
                initialValue: profile.bio ?? '',
                maxLines: 3,
                onSubmit: (value) => _updateProfile(bio: value),
              ),
            ),
            _buildEditableField(
              label: 'Date of Birth',
              value: _formatDate(profile.dateOfBirth),
              onTap: () => _selectDate(profile),
            ),
            _buildEditableField(
              label: 'Profession',
              value: profile.profession ?? '',
              onTap: () => _promptForValue(
                label: 'profession',
                initialValue: profile.profession ?? '',
                onSubmit: (value) => _updateProfile(profession: value),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Account Settings'),
            const SizedBox(height: 16),
            _buildSettingsItem(
              icon: Icons.lock_outline,
              title: 'Change Password',
              onTap: _isLoading ? null : _changePassword,
            ),
            _buildSettingsItem(
              icon: Icons.delete_outline,
              title: profile.hasPendingDeletion ? 'Deletion scheduled' : 'Delete Account',
              onTap: _isLoading
                  ? null
                  : (profile.hasPendingDeletion ? _cancelDeletion : _requestDeletion),
              isDestructive: true,
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _signOut,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.logout, size: 20),
                label: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF8B5CF6),
      ),
    );
  }

  Widget _buildLoginView() {
    return AuthPage(
      showAppBar: false,
      allowSkip: false,
      onAuthenticated: (ctx) => _refreshProfile(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = context.watch<AuthService>();
    final profile = authService.currentProfile;

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
          style: TextStyle(
            color: Colors.black,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
          : authService.isAuthenticated && profile != null
              ? _buildLoggedInView(profile)
              : _buildLoginView(),
    );
  }
}
