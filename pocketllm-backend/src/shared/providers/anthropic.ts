// A more realistic implementation for the Anthropic provider.

interface AnthropicResponse {
  content: {
    text: string;
  }[];
  error?: {
    type: string;
    message: string;
  }
}

/**
 * Calls the Anthropic Messages API to get a response.
 * @param prompt The user's prompt.
 * @param apiKey The user's Anthropic API key.
 * @param model The specific model to use (e.g., 'claude-3-opus-20240229').
 * @param systemPrompt An optional system prompt to guide the model's behavior.
 * @returns An object containing the model's response content.
 */
export async function getAnthropicCompletion(
  prompt: string,
  apiKey: string,
  model: string,
  systemPrompt?: string | null
) {
  const response = await fetch('https://api.anthropic.com/v1/messages', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    },
    body: JSON.stringify({
      model: model,
      system: systemPrompt || 'You are a helpful assistant.',
      messages: [{ role: 'user', content: prompt }],
      max_tokens: 4096, // A required parameter for this API
    }),
  });

  const data: AnthropicResponse = await response.json();

  if (!response.ok) {
    const errorMessage = data.error?.message || 'An unknown error occurred with the Anthropic API.';
    throw new Error(`Anthropic API error (${response.status}): ${errorMessage}`);
  }

  const content = data.content[0]?.text;

  if (!content) {
    throw new Error('Invalid response structure from Anthropic API. No content found.');
  }

  return { content };
}
