'use client';

import { TestConfiguration, TestResult } from '../types/test';
import { SessionOverviewCard } from './SessionOverviewCard';

interface ResultsSummaryProps {
  config: TestConfiguration;
  results: TestResult;
  elapsedSeconds: number;
  onRestart: () => void;
}

const formatDuration = (seconds: number): string => {
  const mins = Math.floor(seconds / 60);
  const secs = seconds % 60;
  return `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;
};

export function ResultsSummary({ config, results, elapsedSeconds, onRestart }: ResultsSummaryProps) {
  return (
    <div className="grid" style={{ gap: '2rem' }}>
      <SessionOverviewCard
        config={config}
        progressLabel={`Completed in ${formatDuration(elapsedSeconds)} · Accuracy ${results.accuracy}%`}
      />

      <section className="section-card">
        <header style={{ marginBottom: '1.5rem' }}>
          <p style={{ margin: 0, color: 'var(--muted-foreground)', fontWeight: 600 }}>Performance summary</p>
          <h2 style={{ margin: '0.35rem 0 0' }}>Great work! Here are the insights for {config.candidateName}.</h2>
        </header>

        <div className="grid columns-2">
          {results.sections.map((section) => {
            const successRate = Math.round((section.correct / Math.max(section.total, 1)) * 100);
            return (
              <article key={section.skill} style={{ padding: '1rem 1.25rem', borderRadius: '16px', border: '1px solid rgba(148, 163, 184, 0.35)' }}>
                <h3 style={{ margin: 0, textTransform: 'capitalize' }}>{section.skill}</h3>
                <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>
                  {section.correct} of {section.total} correct · {successRate}%
                </p>
              </article>
            );
          })}
        </div>

        <div style={{ marginTop: '2rem' }}>
          <h3 style={{ marginBottom: '0.5rem' }}>Recommended focus areas</h3>
          {results.recommendedFocus.length === 0 ? (
            <p style={{ margin: 0, color: 'var(--muted-foreground)' }}>All skills met the target thresholds. Consider moving to a higher CEFR level.</p>
          ) : (
            <ul style={{ margin: 0, paddingLeft: '1rem', color: 'var(--muted-foreground)' }}>
              {results.recommendedFocus.map((skill) => (
                <li key={skill} style={{ textTransform: 'capitalize' }}>
                  {skill} · schedule targeted drills and review recent mistakes.
                </li>
              ))}
            </ul>
          )}
        </div>

        <footer className="session-footer">
          <div>
            <p style={{ margin: 0, fontWeight: 600 }}>Overall accuracy</p>
            <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>{results.accuracy}%</p>
          </div>
          <div>
            <p style={{ margin: 0, fontWeight: 600 }}>Total duration</p>
            <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>{formatDuration(elapsedSeconds)}</p>
          </div>
          <div style={{ textAlign: 'right' }}>
            <button className="primary" type="button" onClick={onRestart}>
              Start new assessment
            </button>
          </div>
        </footer>
      </section>
    </div>
  );
}
