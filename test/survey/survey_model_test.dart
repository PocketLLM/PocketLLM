import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_llm/models/survey_model.dart';

void main() {
  group('SurveyResponse', () {
    test('copyWithAnswer stores responses immutably', () {
      const original = SurveyResponse(answers: {});
      final updated = original.copyWithAnswer('age_range', '18_34');

      expect(original.answers.containsKey('age_range'), isFalse);
      expect(updated.answers['age_range'], equals('18_34'));
    });

    test('toJson returns a copy of the answers map', () {
      const response = SurveyResponse(answers: {'gender': 'female'});
      final json = response.toJson();

      expect(json, equals({'gender': 'female'}));
      json['gender'] = 'male';
      expect(response.answers['gender'], equals('female'));
    });
  });

  group('SurveyQuestion', () {
    test('equality compares by value', () {
      const questionA = SurveyQuestion(
        id: 'q1',
        title: 'Title',
        options: [SurveyOption(id: 'a', label: 'A')],
      );
      const questionB = SurveyQuestion(
        id: 'q1',
        title: 'Title',
        options: [SurveyOption(id: 'a', label: 'A')],
      );

      expect(questionA, equals(questionB));
    });
  });
}
