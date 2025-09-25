import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../services/auth_state.dart';

class UserSurveyPage extends StatefulWidget {
  final VoidCallback onComplete;

  const UserSurveyPage({
    super.key,
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
  final _primaryGoalController = TextEditingController();
  final _otherNotesController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedProfession;
  String? _selectedSource;
  String? _experienceLevel;
  String? _usageFrequency;
  File? _profileImage;
  String? _selectedAvatar;
  final Set<String> _selectedInterests = <String>{};
  bool _isSubmitting = false;
  String? _errorMessage;
  double _progressValue = 0.0;

  AnimationController? _controller;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

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

  final List<String> _experienceLevels = [
    'Beginner',
    'Intermediate',
    'Advanced',
    'Expert'
  ];

  final List<String> _usageFrequencyOptions = [
    'Multiple times a day',
    'Daily',
    'A few times a week',
    'Weekly',
    'Occasionally'
  ];

  final List<String> _interestOptions = [
    'Productivity',
    'Coding',
    'Design',
    'Research',
    'Writing',
    'Learning',
    'Business',
    'Creative Projects'
  ];

  @override
  void initState() {
    super.initState();
    final random = math.Random();
    _selectedAvatar = _avatarOptions[random.nextInt(_avatarOptions.length)];
    _updateProgress();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller!, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0.0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller!, curve: Curves.easeInOut));
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _primaryGoalController.dispose();
    _otherNotesController.dispose();
    super.dispose();
  }

  void _updateProgress() {
    final checks = <bool>[
      _nameController.text.trim().isNotEmpty,
      _usernameController.text.trim().isNotEmpty,
      _selectedDate != null,
      _selectedProfession?.isNotEmpty == true,
      _selectedSource?.isNotEmpty == true,
      _profileImage != null || _selectedAvatar != null,
      _primaryGoalController.text.trim().isNotEmpty,
      _selectedInterests.isNotEmpty,
      _experienceLevel?.isNotEmpty == true,
      _usageFrequency?.isNotEmpty == true,
    ];

    final completed = checks.where((value) => value).length;
    _progressValue = checks.isEmpty ? 0.0 : completed / checks.length;
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, maxHeight: 600, maxWidth: 600);
      if (image != null) {
        setState(() {
          _profileImage = File(image.path);
          _selectedAvatar = null;
          _updateProgress();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error selecting image: $e')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final picked = await showDatePicker(
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

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _updateProgress();
      });
    }
  }

  Future<void> _saveProfileAndComplete() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authState = context.read<AuthState>();
    try {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      String? avatarUrl = _selectedAvatar;
      if (_profileImage != null) {
        try {
          avatarUrl = await authState.uploadProfileImage(_profileImage!);
        } catch (e) {
          avatarUrl = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Unable to upload profile image: $e')),
          );
        }
      }

      final onboarding = {
        'primary_goal': _primaryGoalController.text.trim(),
        'interests': _selectedInterests.toList(),
        'experience_level': _experienceLevel,
        'usage_frequency': _usageFrequency,
        'other_notes': _otherNotesController.text.trim(),
      };

      await authState.completeProfile(
        fullName: _nameController.text.trim(),
        username: _usernameController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        dateOfBirth: _selectedDate,
        profession: _selectedProfession,
        heardFrom: _selectedSource,
        avatarUrl: avatarUrl,
        onboarding: onboarding,
      );

      await authState.refreshProfile();

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile completed successfully!'),
          backgroundColor: Color(0xFF6D28D9),
        ),
      );

      widget.onComplete();
      if (Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error saving profile: $e';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage ?? 'An error occurred'), backgroundColor: Colors.redAccent),
      );
    }
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
          automaticallyImplyLeading: false,
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: _progressValue.clamp(0.0, 1.0),
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
                  child: _controller == null
                      ? const SizedBox.shrink()
                      : AnimatedBuilder(
                          animation: _controller!,
                          builder: (context, child) {
                            return Opacity(
                              opacity: _fadeAnimation?.value ?? 1.0,
                              child: Transform.translate(
                                offset: _slideAnimation?.value ?? Offset.zero,
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
                                            : (_selectedAvatar != null ? AssetImage(_selectedAvatar!) as ImageProvider : null),
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
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                                  onChanged: (_) => setState(_updateProgress),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _usernameController,
                                  decoration: _buildInputDecoration('Username'),
                                  validator: (value) => value == null || value.trim().isEmpty ? 'Required' : null,
                                  onChanged: (_) => setState(_updateProgress),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _bioController,
                                  maxLines: 3,
                                  decoration: _buildInputDecoration('Bio (optional)'),
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
                                  items: _professions
                                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedProfession = newValue;
                                      _updateProgress();
                                    });
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty ? 'Please select a profession' : null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _selectedSource,
                                  decoration: _buildInputDecoration('How did you hear about us?'),
                                  items: _sources
                                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _selectedSource = newValue;
                                      _updateProgress();
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                Text(
                                  'Tell us about your goals',
                                  style:
                                      Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _primaryGoalController,
                                  decoration: _buildInputDecoration('Primary goal for using PocketLLM'),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty ? 'Please share your goal' : null,
                                  onChanged: (_) => setState(_updateProgress),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Which topics interest you?',
                                  style:
                                      Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _interestOptions.map((interest) {
                                    final selected = _selectedInterests.contains(interest);
                                    return FilterChip(
                                      label: Text(interest),
                                      selected: selected,
                                      selectedColor: const Color(0xFF6D28D9).withOpacity(0.15),
                                      checkmarkColor: const Color(0xFF6D28D9),
                                      onSelected: (value) {
                                        setState(() {
                                          if (value) {
                                            _selectedInterests.add(interest);
                                          } else {
                                            _selectedInterests.remove(interest);
                                          }
                                          _updateProgress();
                                        });
                                      },
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _experienceLevel,
                                  decoration: _buildInputDecoration('Experience level with AI tools'),
                                  items: _experienceLevels
                                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _experienceLevel = newValue;
                                      _updateProgress();
                                    });
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty ? 'Please select your experience level' : null,
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _usageFrequency,
                                  decoration:
                                      _buildInputDecoration('How often do you expect to use PocketLLM?'),
                                  items: _usageFrequencyOptions
                                      .map((value) => DropdownMenuItem(value: value, child: Text(value)))
                                      .toList(),
                                  onChanged: (newValue) {
                                    setState(() {
                                      _usageFrequency = newValue;
                                      _updateProgress();
                                    });
                                  },
                                  validator: (value) =>
                                      value == null || value.isEmpty ? 'Please choose a frequency' : null,
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _otherNotesController,
                                  maxLines: 3,
                                  decoration: _buildInputDecoration('Anything else we should know? (optional)'),
                                ),
                                const SizedBox(height: 24),
                                if (_errorMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 12.0),
                                    child: Text(
                                      _errorMessage!,
                                      style: const TextStyle(color: Colors.redAccent),
                                    ),
                                  ),
                                ElevatedButton(
                                  onPressed: _isSubmitting ? null : _saveProfileAndComplete,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6D28D9),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(double.infinity, 50),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: _isSubmitting
                                      ? const CircularProgressIndicator(color: Colors.white)
                                      : const Text('Submit'),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
