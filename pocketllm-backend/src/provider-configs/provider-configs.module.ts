import { Module } from '@nestjs/common';
import { ProviderConfigsController } from './provider-configs.controller';
import { ProviderConfigsService } from './provider-configs.service';
import { ProvidersModule } from '../providers/providers.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [ProvidersModule, AuthModule],
  controllers: [ProviderConfigsController],
  providers: [ProviderConfigsService],
  exports: [ProviderConfigsService],
})
export class ProviderConfigsModule {}

