import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

interface OpenRouterCompletionResponse {
  choices: { message: { content: string } }[];
  error?: { message: string };
}

@Injectable()
export class OpenRouterService {
  private readonly logger = new Logger(OpenRouterService.name);
  private static readonly BASE_URL = 'https://openrouter.ai/api/v1';

  constructor(private readonly httpService: HttpService) {}

  /**
   * Execute a chat completion request against the OpenRouter API.
   */
  async getCompletion(
    prompt: string,
    apiKey: string,
    model: string,
    systemPrompt?: string | null,
  ): Promise<{ content: string }> {
    const messages = [
      { role: 'system', content: systemPrompt || 'You are a helpful assistant.' },
      { role: 'user', content: prompt },
    ];

    try {
      const response = await firstValueFrom(
        this.httpService.post<OpenRouterCompletionResponse>(
          `${OpenRouterService.BASE_URL}/chat/completions`,
          {
            model,
            messages,
            stream: false,
          },
          {
            headers: this.createHeaders(apiKey),
          },
        ),
      );

      const content = response.data.choices?.[0]?.message?.content;

      if (!content) {
        throw new Error('Invalid response structure from OpenRouter API. No content found.');
      }

      return { content };
    } catch (error) {
      this.logger.error('OpenRouter API error:', error);

      const errorMessage =
        error?.response?.data?.error?.message || error?.response?.data?.message || error.message;

      throw new Error(`OpenRouter API error${error.response?.status ? ` (${error.response.status})` : ''}: ${errorMessage}`);
    }
  }

  /**
   * Retrieve all models the API key has access to.
   */
  async getModels(apiKey: string): Promise<any[]> {
    try {
      const response = await firstValueFrom(
        this.httpService.get<{ data: any[] }>(
          `${OpenRouterService.BASE_URL}/models`,
          {
            headers: this.createHeaders(apiKey),
          },
        ),
      );

      return response.data?.data ?? [];
    } catch (error) {
      this.logger.error('OpenRouter get models error:', error);
      const message = error?.response?.data?.error || error.message;
      throw new Error(`Failed to get OpenRouter models: ${message}`);
    }
  }

  /**
   * Helper to build the headers required by OpenRouter.
   */
  private createHeaders(apiKey: string) {
    return {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
      'HTTP-Referer': process.env.OPENROUTER_APP_URL || 'https://pocketllm.app',
      'X-Title': process.env.OPENROUTER_APP_NAME || 'PocketLLM',
    };
  }
}

