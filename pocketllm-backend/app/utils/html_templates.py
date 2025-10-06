"""HTML template helpers for simple informational endpoints."""

from __future__ import annotations

from html import escape
from textwrap import dedent

from app.schemas.common import HealthResponse


def render_root_page() -> str:
    """Return the HTML for the backend landing page."""

    return dedent(
        """
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>PocketLLM Backend</title>
            <style>
              :root {
                color-scheme: light dark;
                --primary: #5b6dff;
                --secondary: #12c2e9;
                --bg: radial-gradient(circle at top, rgba(91, 109, 255, 0.18), transparent 60%),
                       radial-gradient(circle at bottom, rgba(18, 194, 233, 0.18), transparent 55%),
                       #0f172a;
                --card-bg: rgba(15, 23, 42, 0.78);
                --text: #e2e8f0;
                --muted: #94a3b8;
              }

              * {
                box-sizing: border-box;
              }

              body {
                margin: 0;
                padding: 0;
                font-family: "Inter", "Segoe UI", system-ui, -apple-system, sans-serif;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                background: var(--bg);
                color: var(--text);
              }

              .card {
                background: var(--card-bg);
                padding: 3rem;
                border-radius: 24px;
                backdrop-filter: blur(16px);
                box-shadow: 0 24px 60px rgba(15, 23, 42, 0.45);
                max-width: 640px;
                width: calc(100% - 3rem);
                text-align: center;
                border: 1px solid rgba(148, 163, 184, 0.12);
              }

              h1 {
                font-size: clamp(2.25rem, 4vw, 3rem);
                margin-bottom: 0.75rem;
                font-weight: 700;
                letter-spacing: -0.03em;
              }

              p {
                margin: 0 auto 2rem;
                max-width: 480px;
                line-height: 1.7;
                font-size: 1.05rem;
                color: var(--muted);
              }

              .cta {
                display: inline-flex;
                align-items: center;
                gap: 0.6rem;
                padding: 0.85rem 1.65rem;
                border-radius: 999px;
                font-weight: 600;
                background: linear-gradient(135deg, var(--primary), var(--secondary));
                color: white;
                text-decoration: none;
                transition: transform 0.2s ease, box-shadow 0.2s ease;
                box-shadow: 0 12px 30px rgba(91, 109, 255, 0.35);
              }

              .cta:hover {
                transform: translateY(-2px);
                box-shadow: 0 16px 40px rgba(91, 109, 255, 0.45);
              }

              footer {
                margin-top: 2.5rem;
                font-size: 0.9rem;
                color: rgba(148, 163, 184, 0.7);
              }

              @media (max-width: 600px) {
                .card {
                  padding: 2.25rem;
                }

                p {
                  font-size: 1rem;
                }
              }
            </style>
          </head>
          <body>
            <main class="card">
              <h1>PocketLLM Backend</h1>
              <p>
                You're connected to the PocketLLM API service. Use the button below to
                explore versioned API routes, or head to the health check for a quick
                status update.
              </p>
              <a class="cta" href="/health">
                View Health Status
                <span aria-hidden="true">→</span>
              </a>
              <footer>Ready to assist your AI experiences ⚡️</footer>
            </main>
          </body>
        </html>
        """
    ).strip()


def render_health_page(payload: HealthResponse) -> str:
    """Return the HTML for the health endpoint based on the payload."""

    status = escape(payload.status.upper())
    version = escape(payload.version)
    timestamp = escape(payload.timestamp.isoformat())

    return dedent(
        f"""
        <!DOCTYPE html>
        <html lang="en">
          <head>
            <meta charset="UTF-8" />
            <meta name="viewport" content="width=device-width, initial-scale=1.0" />
            <title>PocketLLM Health Status</title>
            <style>
              body {{
                margin: 0;
                font-family: 'Inter', 'Segoe UI', system-ui, -apple-system, sans-serif;
                background: linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #111827 100%);
                color: #e2e8f0;
                min-height: 100vh;
                display: flex;
                align-items: center;
                justify-content: center;
                padding: 2rem;
              }}

              .panel {{
                background: rgba(15, 23, 42, 0.85);
                border-radius: 20px;
                padding: 2.75rem 3rem;
                max-width: 520px;
                width: 100%;
                box-shadow: 0 25px 80px rgba(15, 23, 42, 0.45);
                border: 1px solid rgba(148, 163, 184, 0.15);
                backdrop-filter: blur(18px);
              }}

              h1 {{
                margin: 0 0 1.25rem;
                font-size: clamp(2rem, 4vw, 2.8rem);
                letter-spacing: -0.03em;
              }}

              .status {{
                display: inline-flex;
                align-items: center;
                gap: 0.6rem;
                background: rgba(16, 185, 129, 0.16);
                color: #5eead4;
                padding: 0.55rem 1.15rem;
                border-radius: 999px;
                font-weight: 600;
                letter-spacing: 0.02em;
                text-transform: uppercase;
              }}

              dl {{
                margin: 2rem 0 0;
                display: grid;
                grid-template-columns: auto 1fr;
                gap: 1rem 1.5rem;
                font-size: 1.05rem;
              }}

              dt {{
                color: rgba(148, 163, 184, 0.85);
                text-transform: uppercase;
                font-size: 0.85rem;
                letter-spacing: 0.08em;
              }}

              dd {{
                margin: 0;
                font-weight: 600;
                color: #f8fafc;
              }}

              a {{
                display: inline-block;
                margin-top: 2.5rem;
                color: #60a5fa;
                text-decoration: none;
                font-weight: 600;
              }}

              a:hover {{
                text-decoration: underline;
              }}

              @media (max-width: 520px) {{
                .panel {{
                  padding: 2.25rem;
                }}
              }}
            </style>
          </head>
          <body>
            <section class="panel">
              <span class="status">{status}</span>
              <h1>Service Health</h1>
              <dl>
                <dt>Version</dt>
                <dd>{version}</dd>
                <dt>Timestamp</dt>
                <dd>{timestamp}</dd>
              </dl>
              <a href="/" aria-label="Return to PocketLLM backend home">← Back to home</a>
            </section>
          </body>
        </html>
        """
    ).strip()


__all__ = ["render_health_page", "render_root_page"]
