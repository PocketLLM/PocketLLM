import { randomUUID } from 'crypto';
import { NestFactory } from '@nestjs/core';
import { RequestMethod, ValidationPipe, type INestApplication } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

type DocsRouteInfo = {
  primary: string;
  aliases: string[];
};

function normalizeDocsPath(path?: string | null): string {
  if (!path) {
    return 'api/docs';
  }

  const trimmed = path.trim().replace(/^\/+|\/+$/g, '');
  return trimmed.length > 0 ? trimmed : 'api/docs';
}

function buildDocsRoutes(path?: string | null): DocsRouteInfo {
  const normalized = normalizeDocsPath(path);
  const routes = new Set<string>();

  const sanitized = normalized.replace(/^\/+|\/+$/g, '');
  const primary = sanitized.length > 0 ? sanitized : 'api/docs';
  routes.add(primary);

  // Vercel treats the `/api/*` namespace specially. Serving the docs from
  // an additional `/docs` path avoids collisions with function routing while
  // keeping backwards compatibility for local development.
  if (primary.toLowerCase().startsWith('api/')) {
    const alias = primary.substring(4).replace(/^\/+/, '');
    if (alias.length > 0) {
      routes.add(alias);
    }
  }

  return {
    primary,
    aliases: Array.from(routes).filter((route) => route !== primary),
  };
}

function registerDocsEndpoints(app: INestApplication, docsRouteInfo: DocsRouteInfo) {
  const config = new DocumentBuilder()
    .setTitle('PocketLLM API')
    .setDescription('Backend API for PocketLLM - AI Chat Application')
    .setVersion('1.0.0')
    .addBearerAuth()
    .addTag('Authentication', 'User authentication endpoints')
    .addTag('Users', 'User profile management')
    .addTag('Chats', 'Chat and conversation management')
    .addTag('Jobs', 'Background job management')
    .build();

  const document = SwaggerModule.createDocument(app, config);
  const swaggerOptions = {
    swaggerOptions: {
      persistAuthorization: true,
    },
    customSiteTitle: 'PocketLLM API Docs',
  } as const;

  const docsRoutes = [docsRouteInfo.primary, ...docsRouteInfo.aliases];
  docsRoutes.forEach((route) => {
    SwaggerModule.setup(route, app, document, swaggerOptions);
  });
}

function registerApiPrefixLanding(
  app: INestApplication,
  apiPrefix: string,
  docsRouteInfo: DocsRouteInfo | null,
) {
  const httpAdapter = app.getHttpAdapter();
  const instance = httpAdapter?.getInstance?.();
  if (!instance || typeof instance.get !== 'function') {
    return;
  }

  const docsLinks = docsRouteInfo
    ? [docsRouteInfo.primary, ...docsRouteInfo.aliases].map((route) => `/${route}`)
    : [];

  instance.get(`/${apiPrefix}`, (request, response) => {
    const startedAt = Date.now();
    const requestId = (request as Record<string, any>)['requestId'] ?? randomUUID();
    (request as Record<string, any>)['requestId'] = requestId;

    response.json({
      success: true,
      data: {
        message: `PocketLLM API root. Append endpoint paths such as /${apiPrefix}/auth/signin.`,
        docs: docsLinks,
        health: '/health',
      },
      error: null,
      metadata: {
        timestamp: new Date().toISOString(),
        requestId,
        processingTime: parseFloat((Date.now() - startedAt).toFixed(2)),
      },
    });
  });
}

// Export the NestJS application instance for Vercel
export async function createApp() {
  const app = await NestFactory.create(AppModule);

  const configService = app.get(ConfigService);
  const port = configService.get<number>('app.port', 8000);
  const apiPrefix = configService.get<string>('app.api.prefix', 'v1');
  const corsOrigin = configService.get<string>('app.cors.origin', '*');
  const docsConfig = configService.get<{ enabled?: boolean; path?: string }>('app.docs');
  const docsEnabled = docsConfig?.enabled !== false;
  const docsRouteInfo = docsEnabled ? buildDocsRoutes(docsConfig?.path) : null;

  // Enable CORS
  app.enableCors({
    origin: corsOrigin,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });

  // Set global prefix for all routes
  const globalPrefixExclusions: Array<string | { path: string; method: RequestMethod }> = [
    { path: '/', method: RequestMethod.GET },
    { path: '/health', method: RequestMethod.GET },
  ];

  if (docsRouteInfo) {
    const allDocsRoutes = new Set<string>([docsRouteInfo.primary, ...docsRouteInfo.aliases]);
    allDocsRoutes.forEach((route) => {
      const normalized = route.replace(/^\/+|\/+$/g, '');
      if (normalized.length === 0) {
        return;
      }
      globalPrefixExclusions.push(normalized, `${normalized}/(.*)`, `${normalized.replace(/\/+$/, '')}-json`);
    });
  }

  app.setGlobalPrefix(apiPrefix, {
    exclude: globalPrefixExclusions,
  });

  // Global validation pipe
  app.useGlobalPipes(
    new ValidationPipe({
      transform: true,
      whitelist: true,
      forbidNonWhitelisted: true,
      transformOptions: {
        enableImplicitConversion: true,
      },
    }),
  );

  // Swagger documentation setup (configurable for all environments)
  if (docsRouteInfo) {
    registerDocsEndpoints(app, docsRouteInfo);
  }

  registerApiPrefixLanding(app, apiPrefix, docsRouteInfo);

  return app;
}

// For local development
async function bootstrap() {
  const app = await createApp();
  const configService = app.get(ConfigService);
  const docsConfig = configService.get<{ enabled?: boolean; path?: string }>('app.docs');
  const apiPrefix = configService.get<string>('app.api.prefix', 'v1');
  const port = configService.get<number>('app.port', 8000);
  const docsEnabled = docsConfig?.enabled !== false;
  const docsRouteInfo = docsEnabled ? buildDocsRoutes(docsConfig?.path) : null;

  await app.listen(port);

  console.log(`🚀 PocketLLM Backend is running on: http://localhost:${port}`);
  if (docsRouteInfo) {
    const docsTargets = [docsRouteInfo.primary, ...docsRouteInfo.aliases]
      .map((route) => `http://localhost:${port}/${route}`)
      .join(', ');
    console.log(`📚 API Documentation: ${docsTargets}`);
  }
  console.log(`🔗 API Base URL: http://localhost:${port}/${apiPrefix}`);
}

// For Vercel deployment
export default async function handler(request, response) {
  const app = await createApp();
  await app.init();
  return app.getHttpAdapter().getInstance()(request, response);
}

// Only bootstrap if running locally (not on Vercel)
if (process.env.VERCEL !== '1') {
  bootstrap().catch((error) => {
    console.error('❌ Error starting the application:', error);
    process.exit(1);
  });
}