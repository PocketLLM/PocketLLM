import { Module } from '@nestjs/common';
import { HttpModule } from '@nestjs/axios';
import { OpenAIService } from './openai.service';
import { AnthropicService } from './anthropic.service';
import { OllamaService } from './ollama.service';
import { ImageRouterService } from './image-router.service';

@Module({
  imports: [HttpModule],
  providers: [
    OpenAIService,
    AnthropicService,
    OllamaService,
    ImageRouterService,
  ],
  exports: [
    OpenAIService,
    AnthropicService,
    OllamaService,
    ImageRouterService,
  ],
})
export class ProvidersModule {}
