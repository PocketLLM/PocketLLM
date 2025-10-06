import { describe, expect, it } from 'vitest';
import { evaluateTest } from '../lib/evaluation';
import { Question, Response } from '../types/test';

const sampleQuestions: Question[] = [
  {
    id: 'grammar-1',
    prompt: 'Test grammar',
    skill: 'grammar',
    level: 'B1',
    options: [
      { id: 'grammar-1-a', label: 'A', correct: true },
      { id: 'grammar-1-b', label: 'B', correct: false }
    ]
  },
  {
    id: 'listening-1',
    prompt: 'Test listening',
    skill: 'listening',
    level: 'B1',
    options: [
      { id: 'listening-1-a', label: 'A', correct: false },
      { id: 'listening-1-b', label: 'B', correct: true }
    ]
  },
  {
    id: 'reading-1',
    prompt: 'Test reading',
    skill: 'reading',
    level: 'B1',
    options: [
      { id: 'reading-1-a', label: 'A', correct: false },
      { id: 'reading-1-b', label: 'B', correct: true }
    ]
  }
];

describe('evaluation utilities', () => {
  it('calculates accuracy and section scores', () => {
    const responses: Response[] = [
      { questionId: 'grammar-1', selectedOptionId: 'grammar-1-a', correct: true, timestamp: Date.now() },
      { questionId: 'listening-1', selectedOptionId: 'listening-1-a', correct: false, timestamp: Date.now() },
      { questionId: 'reading-1', selectedOptionId: 'reading-1-b', correct: true, timestamp: Date.now() }
    ];

    const result = evaluateTest(sampleQuestions, responses);

    expect(result.accuracy).toBe(67);
    expect(result.sections).toHaveLength(3);
    expect(result.sections.find((section) => section.skill === 'grammar')?.correct).toBe(1);
    expect(result.sections.find((section) => section.skill === 'listening')?.correct).toBe(0);
  });

  it('suggests focus areas when thresholds are missed', () => {
    const responses: Response[] = [
      { questionId: 'grammar-1', selectedOptionId: 'grammar-1-b', correct: false, timestamp: Date.now() },
      { questionId: 'listening-1', selectedOptionId: 'listening-1-a', correct: false, timestamp: Date.now() },
      { questionId: 'reading-1', selectedOptionId: 'reading-1-a', correct: false, timestamp: Date.now() }
    ];

    const result = evaluateTest(sampleQuestions, responses);
    expect(result.recommendedFocus).toContain('grammar');
    expect(result.recommendedFocus).toContain('listening');
    expect(result.recommendedFocus).toContain('reading');
  });
});
