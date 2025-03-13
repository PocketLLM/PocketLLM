import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/auth_service.dart';
import '../../pages/settings/profile_settings.dart';
import 'dart:math' as math;
import 'dart:io';

class UserSurveyPage extends StatefulWidget {
  final String userId;
  final VoidCallback onComplete;

  const UserSurveyPage({
    super.key,
    required this.userId,
    required this.onComplete,
  });

  @override
  State<UserSurveyPage> createState() => _UserSurveyPageState();
}

class _UserSurveyPageState extends State<UserSurveyPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedProfession;
  String? _selectedSource;
  bool _isSubmitting = false;
  String? _errorMessage;
  final _supabase = Supabase.instance.client;
  final _authService = AuthService();
  File? _profileImage;
  String? _selectedAvatar;
  double _progressValue = 0.0;

  AnimationController? _controller;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  bool _isControllerInitialized = false;

  final List<String> _professions = [
    'Student',
    'Developer',
    'Designer',
    'Product Manager',
    'Data Scientist',
    'Researcher',
    'Educator',
    'Other'
  ];

  final List<String> _sources = [
    'Search Engine',
    'Social Media',
    'Friend/Colleague',
    'Advertisement',
    'App Store',
    'Other'
  ];

  final List<String> _avatarOptions = [
    'assets/avatar1.jpg',
    'assets/avatar2.jpg',
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _selectedAvatar = _avatarOptions[random.nextInt(_avatarOptions.length)];
    _updateProgress();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller!, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
    setState(() {
      _isControllerInitialized = true;
    });
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    double progress = 0.0;
    if (_nameController.text.isNotEmpty) progress += 0.166;
    if (_usernameController.text.isNotEmpty) progress += 0.166;
    if (_selectedDate != null) progress += 0.166;
    if (_selectedProfession != null) progress += 0.166;
    if (_selectedSource != null) progress += 0.166;
    if (_profileImage != null || _selectedAvatar != null) progress += 0.166;

    setState(() {
      _progressValue = progress.clamp(0.0, 1.0);
    });
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxHeight: 400,
        maxWidth: 400,
      );

      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _selectedAvatar = null;
          _updateProgress();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF6D28D9),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _updateProgress();
      });
    }
  }

  Future<void> _saveProfileAndComplete() async {
    if (_formKey.currentState!.validate()) {
      try {
        if (!mounted) return;
        setState(() {
          _isSubmitting = true;
          _errorMessage = null;
        });

        String? avatarUrl = _selectedAvatar;
        if (_profileImage != null) {
          final String path = 'avatars/${widget.userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await _supabase.storage.from('avatars').upload(path, _profileImage!);
          avatarUrl = _supabase.storage.from('avatars').getPublicUrl(path);
        }

        await _authService.updateUserProfile(
          userId: widget.userId,
          fullName: _nameController.text,
          username: _usernameController.text,
          bio: _bioController.text,
          dateOfBirth: _selectedDate,
          profession: _selectedProfession,
          heardFrom: _selectedSource,
          avatarUrl: avatarUrl,
          surveyCompleted: true,
        );

        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile completed successfully!'),
            backgroundColor: Color(0xFF6D28D9),
          ),
        );

        // Navigate to ProfileSettingsPage after successful submission
        if (mounted) {
          // Ensure we're still mounted before starting the delay
          Future.delayed(const Duration(seconds: 1)).then((_) {
            // Check again if we're still mounted after the delay
            if (mounted) {
              // First navigate to ProfileSettingsPage
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const ProfileSettingsPage()),
              );
              // Then call the onComplete callback
              widget.onComplete();
            }
          });
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Error saving profile: ${e.toString()}';
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_errorMessage ?? 'An error occurred'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.grey[50],
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
            onPressed: () => {}, // Disabled since this is a required survey
          ),
          title: const Text(
            'Profile Setup',
            style: TextStyle(
              color: Colors.black,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _progressValue,
                      backgroundColor: Colors.grey[300],
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6D28D9)),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(_progressValue * 100).toInt()}% Complete',
                      style: const TextStyle(color: Color(0xFF6D28D9), fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: _isControllerInitialized && _controller != null
                      ? AnimatedBuilder(
                          animation: _controller!,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation!.value,
                              child: Transform.translate(
                                offset: _slideAnimation!.value,
                                child: child,
                              ),
                            );
                          },
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Center(
                                  child: Stack(
                                    alignment: Alignment.bottomRight,
                                    children: [
                                      CircleAvatar(
                                        radius: 50,
                                        backgroundImage: _profileImage != null
                                            ? FileImage(_profileImage!)
                                            : _selectedAvatar != null
                                                ? AssetImage(_selectedAvatar!)
                                                : null,
                                        child: _profileImage == null && _selectedAvatar == null
                                            ? const Icon(Icons.person, size: 50)
                                            : null,
                                      ),
                                      GestureDetector(
                                        onTap: _pickImage,
                                        child: Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: Color(0xFF6D28D9),
                                          ),
                                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 20),
                                TextFormField(
                                  controller: _nameController,
                                  decoration: _buildInputDecoration('Full Name'),
                                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                                  onChanged: (_) => _updateProgress(),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: _buildInputDecoration('Username'),
                                  validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                                  onChanged: (_) => _updateProgress(),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _bioController,
                                  maxLines: 3,
                                  decoration: _buildInputDecoration('Bio'),
                                  onChanged: (_) => _updateProgress(),
                                ),
                                const SizedBox(height: 16),
                                InkWell(
                                  onTap: () => _selectDate(context),
                                  child: InputDecorator(
                                    decoration: _buildInputDecoration('Date of Birth'),
                                    child: Text(
                                      _selectedDate == null
                                          ? 'Select date'
                                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedProfession,
                                  decoration: _buildInputDecoration('Profession'),
                                  items: _professions.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedProfession = newValue;
                                      _updateProgress();
                                    });
                                  },
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedSource,
                                  decoration: _buildInputDecoration('How did you hear about us?'),
                                  items: _sources.map((String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedSource = newValue;
                                      _updateProgress();
                                    });
                                  },
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton(
                                  onPressed: _isSubmitting ? null : _saveProfileAndComplete,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6D28D9),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: _isSubmitting
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('Submit'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : const Center(child: CircularProgressIndicator()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}