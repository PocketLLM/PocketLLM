import { Module } from '@nestjs/common';
import { ChatsController } from './chats.controller';
import { ChatsService } from './chats.service';
import { ProvidersModule } from '../providers/providers.module';
import { AuthModule } from '../auth/auth.module';

@Module({
  imports: [ProvidersModule, AuthModule],
  controllers: [ChatsController],
  providers: [ChatsService],
  exports: [ChatsService],
})
export class ChatsModule {}
