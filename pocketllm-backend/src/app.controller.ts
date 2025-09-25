import { Controller, Get } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';

@Controller()
export class AppController {
  constructor(private readonly configService: ConfigService) {}

  @Get()
  getRoot() {
    const apiPrefix = this.configService.get<string>('app.api.prefix') ?? 'v1';
    const docsConfig = this.configService.get<{ enabled?: boolean; path?: string }>('app.docs');
    const docsEnabled = docsConfig?.enabled !== false;
    const docsPath = docsEnabled ? this.resolveDocsPath(docsConfig?.path) : null;

    return {
      status: 'ok',
      message: `PocketLLM backend is running. All REST endpoints are available under the /${apiPrefix} prefix.`,
      docs: docsPath,
      docsAliases: docsEnabled ? this.resolveDocsAliases(docsConfig?.path) : [],
      health: '/health',
    };
  }

  @Get('health')
  getHealth() {
    return {
      status: 'ok',
      timestamp: new Date().toISOString(),
    };
  }

  private resolveDocsPath(path?: string | null): string {
    const sanitized = (path ?? 'api/docs').trim().replace(/^\/+|\/+$/g, '');
    return `/${sanitized.length > 0 ? sanitized : 'api/docs'}`;
  }

  private resolveDocsAliases(path?: string | null): string[] {
    const primary = this.resolveDocsPath(path);
    const normalized = primary.replace(/^\/+|\/+$/g, '');

    if (!normalized.toLowerCase().startsWith('api/')) {
      return [];
    }

    const alias = normalized.substring(4).replace(/^\/+/, '');
    if (!alias) {
      return [];
    }

    return [`/${alias}`];
  }
}
