export function HeroSection() {
  return (
    <section style={{ textAlign: 'center', marginBottom: '2.5rem' }}>
      <div className="badge" style={{ marginBottom: '0.75rem' }}>
        Language Test App
      </div>
      <h1 style={{ margin: '0 auto 1rem', maxWidth: '640px' }}>
        Build adaptive language proficiency assessments in minutes.
      </h1>
      <p style={{ margin: '0 auto', maxWidth: '640px', color: 'var(--muted-foreground)', lineHeight: 1.6 }}>
        Configure CEFR-aligned grammar, reading, listening, and vocabulary tasks. Deliver the assessment instantly and share a
        polished performance summary with your learners.
      </p>
    </section>
  );
}
