// A more realistic implementation for the OpenAI provider.

interface OpenAIResponse {
  choices: {
    message: {
      content: string;
    };
  }[];
  error?: {
    message: string;
  }
}

/**
 * Calls the OpenAI Chat Completions API to get a response.
 * @param prompt The user's prompt.
 * @param apiKey The user's OpenAI API key.
 * @param model The specific model to use (e.g., 'gpt-4').
 * @param systemPrompt An optional system prompt to guide the model's behavior.
 * @returns An object containing the model's response content.
 */
export async function getOpenAICompletion(
  prompt: string,
  apiKey: string,
  model: string,
  systemPrompt?: string | null
) {
  const messages = [
    { role: 'system', content: systemPrompt || 'You are a helpful assistant.' },
    { role: 'user', content: prompt }
  ];

  const response = await fetch('https://api.openai.com/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${apiKey}`,
    },
    body: JSON.stringify({
      model: model,
      messages: messages,
    }),
  });

  const data: OpenAIResponse = await response.json();

  if (!response.ok) {
    const errorMessage = data.error?.message || 'An unknown error occurred with the OpenAI API.';
    throw new Error(`OpenAI API error (${response.status}): ${errorMessage}`);
  }

  const content = data.choices[0]?.message?.content;

  if (!content) {
    throw new Error('Invalid response structure from OpenAI API. No content found.');
  }

  return { content };
}
