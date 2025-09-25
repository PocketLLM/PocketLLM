import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Controller()
export class AppController {
  constructor(private readonly configService: ConfigService) {}

  @Get()
  getRoot() {
    const docsConfig = this.configService.get<{ enabled?: boolean; paths?: string[] }>('app.docs');
    const docsDisabled = docsConfig?.enabled === false;

    const documentationPaths = docsDisabled
      ? []
      : Array.from(
          new Set(
            (Array.isArray(docsConfig?.paths) && docsConfig.paths.length > 0
              ? docsConfig.paths
              : ['docs', 'api/docs'])
              .map((path) => path.trim())
              .filter((path) => path.length > 0)
              .map((path) => (path.startsWith('/') ? path : `/${path}`)),
          ),
        );

    const [primaryDoc, ...alternateDocs] = documentationPaths;

    return {
      status: 'ok',
      message: 'PocketLLM backend is running. All REST endpoints are available under the /v1 prefix.',
      docs: primaryDoc ?? null,
      alternateDocs,
      health: '/v1/health',
    };
  }

  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      environment: this.configService.get<string>('app.environment', 'development'),
      version: this.configService.get<string>('app.api.version', '1.0.0'),
      uptime: parseFloat(process.uptime().toFixed(3)),
      timestamp: new Date().toISOString(),
    };
  }
}
