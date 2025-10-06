# Language Test App

The Language Test App is a web tool for creating adaptive language proficiency assessments. It allows educators to configure a session, deliver curated grammar and comprehension questions, and instantly review candidate performance.

## Getting Started

```bash
npm install
npm run dev
```

The development server runs at [http://localhost:3000](http://localhost:3000). Edits within `src/` trigger hot reloads.

## Available Scripts

| Command | Description |
| ------- | ----------- |
| `npm run dev` | Start the Next.js development server. |
| `npm run build` | Create an optimized production build. |
| `npm start` | Run the production build locally. |
| `npm run lint` | Execute ESLint using Next.js defaults. |
| `npm run test` | Run the Vitest unit test suite. |

## Project Structure

```
.
├── docs/                  # Architecture notes and product guides
├── public/                # Static assets served by Next.js
├── src/
│   ├── app/               # App Router entrypoints and layouts
│   ├── components/        # Reusable UI components
│   ├── data/              # Question banks and configuration defaults
│   ├── hooks/             # Client-side state management hooks
│   ├── lib/               # Pure utilities for scoring and formatting
│   ├── styles/            # Global stylesheets
│   └── types/             # Shared TypeScript interfaces
└── vitest.config.ts       # Test runner configuration
```

## Testing

The app uses [Vitest](https://vitest.dev/) and Testing Library. Place spec files in `src/__tests__/` or alongside the code under test. Run the suite with:

```bash
npm run test
```

## License

Released under the MIT License.
