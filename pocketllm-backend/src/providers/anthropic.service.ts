import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

interface AnthropicResponse {
  content: {
    text: string;
  }[];
  error?: {
    type: string;
    message: string;
  };
}

@Injectable()
export class AnthropicService {
  private readonly logger = new Logger(AnthropicService.name);

  constructor(private readonly httpService: HttpService) {}

  /**
   * Calls the Anthropic Messages API to get a response.
   * @param prompt The user's prompt.
   * @param apiKey The user's Anthropic API key.
   * @param model The specific model to use (e.g., 'claude-3-opus-20240229').
   * @param systemPrompt An optional system prompt to guide the model's behavior.
   * @returns An object containing the model's response content.
   */
  async getCompletion(
    prompt: string,
    apiKey: string,
    model: string,
    systemPrompt?: string | null,
  ): Promise<{ content: string }> {
    try {
      const response = await firstValueFrom(
        this.httpService.post<AnthropicResponse>(
          'https://api.anthropic.com/v1/messages',
          {
            model: model,
            system: systemPrompt || 'You are a helpful assistant.',
            messages: [{ role: 'user', content: prompt }],
            max_tokens: 4096, // A required parameter for this API
          },
          {
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
          },
        ),
      );

      const content = response.data.content[0]?.text;

      if (!content) {
        throw new Error('Invalid response structure from Anthropic API. No content found.');
      }

      return { content };
    } catch (error) {
      this.logger.error('Anthropic API error:', error);
      
      if (error.response?.data?.error?.message) {
        throw new Error(`Anthropic API error (${error.response.status}): ${error.response.data.error.message}`);
      }
      
      throw new Error(`Anthropic API error: ${error.message}`);
    }
  }
}
