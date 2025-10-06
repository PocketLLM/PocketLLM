export type Skill = 'grammar' | 'listening' | 'reading' | 'vocabulary';

export type ProficiencyLevel = 'A1' | 'A2' | 'B1' | 'B2' | 'C1' | 'C2';

export interface AnswerOption {
  id: string;
  label: string;
  correct: boolean;
}

export interface Question {
  id: string;
  prompt: string;
  context?: string;
  skill: Skill;
  level: ProficiencyLevel;
  options: AnswerOption[];
}

export interface TestConfiguration {
  candidateName: string;
  targetLevel: ProficiencyLevel;
  questionsPerSkill: number;
  timed: boolean;
}

export interface Response {
  questionId: string;
  selectedOptionId: string;
  correct: boolean;
  timestamp: number;
}

export interface SectionScore {
  skill: Skill;
  total: number;
  correct: number;
}

export interface TestResult {
  accuracy: number;
  sections: SectionScore[];
  recommendedFocus: Skill[];
}

export type SessionStatus = 'idle' | 'running' | 'complete';
