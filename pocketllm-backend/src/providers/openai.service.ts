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

interface OpenAIEmbeddingResponse {
  data: {
    embedding: number[];
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

  /**
   * Calls the OpenAI Embeddings API to generate embeddings for text.
   * @param text The text to generate embeddings for.
   * @param apiKey The user's OpenAI API key.
   * @param model The embedding model to use (e.g., 'text-embedding-3-large').
   * @returns An object containing the embedding vector.
   */
  async getEmbedding(
    text: string,
    apiKey: string,
    model: string,
  ): Promise<{ embedding: number[] }> {
    try {
      const response = await firstValueFrom(
        this.httpService.post<OpenAIEmbeddingResponse>(
          'https://api.openai.com/v1/embeddings',
          {
            model: model,
            input: text,
          },
          {
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${apiKey}`,
            },
          },
        ),
      );

      const embedding = response.data.data[0]?.embedding;

      if (!embedding) {
        throw new Error('Invalid response structure from OpenAI Embeddings API. No embedding found.');
      }

      return { embedding };
    } catch (error) {
      this.logger.error('OpenAI Embeddings API error:', error);

      if (error.response?.data?.error?.message) {
        throw new Error(`OpenAI Embeddings API error (${error.response.status}): ${error.response.data.error.message}`);
      }

      throw new Error(`OpenAI Embeddings API error: ${error.message}`);
    }
  }
}
