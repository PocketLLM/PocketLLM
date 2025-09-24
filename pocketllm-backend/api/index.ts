import { createApp } from '../src/main';

// Create the NestJS app instance
const appPromise = createApp().then(async (app) => {
  await app.init();
  return app;
});

export default async function handler(req, res) {
  const app = await appPromise;
  app.getHttpAdapter().getInstance()(req, res);
}