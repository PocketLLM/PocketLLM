import type { INestApplication } from '@nestjs/common';
import type { Request, Response } from 'express';

type CreateAppFn = () => Promise<INestApplication>;

function resolveCreateApp(): CreateAppFn {
  try {
    // Prefer the compiled NestJS bundle produced during `npm run build`
    // because it is what the Vercel runtime executes in production.
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const { createApp } = require('../dist/main') as { createApp: CreateAppFn };
    if (typeof createApp === 'function') {
      return createApp;
    }
  } catch (error) {
    if (process.env.NODE_ENV !== 'production') {
      console.warn('Falling back to the TypeScript sources for createApp().', error);
    }
  }

  // eslint-disable-next-line @typescript-eslint/no-var-requires
  const { createApp } = require('../src/main') as { createApp: CreateAppFn };
  return createApp;
}

const appPromise = resolveCreateApp()().then(async (app) => {
  await app.init();
  return app;
});

export default async function handler(req: Request, res: Response) {
  const app = await appPromise;
  app.getHttpAdapter().getInstance()(req, res);
}