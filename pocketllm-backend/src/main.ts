import { NestFactory } from '@nestjs/core';
import { ValidationPipe } from '@nestjs/common';
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';
import { ConfigService } from '@nestjs/config';
import { AppModule } from './app.module';

// Export the NestJS application instance for Vercel
export async function createApp() {
  const app = await NestFactory.create(AppModule);
  
  const configService = app.get(ConfigService);
  const port = configService.get<number>('app.port', 8000);
  const apiPrefix = configService.get<string>('app.api.prefix', 'v1');
  const corsOrigin = configService.get<string>('app.cors.origin', '*');

  // Enable CORS
  app.enableCors({
    origin: corsOrigin,
    credentials: true,
    methods: ['GET', 'POST', 'PUT', 'DELETE', 'PATCH', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'Accept'],
  });

  // Set global prefix for all routes
  app.setGlobalPrefix(apiPrefix);

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

  // Swagger documentation setup (only in development)
  if (process.env.NODE_ENV !== 'production') {
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
    SwaggerModule.setup('api/docs', app, document, {
      swaggerOptions: {
        persistAuthorization: true,
      },
    });
  }

  return app;
}

// For local development
async function bootstrap() {
  const app = await createApp();
  const configService = app.get(ConfigService);
  const port = configService.get<number>('app.port', 8000);
  
  await app.listen(port);
  
  console.log(`🚀 PocketLLM Backend is running on: http://localhost:${port}`);
  console.log(`📚 API Documentation: http://localhost:${port}/api/docs`);
  console.log(`🔗 API Base URL: http://localhost:${port}/v1`);
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