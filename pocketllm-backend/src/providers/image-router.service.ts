import { Injectable, Logger } from '@nestjs/common';
import { HttpService } from '@nestjs/axios';
import { firstValueFrom } from 'rxjs';

interface ImageRouterResponse {
  data: {
    b64_json: string;
  }[];
  error?: {
    message: string;
  };
}

export interface ImageJobInput {
  prompt: string;
  model: string;
  quality?: string;
  size?: string;
}

@Injectable()
export class ImageRouterService {
  private readonly logger = new Logger(ImageRouterService.name);

  constructor(private readonly httpService: HttpService) {}

  /**
   * Calls the ImageRouter API and returns the base64-encoded image data.
   * @param jobInput The details for the image generation job.
   * @param apiKey The secret API key for the ImageRouter service.
   * @returns An object containing the base64 encoded image and its mime type.
   */
  async generateImage(
    jobInput: ImageJobInput,
    apiKey: string,
  ): Promise<{ base64Image: string; mimeType: string }> {
    try {
      const response = await firstValueFrom(
        this.httpService.post<ImageRouterResponse>(
          'https://api.imagerouter.io/v1/openai/images/generations',
          {
            ...jobInput,
            response_format: 'b64_json', // We want the raw data to upload it ourselves
          },
          {
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${apiKey}`,
            },
          },
        ),
      );

      const b64Json = response.data.data[0]?.b64_json;
      if (!b64Json) {
        throw new Error('Invalid response structure from ImageRouter API. No b64_json found.');
      }

      // The controller will be responsible for decoding this and uploading.
      return {
        base64Image: b64Json,
        mimeType: 'image/png', // The API defaults to png, this is a safe assumption.
      };
    } catch (error) {
      this.logger.error('ImageRouter API error:', error);
      
      if (error.response?.data?.error?.message) {
        throw new Error(`ImageRouter API error (${error.response.status}): ${error.response.data.error.message}`);
      }
      
      throw new Error(`ImageRouter API error: ${error.message}`);
    }
  }
}
