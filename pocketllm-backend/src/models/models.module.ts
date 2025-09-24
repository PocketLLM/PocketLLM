import { Module } from '@nestjs/common';
import { ModelsController } from './models.controller';
import { ModelsService } from './models.service';
import { ProviderConfigsModule } from '../provider-configs/provider-configs.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [ProviderConfigsModule, AuthModule],
  controllers: [ModelsController],
  providers: [ModelsService],
  exports: [ModelsService],
})
export class ModelsModule {}

