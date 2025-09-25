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
    enabled:
      process.env.ENABLE_SWAGGER_DOCS?.toLowerCase() === 'false'
        ? false
        : process.env.ENABLE_SWAGGER_DOCS?.toLowerCase() === 'true'
        ? true
        : true,
    path: process.env.SWAGGER_DOCS_PATH || 'api/docs',
  },
}));