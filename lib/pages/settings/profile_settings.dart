import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
import '../auth/auth_page.dart';
import '../auth/user_survey_page.dart';
// import '../../services/auth_service.dart';
import '../../services/local_db_service.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({Key? key}) : super(key: key);

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  bool _isLoggedIn = false;
  File? _profileImageFile;
  String? _profileImageUrl;
  String? _username;
  String? _email;
  DateTime? _signupDate;
  String? _profession;
  String? _fullName;
  DateTime? _dateOfBirth;
  String? _heardFrom;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  // final _authService = AuthService();
  // final _supabase = Supabase.instance.client;
  final _localDBService = LocalDBService();
  User? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _localDBService.currentUser;
      
      if (currentUser != null) {
        setState(() {
          _isLoggedIn = true;
          _email = currentUser.email;
          _username = currentUser.username;
          _profileImageUrl = currentUser.avatarUrl;
          _profession = currentUser.profession;
          _signupDate = currentUser.createdAt;
          _fullName = currentUser.fullName;
          _dateOfBirth = currentUser.dateOfBirth;
          _userData = currentUser;
          
          // If avatar URL is a local file path, create File object
          if (_profileImageUrl != null && _profileImageUrl!.isNotEmpty) {
            _profileImageFile = File(_profileImageUrl!);
          }
        });
      } else {
        setState(() {
          _isLoggedIn = false;
        });
      }
    } catch (e) {
      print('Error loading user data: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading profile: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        final currentUser = _localDBService.currentUser;
        if (currentUser != null) {
          // Copy the selected image to app documents directory
          final appDir = await getApplicationDocumentsDirectory();
          final fileName = 'profile_${currentUser.id}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final savedImagePath = path.join(appDir.path, fileName);
          
          // Copy the image
          final File imageFile = File(image.path);
          await imageFile.copy(savedImagePath);

          // Update user profile with new image path
          await _localDBService.updateUserProfile(
            userId: currentUser.id,
            avatarUrl: savedImagePath,
          );

          setState(() {
            _profileImageFile = File(savedImagePath);
            _profileImageUrl = savedImagePath;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile image updated'),
              backgroundColor: Color(0xFF8B5CF6),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _localDBService.logout();
      setState(() {
        _isLoggedIn = false;
        _email = null;
        _username = null;
        _profileImageFile = null;
        _profileImageUrl = null;
        _profession = null;
        _signupDate = null;
        _fullName = null;
        _dateOfBirth = null;
        _heardFrom = null;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully signed out')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _handleLoginSuccess(String email) {
    setState(() {
      _email = email;
      _isLoggedIn = true;
    });
    _loadUserData();
  }

  Widget _buildLoggedInView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: _profileImageFile != null
                            ? FileImage(_profileImageFile!)
                            : null,
                        child: (_profileImageFile == null)
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
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _username ?? 'Username',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _email ?? 'Email',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Personal Information'),
          const SizedBox(height: 16),
          _buildEditableField(
            label: 'Full Name',
            value: _userData?.fullName ?? '',
            onEdit: () => _editField('full_name', _userData?.fullName ?? ''),
          ),
          _buildEditableField(
            label: 'Username',
            value: _userData?.username ?? '',
            onEdit: () => _editField('username', _userData?.username ?? ''),
          ),
          _buildEditableField(
            label: 'Bio',
            value: _userData?.bio ?? '',
            onEdit: () => _editField('bio', _userData?.bio ?? ''),
          ),
          _buildEditableField(
            label: 'Date of Birth',
            value: _userData?.dateOfBirth != null ? _formatDate(_userData!.dateOfBirth!.toIso8601String()) : '',
            onEdit: () => _selectDate(context),
          ),
          _buildEditableField(
            label: 'Profession',
            value: _userData?.profession ?? '',
            onEdit: () => _editField('profession', _userData?.profession ?? ''),
          ),
          const SizedBox(height: 32),
          _buildSectionTitle('Account Settings'),
          const SizedBox(height: 16),
          _buildSettingsItem(
            icon: Icons.email_outlined,
            title: 'Change Email',
            onTap: () => _editField('email', _userData?.email ?? ''),
          ),
          _buildSettingsItem(
            icon: Icons.lock_outline,
            title: 'Change Password',
            onTap: _changePassword,
          ),
          _buildSettingsItem(
            icon: Icons.delete_outline,
            title: 'Delete Account',
            onTap: _deleteAccount,
            isDestructive: true,
          ),
          const SizedBox(height: 32),
          Center(
            child: ElevatedButton(
              onPressed: _isLoading ? null : () async {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: Text(
                          'Cancel',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );
              
                if (shouldLogout == true) {
                  setState(() => _isLoading = true);
                  try {
                    await _signOut();
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Logged out successfully'),
                        backgroundColor: Color(0xFF8B5CF6),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error logging out: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  } finally {
                    if (mounted) setState(() => _isLoading = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      strokeWidth: 2,
                    ),
                  )
                : const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Logout',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
            ),
          ),
          const SizedBox(height: 32),
        ],
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

  Widget _buildEditableField({
    required String label,
    required String value,
    required VoidCallback onEdit,
  }) {
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
    required VoidCallback onTap,
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

  void _editField(String field, String value) {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController controller = TextEditingController(text: value);
        return AlertDialog(
          title: Text('Edit ${field.replaceAll('_', ' ').capitalize()}'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter ${field.replaceAll('_', ' ')}',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            maxLines: field == 'bio' ? 3 : 1,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty) {
                  Navigator.pop(context);
                  setState(() => _isLoading = true);
                  
                  try {
                    // Update the profile
                    if (field == 'username') {
                      await _localDBService.updateUserProfile(
                        userId: _localDBService.currentUser!.id,
                        username: controller.text,
                      );
                    } else if (field == 'full_name') {
                      await _localDBService.updateUserProfile(
                        userId: _localDBService.currentUser!.id,
                        fullName: controller.text,
                      );
                    } else if (field == 'profession') {
                      await _localDBService.updateUserProfile(
                        userId: _localDBService.currentUser!.id,
                        profession: controller.text,
                      );
                    } else if (field == 'bio') {
                      await _localDBService.updateUserProfile(
                        userId: _localDBService.currentUser!.id,
                        bio: controller.text,
                      );
                    }
                    
                    if (!mounted) return;
                    setState(() {
                      if (field == 'username') {
                        _username = controller.text;
                      } else if (field == 'full_name') {
                        _fullName = controller.text;
                      } else if (field == 'bio') {
                        // No UI field to update
                      } else if (field == 'profession') {
                        _profession = controller.text;
                      }
                      // Reload user data to ensure all fields are updated
                      _loadUserData();
                      _isLoading = false;
                    });
                    
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Profile updated successfully'),
                        backgroundColor: Color(0xFF8B5CF6),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    setState(() => _isLoading = false);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error updating profile: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
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

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000),
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
    
    if (picked != null && picked != _dateOfBirth) {
      setState(() => _isLoading = true);
      
      try {
        await _localDBService.updateUserProfile(
          userId: _localDBService.currentUser!.id,
          dateOfBirth: picked,
        );
        
        if (!mounted) return;
        setState(() {
          _dateOfBirth = picked;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Date of birth updated successfully'),
            backgroundColor: Color(0xFF8B5CF6),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating date of birth: ${e.toString()}')),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _changePassword() {
    showDialog(
      context: context,
      builder: (context) {
        final TextEditingController currentPasswordController = TextEditingController();
        final TextEditingController newPasswordController = TextEditingController();
        final TextEditingController confirmPasswordController = TextEditingController();
        
        return AlertDialog(
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Current Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  hintText: 'Confirm New Password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newPasswordController.text.isEmpty || 
                    currentPasswordController.text.isEmpty ||
                    confirmPasswordController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill all fields'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                if (newPasswordController.text != confirmPasswordController.text) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('New passwords do not match'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }
                
                Navigator.pop(context);
                setState(() => _isLoading = true);
                
                try {
                  // Change password using the local DB service
                  await _localDBService.changePassword(
                    userId: _localDBService.currentUser!.id,
                    currentPassword: currentPasswordController.text,
                    newPassword: newPasswordController.text,
                  );
                  
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Password changed successfully'),
                      backgroundColor: Color(0xFF8B5CF6),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error changing password: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
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

  void _deleteAccount() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoading = true);
              
              try {
                // Delete user account from local database
                await _localDBService.deleteUser(_localDBService.currentUser!.id);
                
                setState(() {
                  _isLoggedIn = false;
                  _email = null;
                  _username = null;
                  _profileImageFile = null;
                  _profileImageUrl = null;
                  _fullName = null;
                  _dateOfBirth = null;
                  _profession = null;
                });
                
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account deleted successfully')),
                );
              } catch (e) {
                setState(() => _isLoading = false);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting account: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final DateTime dateTime = DateTime.parse(date);
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  void _logout() {
    _signOut();
  }

  Widget _buildLoginView() {
    return AuthPage(
      onLoginSuccess: _handleLoginSuccess,
      showAppBar: false,
    );
  }

  @override
  Widget build(BuildContext context) {
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
          : _isLoggedIn
              ? _buildLoggedInView()
              : _buildLoginView(),
    );
  }
}