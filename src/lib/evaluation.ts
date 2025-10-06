import { Question, Response, SectionScore, Skill, TestResult } from '../types/test';

const SCORE_THRESHOLDS: Record<Skill, number> = {
  grammar: 75,
  listening: 70,
  reading: 72,
  vocabulary: 78
};

export const calculateSectionScores = (questions: Question[], responses: Response[]): SectionScore[] => {
  const grouped = new Map<Skill, SectionScore>();

  questions.forEach((question) => {
    if (!grouped.has(question.skill)) {
      grouped.set(question.skill, {
        skill: question.skill,
        total: 0,
        correct: 0
      });
    }

    const section = grouped.get(question.skill)!;
    section.total += 1;

    const response = responses.find((entry) => entry.questionId === question.id);
    if (response?.correct) {
      section.correct += 1;
    }
  });

  return Array.from(grouped.values()).sort((a, b) => a.skill.localeCompare(b.skill));
};

export const calculateAccuracy = (sections: SectionScore[]): number => {
  const totals = sections.reduce(
    (accumulator, section) => {
      return {
        correct: accumulator.correct + section.correct,
        total: accumulator.total + section.total
      };
    },
    { correct: 0, total: 0 }
  );

  if (totals.total === 0) {
    return 0;
  }

  return Math.round((totals.correct / totals.total) * 100);
};

export const recommendFocusAreas = (sections: SectionScore[]): Skill[] => {
  return sections
    .filter((section) => {
      const threshold = SCORE_THRESHOLDS[section.skill];
      const achieved = (section.correct / Math.max(section.total, 1)) * 100;
      return achieved < threshold;
    })
    .map((section) => section.skill);
};

export const evaluateTest = (questions: Question[], responses: Response[]): TestResult => {
  const sections = calculateSectionScores(questions, responses);
  return {
    accuracy: calculateAccuracy(sections),
    sections,
    recommendedFocus: recommendFocusAreas(sections)
  };
};
