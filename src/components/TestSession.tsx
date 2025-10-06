'use client';

import { Question, Response, TestConfiguration } from '../types/test';
import { SessionOverviewCard } from './SessionOverviewCard';

interface ProgressState {
  index: number;
  total: number;
  answered: number;
  remaining: number;
  percent: number;
}

interface TestSessionProps {
  config: TestConfiguration;
  question: Question | null;
  progress: ProgressState;
  responses: Response[];
  elapsedSeconds: number;
  onSubmit: (optionId: string) => void;
  onCancel: () => void;
}

const formatDuration = (seconds: number): string => {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
};

export function TestSession({
  config,
  question,
  progress,
  responses,
  elapsedSeconds,
  onSubmit,
  onCancel
}: TestSessionProps) {
  const currentResponse = question
    ? responses.find((entry) => entry.questionId === question.id)
    : undefined;

  return (
    <div className="grid" style={{ gap: '2rem' }}>
      <SessionOverviewCard
        config={config}
        progressLabel={`Question ${Math.min(progress.index + 1, progress.total)} of ${progress.total} · ${formatDuration(
          elapsedSeconds
        )}`}
      />

      <section className="section-card">
        <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1.25rem' }}>
          <div>
            <p style={{ margin: 0, color: 'var(--muted-foreground)', fontWeight: 600 }}>Active prompt</p>
            <h2 style={{ margin: '0.35rem 0 0' }}>
              {question ? question.prompt : 'Preparing next question…'}
            </h2>
          </div>
          <div className="progress-bar" aria-hidden>
            <span style={{ width: `${progress.percent}%` }} />
          </div>
        </header>

        {question?.context ? (
          <article
            style={{
              background: 'rgba(148, 163, 184, 0.12)',
              borderRadius: '14px',
              padding: '1rem',
              marginBottom: '1.5rem'
            }}
          >
            <p style={{ margin: 0, whiteSpace: 'pre-line' }}>{question.context}</p>
          </article>
        ) : null}

        <div className="question-options">
          {question?.options.map((option) => {
            const isSelected = currentResponse?.selectedOptionId === option.id;
            return (
              <button
                key={option.id}
                type="button"
                className={`question-option ${isSelected ? 'selected' : ''}`}
                onClick={() => onSubmit(option.id)}
              >
                {option.label}
              </button>
            );
          })}
        </div>

        <footer className="session-footer">
          <div>
            <p style={{ margin: 0, fontWeight: 600 }}>Answered</p>
            <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>
              {progress.answered} of {progress.total}
            </p>
          </div>
          <div>
            <p style={{ margin: 0, fontWeight: 600 }}>Remaining</p>
            <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>{progress.remaining}</p>
          </div>
          <div style={{ textAlign: 'right' }}>
            <button className="secondary" type="button" onClick={onCancel}>
              End session
            </button>
          </div>
        </footer>
      </section>
    </div>
  );
}
