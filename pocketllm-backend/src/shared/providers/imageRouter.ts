interface ImageRouterResponse {
  data: {
    b64_json: string;
  }[];
  error?: {
    message: string;
  }
}

interface ImageJobInput {
  prompt: string;
  model: string;
  quality?: string;
  size?: string;
}

/**
 * A more realistic implementation for the ImageRouter provider.
 * It calls the ImageRouter API and returns the base64-encoded image data.
 * @param jobInput The details for the image generation job.
 * @param apiKey The secret API key for the ImageRouter service.
 * @returns An object containing the base64 encoded image and its mime type.
 */
export async function generateImage(jobInput: ImageJobInput, apiKey: string) {
  const response = await fetch('https://api.imagerouter.io/v1/openai/images/generations', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      ...jobInput,
      response_format: 'b64_json', // We want the raw data to upload it ourselves
    }),
  });

  const data: ImageRouterResponse = await response.json();

  if (!response.ok) {
    const errorMessage = data.error?.message || 'An unknown error occurred with the ImageRouter API.';
    throw new Error(`ImageRouter API error (${response.status}): ${errorMessage}`);
  }

  const b64Json = data.data[0]?.b64_json;
  if (!b64Json) {
    throw new Error('Invalid response structure from ImageRouter API. No b64_json found.');
  }

  // The controller will be responsible for decoding this and uploading.
  return {
    base64Image: b64Json,
    mimeType: 'image/png' // The API defaults to png, this is a safe assumption.
  };
}
