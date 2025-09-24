import { Module } from '@nestjs/common';
import { AuthModule } from '../../auth/auth.module';
import { UsersModule } from '../../users/users.module';
import { ChatsModule } from '../../chats/chats.module';
import { JobsModule } from '../../jobs/jobs.module';
import { ProviderConfigsModule } from '../../provider-configs/provider-configs.module';
import { ModelsModule } from '../../models/models.module';

@Module({
  imports: [
    AuthModule,
    UsersModule,
    ChatsModule,
    JobsModule,
    ProviderConfigsModule,
    ModelsModule,
  ],
})
export class V1Module {}
