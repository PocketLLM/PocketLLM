'use client';

import { useCallback, useMemo, useState } from 'react';
import { QUESTION_BANK } from '../data/questionBank';
import { evaluateTest } from '../lib/evaluation';
import {
  ProficiencyLevel,
  Question,
  Response,
  SessionStatus,
  TestConfiguration,
  TestResult
} from '../types/test';

const cloneQuestion = (question: Question, seed: string): Question => ({
  ...question,
  id: `${question.id}-${seed}`,
  options: question.options.map((option, index) => ({
    ...option,
    id: `${question.id}-${seed}-${index}`
  }))
});

const buildQuestionPool = (level: ProficiencyLevel, questionsPerSkill: number): Question[] => {
  const bank = QUESTION_BANK[level] ?? [];
  if (bank.length === 0) {
    return [];
  }
  const grouped = bank.reduce<Record<string, Question[]>>((accumulator, question) => {
    if (!accumulator[question.skill]) {
      accumulator[question.skill] = [];
    }

    accumulator[question.skill].push(question);
    return accumulator;
  }, {});

  const skills = Object.keys(grouped);
  const pool: Question[] = [];

  for (let iteration = 0; iteration < questionsPerSkill; iteration += 1) {
    skills.forEach((skill) => {
      const questionSet = grouped[skill];
      const baseQuestion = questionSet[iteration % questionSet.length];
      pool.push(cloneQuestion(baseQuestion, `${iteration}`));
    });
  }

  return pool;
};

export interface UseTestSessionReturn {
  status: SessionStatus;
  config: TestConfiguration | null;
  question: Question | null;
  questions: Question[];
  progress: {
    index: number;
    total: number;
    answered: number;
    remaining: number;
    percent: number;
  };
  responses: Response[];
  results: TestResult | null;
  elapsedSeconds: number;
  startSession: (config: TestConfiguration) => void;
  submitAnswer: (optionId: string) => void;
  resetSession: () => void;
}

export const useTestSession = (): UseTestSessionReturn => {
  const [status, setStatus] = useState<SessionStatus>('idle');
  const [config, setConfig] = useState<TestConfiguration | null>(null);
  const [questions, setQuestions] = useState<Question[]>([]);
  const [currentIndex, setCurrentIndex] = useState(0);
  const [responses, setResponses] = useState<Response[]>([]);
  const [results, setResults] = useState<TestResult | null>(null);
  const [startedAt, setStartedAt] = useState<number | null>(null);
  const [completedAt, setCompletedAt] = useState<number | null>(null);

  const question = useMemo(() => {
    if (status !== 'running') {
      return null;
    }

    return questions[currentIndex] ?? null;
  }, [questions, currentIndex, status]);

  const progress = useMemo(() => {
    const total = questions.length;
    const answered = responses.length;
    const percent = total === 0 ? 0 : Math.min(100, Math.round((answered / total) * 100));
    return {
      index: currentIndex,
      total,
      answered,
      remaining: Math.max(total - answered, 0),
      percent
    };
  }, [questions.length, responses.length, currentIndex]);

  const elapsedSeconds = useMemo(() => {
    if (!startedAt) {
      return 0;
    }

    const end = completedAt ?? Date.now();
    return Math.round((end - startedAt) / 1000);
  }, [startedAt, completedAt]);

  const startSession = useCallback((configuration: TestConfiguration) => {
    const pool = buildQuestionPool(configuration.targetLevel, configuration.questionsPerSkill);
    if (pool.length === 0) {
      console.warn('No questions available for the selected configuration');
      return;
    }

    setConfig(configuration);
    setQuestions(pool);
    setCurrentIndex(0);
    setResponses([]);
    setResults(null);
    setStatus('running');
    setStartedAt(Date.now());
    setCompletedAt(null);
  }, []);

  const resetSession = useCallback(() => {
    setStatus('idle');
    setConfig(null);
    setQuestions([]);
    setResponses([]);
    setResults(null);
    setCurrentIndex(0);
    setStartedAt(null);
    setCompletedAt(null);
  }, []);

  const submitAnswer = useCallback(
    (optionId: string) => {
      if (status !== 'running') {
        return;
      }

      const activeQuestion = questions[currentIndex];
      if (!activeQuestion) {
        return;
      }

      const option = activeQuestion.options.find((candidate) => candidate.id === optionId);
      if (!option) {
        return;
      }

      const response: Response = {
        questionId: activeQuestion.id,
        selectedOptionId: option.id,
        correct: option.correct,
        timestamp: Date.now()
      };

      setResponses((previous) => {
        const filtered = previous.filter((entry) => entry.questionId !== response.questionId);
        const updated = [...filtered, response];

        const isLastQuestion = currentIndex === questions.length - 1;
        if (isLastQuestion) {
          const evaluation = evaluateTest(questions, updated);
          setResults(evaluation);
          setStatus('complete');
          setCompletedAt(Date.now());
        } else {
          setCurrentIndex((index) => Math.min(index + 1, questions.length - 1));
        }

        return updated;
      });
    },
    [status, questions, currentIndex]
  );

  return {
    status,
    config,
    question,
    questions,
    progress,
    responses,
    results,
    elapsedSeconds,
    startSession,
    submitAnswer,
    resetSession
  };
};
