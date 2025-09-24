import fetch from 'node-fetch';
import { Readable } from 'stream';

interface OllamaCompletionOptions {
  baseUrl: string;
  model: string;
  // We can add more Ollama-specific options here later
}

/**
 * Calls the Ollama /api/chat endpoint and returns the response stream.
 * @param prompt The user's prompt.
 * @param history The previous messages in the chat.
 * @param options Configuration for the Ollama request.
 * @returns A ReadableStream from the fetch response.
 */
export async function getOllamaCompletionStream(
  prompt: string,
  history: any[], // Define a proper type for this later
  options: OllamaCompletionOptions
): Promise<Readable> {
  const { baseUrl, model } = options;

  const messages = [
    ...history,
    { role: 'user', content: prompt }
  ];

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

  // The body of a node-fetch response is a Readable stream
  return response.body;
}
