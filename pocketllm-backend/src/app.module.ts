import { Module } from '@nestjs/common';
import { ConfigModule } from './config/config.module';
import { CommonModule } from './common/common.module';
import { ProvidersModule } from './providers/providers.module';
import { AuthModule } from './auth/auth.module';
import { UsersModule } from './users/users.module';
import { ChatsModule } from './chats/chats.module';
import { JobsModule } from './jobs/jobs.module';
import { ApiModule } from './api/api.module';

@Module({
  imports: [
    ConfigModule,
    CommonModule,
    ProvidersModule,
    AuthModule,
    UsersModule,
    ChatsModule,
    JobsModule,
    ApiModule,
  ],
})
export class AppModule {}
