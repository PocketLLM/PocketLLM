/// File Overview:
/// - Purpose: Data models representing onboarding survey questions, options,
///   and responses.
/// - Backend Migration: Keep but ensure schema mirrors backend survey payloads.
import 'package:equatable/equatable.dart';

class SurveyQuestion extends Equatable {
  final String id;
  final String title;
  final String? subtitle;
  final List<SurveyOption> options;
  final bool isMultiSelect;

  const SurveyQuestion({
    required this.id,
    required this.title,
    this.subtitle,
    required this.options,
    this.isMultiSelect = false,
  });

  @override
  List<Object?> get props => [id, title, subtitle, options, isMultiSelect];
}

class SurveyOption extends Equatable {
  final String id;
  final String label;

  const SurveyOption({
    required this.id,
    required this.label,
  });

  @override
  List<Object?> get props => [id, label];
}

class SurveyResponse extends Equatable {
  final Map<String, dynamic> answers;

  const SurveyResponse({
    required this.answers,
  });

  SurveyResponse copyWithAnswer(String questionId, dynamic value) {
    final updated = Map<String, dynamic>.from(answers)..[questionId] = value;
    return SurveyResponse(answers: updated);
  }

  bool get isEmpty => answers.isEmpty;

  Map<String, dynamic> toJson() => Map<String, dynamic>.from(answers);

  @override
  List<Object?> get props => [answers];
}
