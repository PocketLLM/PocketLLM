'use client';

import { HeroSection } from '../components/HeroSection';
import { ResultsSummary } from '../components/ResultsSummary';
import { TestConfigurator } from '../components/TestConfigurator';
import { TestSession } from '../components/TestSession';
import { useTestSession } from '../hooks/useTestSession';

export default function HomePage() {
  const { status, config, question, progress, responses, results, elapsedSeconds, startSession, submitAnswer, resetSession } =
    useTestSession();

  return (
    <main>
      <HeroSection />

      {status === 'idle' && <TestConfigurator onStart={startSession} disabled={status !== 'idle'} />}

      {status === 'running' && config ? (
        <TestSession
          config={config}
          question={question}
          progress={progress}
          responses={responses}
          elapsedSeconds={elapsedSeconds}
          onSubmit={submitAnswer}
          onCancel={resetSession}
        />
      ) : null}

      {status === 'complete' && config && results ? (
        <ResultsSummary
          config={config}
          results={results}
          elapsedSeconds={elapsedSeconds}
          onRestart={resetSession}
        />
      ) : null}
    </main>
  );
}
