import clsx from 'clsx';
import { ProficiencyLevel } from '../types/test';

const LEVEL_LABELS: Record<ProficiencyLevel, string> = {
  A1: 'Beginner',
  A2: 'Elementary',
  B1: 'Intermediate',
  B2: 'Upper-Intermediate',
  C1: 'Advanced',
  C2: 'Mastery'
};

interface LevelBadgeProps {
  level: ProficiencyLevel;
  variant?: 'primary' | 'neutral';
}

export function LevelBadge({ level, variant = 'primary' }: LevelBadgeProps) {
  return <span className={clsx('badge', { neutral: variant === 'neutral' })}>CEFR {level} · {LEVEL_LABELS[level]}</span>;
}
