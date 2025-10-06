'use client';

import { FormEvent, useMemo, useState } from 'react';
import { SUPPORTED_LEVELS } from '../data/questionBank';
import { TestConfiguration } from '../types/test';
import { LevelBadge } from './LevelBadge';

interface TestConfiguratorProps {
  onStart: (config: TestConfiguration) => void;
  disabled?: boolean;
}

const QUESTION_OPTIONS = [1, 2, 3];

export function TestConfigurator({ onStart, disabled = false }: TestConfiguratorProps) {
  const [candidateName, setCandidateName] = useState('');
  const [targetLevel, setTargetLevel] = useState(SUPPORTED_LEVELS[2]);
  const [questionsPerSkill, setQuestionsPerSkill] = useState(2);
  const [timed, setTimed] = useState(true);

  const selectedLevelLabel = useMemo(() => {
    return <LevelBadge level={targetLevel} variant="neutral" />;
  }, [targetLevel]);

  const handleSubmit = (event: FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    if (disabled) {
      return;
    }

    onStart({
      candidateName: candidateName.trim() || 'Candidate',
      targetLevel,
      questionsPerSkill,
      timed
    });
  };

  return (
    <section className="section-card" aria-labelledby="configurator-heading">
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
        <div>
          <h2 id="configurator-heading" style={{ margin: 0 }}>
            Configure a new assessment
          </h2>
          <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>
            Tailor the session to match the learner’s goals and proficiency level.
          </p>
        </div>
        {selectedLevelLabel}
      </header>

      <form onSubmit={handleSubmit} style={{ marginTop: '1.5rem' }}>
        <div className="grid columns-2">
          <fieldset>
            <label htmlFor="candidate">Candidate name</label>
            <input
              id="candidate"
              type="text"
              placeholder="e.g. Alex Morgan"
              value={candidateName}
              onChange={(event) => setCandidateName(event.target.value)}
              required
            />
          </fieldset>

          <fieldset>
            <label htmlFor="level">Target proficiency level</label>
            <select
              id="level"
              value={targetLevel}
              onChange={(event) => setTargetLevel(event.target.value as typeof targetLevel)}
            >
              {SUPPORTED_LEVELS.map((level) => (
                <option key={level} value={level}>
                  CEFR {level}
                </option>
              ))}
            </select>
          </fieldset>

          <fieldset>
            <label htmlFor="questions">Questions per skill</label>
            <select
              id="questions"
              value={questionsPerSkill}
              onChange={(event) => setQuestionsPerSkill(Number(event.target.value))}
            >
              {QUESTION_OPTIONS.map((option) => (
                <option key={option} value={option}>
                  {option} question{option > 1 ? 's' : ''}
                </option>
              ))}
            </select>
          </fieldset>

          <fieldset>
            <label htmlFor="timed">Delivery mode</label>
            <select
              id="timed"
              value={timed ? 'timed' : 'untimed'}
              onChange={(event) => setTimed(event.target.value === 'timed')}
            >
              <option value="timed">Timed session (recommended)</option>
              <option value="untimed">Untimed practice</option>
            </select>
          </fieldset>
        </div>

        <div style={{ marginTop: '2rem', display: 'flex', gap: '1rem', flexWrap: 'wrap' }}>
          <button className="primary" type="submit" disabled={disabled}>
            Launch assessment
          </button>
          <button
            className="secondary"
            type="button"
            onClick={() => {
              setCandidateName('');
              setTargetLevel(SUPPORTED_LEVELS[2]);
              setQuestionsPerSkill(2);
              setTimed(true);
            }}
            disabled={disabled}
          >
            Reset form
          </button>
        </div>
      </form>
    </section>
  );
}
