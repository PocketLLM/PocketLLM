import { Module, Global } from '@nestjs/common';
import { APP_FILTER, APP_INTERCEPTOR } from '@nestjs/core';
import { EncryptionService } from './services/encryption.service';
import { SupabaseService } from './services/supabase.service';
import { HashService } from './services/hash.service';
import { ResponseInterceptor } from './interceptors/response.interceptor';
import { HttpExceptionFilter } from './filters/http-exception.filter';

@Global()
@Module({
  providers: [
    EncryptionService,
    SupabaseService,
    HashService,
    {
      provide: APP_INTERCEPTOR,
      useClass: ResponseInterceptor,
    },
    {
      provide: APP_FILTER,
      useClass: HttpExceptionFilter,
    },
  ],
  exports: [EncryptionService, SupabaseService, HashService],
})
export class CommonModule {}
