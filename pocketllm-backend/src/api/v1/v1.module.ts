import { Module } from '@nestjs/common';
import { AuthModule } from '../../auth/auth.module';
import { UsersModule } from '../../users/users.module';
import { ChatsModule } from '../../chats/chats.module';
import { ModelsModule } from '../../models/models.module';
import { JobsModule } from '../../jobs/jobs.module';
import { EmbeddingsModule } from '../../embeddings/embeddings.module';

@Module({
  imports: [
    AuthModule,
    UsersModule,
    ChatsModule,
    ModelsModule,
    JobsModule,
    EmbeddingsModule,
  ],
})
export class V1Module {}
