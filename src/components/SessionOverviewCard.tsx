import { TestConfiguration } from '../types/test';
import { LevelBadge } from './LevelBadge';

interface SessionOverviewCardProps {
  config: TestConfiguration;
  progressLabel?: string;
}

export function SessionOverviewCard({ config, progressLabel }: SessionOverviewCardProps) {
  return (
    <section className="section-card">
      <header style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '1rem' }}>
        <div>
          <h2 style={{ margin: 0 }}>{config.candidateName || 'Unnamed Candidate'}</h2>
          <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>Language proficiency assessment</p>
        </div>
        <LevelBadge level={config.targetLevel} />
      </header>
      <div className="grid columns-2">
        <div>
          <p style={{ margin: 0, fontWeight: 600 }}>Questions per skill</p>
          <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>{config.questionsPerSkill}</p>
        </div>
        <div>
          <p style={{ margin: 0, fontWeight: 600 }}>Timing</p>
          <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>
            {config.timed ? 'Timed delivery enabled' : 'No time limit'}
          </p>
        </div>
        {progressLabel ? (
          <div style={{ gridColumn: '1 / -1' }}>
            <p style={{ margin: 0, fontWeight: 600 }}>Progress</p>
            <p style={{ margin: '0.25rem 0 0', color: 'var(--muted-foreground)' }}>{progressLabel}</p>
          </div>
        ) : null}
      </div>
    </section>
  );
}
