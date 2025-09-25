import { registerAs } from '@nestjs/config';

export default registerAs('app', () => ({
  port: parseInt(process.env.PORT, 10) || 8000,
  environment: process.env.NODE_ENV || 'development',
  supabase: {
    url: process.env.SUPABASE_URL,
    serviceRoleKey: process.env.SUPABASE_SERVICE_ROLE_KEY,
  },
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    credentials: true,
  },
  api: {
    prefix: 'v1',
    version: '1.0.0',
  },
  docs: {
    enabled: process.env.SWAGGER_ENABLED !== 'false',
    paths:
      process.env.SWAGGER_PATHS?.split(',')
        .map((path) => path.trim())
        .filter(Boolean) || ['docs', 'api/docs'],
  },
}));
