import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../component/survey/survey_option_tile.dart';
import '../../component/survey/survey_progress_indicator.dart';
import '../../models/survey_model.dart';
import '../../services/auth_state.dart';
import '../../services/survey_service.dart';

class UserSurveyPage extends StatefulWidget {
  final VoidCallback onComplete;

  const UserSurveyPage({
    super.key,
    required this.onComplete,
  });

  @override
  State<UserSurveyPage> createState() => _UserSurveyPageState();
}

class _UserSurveyPageState extends State<UserSurveyPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _bioController = TextEditingController();
  final List<String> _professions = const [
    'Student',
    'Developer',
    'Designer',
    'Product Manager',
    'Data Scientist',
    'Researcher',
    'Educator',
    'Other',
  ];
  final List<String> _sources = const [
    'Search Engine',
    'Social Media',
    'Friend/Colleague',
    'Advertisement',
    'App Store',
    'Other',
  ];

  late final List<SurveyQuestion> _questions;

  final Map<String, dynamic> _answers = {};
  int _currentStep = 0;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _selectedProfession;
  String? _selectedSource;

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
    _questions = [
      const SurveyQuestion(
        id: 'age_range',
        title: 'Answer some questions about yourself to get started.',
        subtitle: 'What is your age range?',
        options: [
          SurveyOption(id: 'under_18', label: 'Under 18'),
          SurveyOption(id: '18_34', label: '18-34'),
          SurveyOption(id: '35_54', label: '35-54'),
          SurveyOption(id: '55_plus', label: '55 or over'),
        ],
      ),
      const SurveyQuestion(
        id: 'education_level',
        title: 'Answer some questions about yourself to get started.',
        subtitle: 'What is your highest level of education completed?',
        options: [
          SurveyOption(id: 'high_school', label: 'High school or less'),
          SurveyOption(id: 'some_college', label: 'Some college or vocational training'),
          SurveyOption(id: 'bachelors', label: "Bachelor's degree"),
          SurveyOption(id: 'graduate', label: "Graduate degree"),
        ],
      ),
      const SurveyQuestion(
        id: 'gender',
        title: 'Answer some questions about yourself to get started.',
        subtitle: 'What is your gender?',
        options: [
          SurveyOption(id: 'male', label: 'Male'),
          SurveyOption(id: 'female', label: 'Female'),
          SurveyOption(id: 'other', label: 'Rather not say'),
        ],
      ),
      const SurveyQuestion(
        id: 'ethnicity',
        title: 'Answer some questions about yourself to get started.',
        subtitle: 'What is your ethnicity or race?',
        options: [
          SurveyOption(id: 'white', label: 'Caucasian/White'),
          SurveyOption(id: 'black', label: 'African American/Black'),
          SurveyOption(id: 'latinx', label: 'Hispanic/Latinx'),
          SurveyOption(id: 'asian', label: 'Asian/Asian American'),
          SurveyOption(id: 'other', label: 'Other / Prefer not to say'),
        ],
      ),
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    _primaryGoalController.dispose();
    _otherNotesController.dispose();
    super.dispose();
  }

  int get _totalSteps => _questions.length + 1;

  bool get _isProfileStep => _currentStep >= _questions.length;

  void _handleExit() {
    Navigator.of(context).maybePop();
  }

  void _handleBack() {
    if (_currentStep == 0) {
      _handleExit();
      return;
    }
    setState(() {
      _errorMessage = null;
      _currentStep -= 1;
    });
  }

  void _handleNext() {
    if (_isProfileStep) {
      _submit();
      return;
    }

    final question = _questions[_currentStep];
    final answer = _answers[question.id];
    if (answer == null || (answer is List && answer.isEmpty)) {
      setState(() {
        _errorMessage = 'Please select an option to continue.';
      });
      return;
    }

    setState(() {
      _errorMessage = null;
      _currentStep += 1;
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final authState = context.read<AuthState>();
    final surveyService = SurveyService(authState);
    final onboardingAnswers = {
      'age_range': _answers['age_range'],
      'education_level': _answers['education_level'],
      'gender': _answers['gender'],
      'ethnicity': _answers['ethnicity'],
    }..removeWhere((key, value) => value == null);

    try {
      setState(() {
        _isSubmitting = true;
        _errorMessage = null;
      });

      await surveyService.submitSurvey(
        SurveyPayload(
          fullName: _nameController.text.trim(),
          username: _usernameController.text.trim(),
          bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
          profession: _selectedProfession,
          heardFrom: _selectedSource,
          onboarding: onboardingAnswers,
        ),
      );

      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thanks! Your responses have been saved.'),
          backgroundColor: Color(0xFF6D28D9),
        ),
      );

      widget.onComplete();
      if (Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error saving survey: $e';
      });
    }
  }

  Widget _buildQuestionStep(SurveyQuestion question, ThemeData theme) {
    final selectedValue = _answers[question.id];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.title,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (question.subtitle != null)
          Text(
            question.subtitle!,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        const SizedBox(height: 24),
        ...question.options.map(
          (option) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SurveyOptionTile(
              label: option.label,
              selected: selectedValue == option.id,
              onTap: () {
                setState(() {
                  _answers[question.id] = option.id;
                  _errorMessage = null;
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileStep(ThemeData theme) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Complete your profile',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add a few more details so we can personalize your experience.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full name is required';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _usernameController,
            decoration: const InputDecoration(
              labelText: 'Username',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().length < 3) {
                return 'Username must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _bioController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Bio (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedProfession,
            decoration: const InputDecoration(
              labelText: 'Profession',
              border: OutlineInputBorder(),
            ),
            items: _professions
                .map(
                  (profession) => DropdownMenuItem(
                    value: profession,
                    child: Text(profession),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedProfession = value),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedSource,
            decoration: const InputDecoration(
              labelText: 'How did you hear about us?',
              border: OutlineInputBorder(),
            ),
            items: _sources
                .map(
                  (source) => DropdownMenuItem(
                    value: source,
                    child: Text(source),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _selectedSource = value),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        titleSpacing: 16,
        title: SurveyProgressIndicator(
          totalSteps: _totalSteps,
          currentStep: _currentStep,
        ),
        actions: [
          TextButton(
            onPressed: _handleExit,
            child: const Text('Exit'),
          ),
        ],
        leading: _currentStep > 0
            ? TextButton(
                onPressed: _handleBack,
                child: const Text('Back'),
              )
            : null,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0.1, 0.05),
                          end: Offset.zero,
                        ).animate(animation),
                        child: child,
                      ),
                    ),
                    child: Padding(
                      key: ValueKey(_currentStep),
                      padding: const EdgeInsets.only(top: 8),
                      child: _isProfileStep
                          ? _buildProfileStep(theme)
                          : _buildQuestionStep(_questions[_currentStep], theme),
                    ),
                  ),
                ),
              ),
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6D28D9),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(_isProfileStep ? 'Finish' : 'Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
