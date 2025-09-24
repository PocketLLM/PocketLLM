import { Module } from '@nestjs/common';
import { AuthModule } from '../../auth/auth.module';
import { UsersModule } from '../../users/users.module';
import { ChatsModule } from '../../chats/chats.module';
import { JobsModule } from '../../jobs/jobs.module';

@Module({
  imports: [
    AuthModule,
    UsersModule,
    ChatsModule,
    JobsModule,
  ],
})
export class V1Module {}
