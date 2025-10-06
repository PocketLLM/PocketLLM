import { ProficiencyLevel, Question } from '../types/test';

const grammar = (id: number, prompt: string, options: [string, boolean][]): Question => ({
  id: `grammar-${id}`,
  prompt,
  skill: 'grammar',
  level: 'A1',
  options: options.map(([label, correct], index) => ({
    id: `grammar-${id}-${index}`,
    label,
    correct
  }))
});

const listening = (id: number, prompt: string, context: string, options: [string, boolean][]): Question => ({
  id: `listening-${id}`,
  prompt,
  context,
  skill: 'listening',
  level: 'A1',
  options: options.map(([label, correct], index) => ({
    id: `listening-${id}-${index}`,
    label,
    correct
  }))
});

const reading = (id: number, prompt: string, context: string, options: [string, boolean][]): Question => ({
  id: `reading-${id}`,
  prompt,
  context,
  skill: 'reading',
  level: 'A1',
  options: options.map(([label, correct], index) => ({
    id: `reading-${id}-${index}`,
    label,
    correct
  }))
});

const vocabulary = (id: number, prompt: string, options: [string, boolean][]): Question => ({
  id: `vocabulary-${id}`,
  prompt,
  skill: 'vocabulary',
  level: 'A1',
  options: options.map(([label, correct], index) => ({
    id: `vocabulary-${id}-${index}`,
    label,
    correct
  }))
});

const baseQuestions: Question[] = [
  grammar(1, 'Choose the correct verb: "She ___ to school every day."', [
    ['go', false],
    ['goes', true],
    ['gone', false],
    ['going', false]
  ]),
  grammar(2, 'Complete the sentence: "If I ___ more time, I would learn Italian."', [
    ['have', false],
    ['had', true],
    ['will have', false],
    ['am having', false]
  ]),
  vocabulary(1, 'Select the best synonym for "quick".', [
    ['rapid', true],
    ['slow', false],
    ['tired', false],
    ['heavy', false]
  ]),
  vocabulary(2, 'Choose the word that best matches "meticulous".', [
    ['careful', true],
    ['rushed', false],
    ['messy', false],
    ['forgetful', false]
  ]),
  reading(
    1,
    'What is the main reason Tom enjoys Saturdays?',
    'Tom loves Saturdays because he can visit his grandmother. She always bakes fresh bread and tells stories from her childhood.',
    [
      ['He likes staying at home.', false],
      ['He visits his grandmother.', true],
      ['He has football practice.', false],
      ['He goes to work.', false]
    ]
  ),
  reading(
    2,
    'What inspired Maya to change careers?',
    'After ten years in finance, Maya attended a linguistics workshop while traveling in Kyoto. Hearing scholars discuss endangered languages rekindled her childhood fascination with storytelling.',
    [
      ['A promotion at work.', false],
      ['A workshop she attended abroad.', true],
      ['Advice from her manager.', false],
      ['Financial incentives.', false]
    ]
  ),
  listening(
    1,
    'After hearing the announcement, what should passengers do?',
    'Attention passengers: the 10:30 service to Bristol now departs from platform 6. Please have your tickets ready for inspection.',
    [
      ['Remain on platform 4.', false],
      ['Move to platform 6.', true],
      ['Buy a ticket at the counter.', false],
      ['Cancel their trip.', false]
    ]
  ),
  listening(
    2,
    'What does the speaker want colleagues to prepare?',
    'Hi team, tomorrow’s client demo starts at 9 a.m. sharp. Please upload your language assessment slides tonight so I can combine them before the meeting.',
    [
      ['Travel itineraries.', false],
      ['Assessment slide decks.', true],
      ['Expense reports.', false],
      ['Meeting minutes.', false]
    ]
  )
];

const adaptQuestion = (question: Question, level: ProficiencyLevel, index: number): Question => ({
  ...question,
  id: `${question.skill}-${level}-${index}`,
  level,
  options: question.options.map((option, optionIndex) => ({
    ...option,
    id: `${question.skill}-${level}-${index}-${optionIndex}`
  }))
});

const LEVEL_DIFFICULTY: Record<ProficiencyLevel, number> = {
  A1: 0,
  A2: 1,
  B1: 2,
  B2: 3,
  C1: 4,
  C2: 5
};

export const QUESTION_BANK: Record<ProficiencyLevel, Question[]> = Object.entries(LEVEL_DIFFICULTY).reduce(
  (accumulator, [levelKey, difficulty]) => {
    const level = levelKey as ProficiencyLevel;
    const variants = baseQuestions.map((question, index) => {
      const adjustedPrompt = `${question.prompt} (${level})`;
      const adjustedContext = question.context
        ? `${question.context}\n\nLevel cue: focus on ${level}.`
        : undefined;

      return adaptQuestion(
        {
          ...question,
          prompt: adjustedPrompt,
          context: adjustedContext,
          options: question.options.map((option) => ({
            ...option,
            label: difficulty > 2 ? option.label : option.label
          }))
        },
        level,
        index
      );
    });

    return {
      ...accumulator,
      [level]: variants
    };
  },
  {} as Record<ProficiencyLevel, Question[]>
);

export const SUPPORTED_LEVELS: ProficiencyLevel[] = Object.keys(QUESTION_BANK) as ProficiencyLevel[];
