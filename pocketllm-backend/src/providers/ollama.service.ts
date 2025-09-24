import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';
import { Readable } from 'stream';

interface OllamaCompletionOptions {
  baseUrl: string;
  model: string;
}

interface OllamaMessage {
  role: string;
  content: string;
}

@Injectable()
export class OllamaService {
  private readonly logger = new Logger(OllamaService.name);

  constructor(private readonly httpService: HttpService) {}

  /**
   * Calls the Ollama /api/chat endpoint and returns the response stream.
   * @param prompt The user's prompt.
   * @param history The previous messages in the chat.
   * @param options Configuration for the Ollama request.
   * @returns A ReadableStream from the fetch response.
   */
  async getCompletionStream(
    prompt: string,
    history: OllamaMessage[],
    options: OllamaCompletionOptions,
  ): Promise<Readable> {
    const { baseUrl, model } = options;

    const messages = [
      ...history,
      { role: 'user', content: prompt },
    ];

    try {
      const response = await fetch(`${baseUrl}/api/chat`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          model: model,
          messages: messages,
          stream: true,
        }),
      });

      if (!response.ok) {
        const errorBody = await response.text();
        throw new Error(`Ollama API error: ${response.statusText} - ${errorBody}`);
      }

      // Return the response body as a Readable stream
      return response.body as unknown as Readable;
    } catch (error) {
      this.logger.error('Ollama API error:', error);
      throw new Error(`Ollama API error: ${error.message}`);
    }
  }

  /**
   * Get available models from Ollama
   * @param baseUrl The Ollama base URL
   */
  async getModels(baseUrl: string): Promise<any> {
    try {
      const response = await firstValueFrom(
        this.httpService.get(`${baseUrl}/api/tags`),
      );
      return response.data;
    } catch (error) {
      this.logger.error('Ollama get models error:', error);
      throw new Error(`Failed to get Ollama models: ${error.message}`);
    }
  }

  /**
   * Get model details from Ollama
   * @param baseUrl The Ollama base URL
   * @param modelName The model name
   */
  async getModelDetails(baseUrl: string, modelName: string): Promise<any> {
    try {
      const response = await firstValueFrom(
        this.httpService.post(`${baseUrl}/api/show`, {
          name: modelName,
        }),
      );
      return response.data;
    } catch (error) {
      this.logger.error('Ollama get model details error:', error);
      throw new Error(`Failed to get Ollama model details: ${error.message}`);
    }
  }

  /**
   * Get a single completion from Ollama (non-streaming)
   * @param prompt The user's prompt
   * @param model The model to use
   * @param systemPrompt Optional system prompt
   * @param baseUrl Optional base URL (defaults to localhost)
   */
  async getCompletion(
    prompt: string,
    model: string,
    systemPrompt?: string,
    baseUrl: string = 'http://localhost:11434',
  ): Promise<{ content: string }> {
    const messages = [
      { role: 'system', content: systemPrompt || 'You are a helpful assistant.' },
      { role: 'user', content: prompt },
    ];

    try {
      const response = await firstValueFrom(
        this.httpService.post(`${baseUrl}/api/chat`, {
          model: model,
          messages: messages,
          stream: false,
        }),
      );

      const content = response.data?.message?.content;

      if (!content) {
        throw new Error('Invalid response structure from Ollama API. No content found.');
      }

      return { content };
    } catch (error) {
      this.logger.error('Ollama API error:', error);
      throw new Error(`Ollama API error: ${error.message}`);
    }
  }
}
