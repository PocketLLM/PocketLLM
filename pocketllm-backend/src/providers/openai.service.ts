import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

interface OpenAIResponse {
  choices: {
    message: {
      content: string;
    };
  }[];
  error?: {
    message: string;
  };
}

@Injectable()
export class OpenAIService {
  private readonly logger = new Logger(OpenAIService.name);

  constructor(private readonly httpService: HttpService) {}

  /**
   * Calls the OpenAI Chat Completions API to get a response.
   * @param prompt The user's prompt.
   * @param apiKey The user's OpenAI API key.
   * @param model The specific model to use (e.g., 'gpt-4').
   * @param systemPrompt An optional system prompt to guide the model's behavior.
   * @returns An object containing the model's response content.
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
        this.httpService.post<OpenAIResponse>(
          'https://api.openai.com/v1/chat/completions',
          {
            model: model,
            messages: messages,
          },
          {
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${apiKey}`,
            },
          },
        ),
      );

      const content = response.data.choices[0]?.message?.content;

      if (!content) {
        throw new Error('Invalid response structure from OpenAI API. No content found.');
      }

      return { content };
    } catch (error) {
      this.logger.error('OpenAI API error:', error);
      
      if (error.response?.data?.error?.message) {
        throw new Error(`OpenAI API error (${error.response.status}): ${error.response.data.error.message}`);
      }
      
      throw new Error(`OpenAI API error: ${error.message}`);
    }
  }

}
