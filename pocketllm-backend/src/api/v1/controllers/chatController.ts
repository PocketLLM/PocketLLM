import { FastifyRequest, FastifyReply } from 'fastify'
import { supabaseAdmin } from '../../../shared/supabaseClient.ts'
import { decrypt } from '../../../shared/utils/encryption.ts'
import { getOpenAICompletion } from '../../../shared/providers/openai.ts'
import { getAnthropicCompletion } from '../../../shared/providers/anthropic.ts'
import { getOllamaCompletionStream } from '../../../shared/providers/ollama.ts'
import { handleError } from '../../../shared/utils/errorHandler.ts'
import { sendResponse } from '../../../shared/utils/responseHandler.ts'
import { z } from 'zod'
import { createMessageSchema } from '../schemas/chatSchemas.ts'

type AuthenticatedRequest = FastifyRequest<{
  Body: z.infer<typeof createMessageSchema.body>,
  Params: z.infer<typeof createMessageSchema.params>
}>

export async function handleNewMessage(request: AuthenticatedRequest, reply: FastifyReply) {
  try {
    const userId = request.user.id
    const { chatId } = request.params
    const { prompt } = request.body

    // 1. Save the user's message
    const { error: userMessageError } = await supabaseAdmin.from('messages').insert({
      chat_id: chatId,
      role: 'user',
      content: prompt,
    })
    if (userMessageError) throw new Error(`Failed to save user message: ${userMessageError.message}`)

    // 2. Fetch chat, model config, and message history
    const { data: chat, error: chatError } = await supabaseAdmin
      .from('chats')
      .select('*, model_configs(*), messages(role, content)')
      .eq('id', chatId)
      .eq('user_id', userId)
      .single()

    if (chatError || !chat || !chat.model_configs) {
      return handleError(reply, request, chatError, 404, 'Chat not found or model configuration missing.');
    }
    const { provider, model, api_key_encrypted, base_url } = chat.model_configs;
    const history = chat.messages?.filter(m => m.role !== 'user') || []; // Basic history

    // 3. Route to the correct provider
    if (provider.toLowerCase() === 'ollama') {
      if (!base_url) {
        return handleError(reply, request, null, 400, 'Ollama provider requires a base_url in the model configuration.');
      }

      // Set headers for Server-Sent Events (SSE)
      reply.raw.setHeader('Content-Type', 'text/event-stream');
      reply.raw.setHeader('Cache-Control', 'no-cache');
      reply.raw.setHeader('Connection', 'keep-alive');

      const ollamaStream = await getOllamaCompletionStream(prompt, history, { baseUrl: base_url, model });

      let fullContent = '';
      ollamaStream.on('data', (chunk: Buffer) => {
        const chunkStr = chunk.toString();
        const jsonLines = chunkStr.split('\n').filter(line => line.trim() !== '');

        for (const line of jsonLines) {
          try {
            const json = JSON.parse(line);
            if (json.message?.content) {
              const contentPart = json.message.content;
              fullContent += contentPart;
              // Send the content chunk to the client
              reply.raw.write(`data: ${JSON.stringify({ content: contentPart })}\n\n`);
            }
            if (json.done) {
              // Stream is finished, save the full message and close the connection
              supabaseAdmin.from('messages').insert({
                chat_id: chatId,
                role: 'assistant',
                content: fullContent,
                metadata: { provider, model }
              }).then(({ error }) => {
                if (error) console.error('Failed to save assistant message after stream:', error);
                reply.raw.write(`data: ${JSON.stringify({ done: true })}\n\n`);
                reply.raw.end();
              });
            }
          } catch (e) {
            console.error('Failed to parse stream chunk:', line, e);
          }
        }
      });

      ollamaStream.on('error', (err) => {
        console.error('Stream error from Ollama provider:', err);
        if (!reply.raw.writableEnded) {
          reply.raw.end();
        }
      });
      // The request is now being handled by the stream events, so we must not call any other reply methods.
      return;
    }

    // Handle other providers (OpenAI, Anthropic)
    let assistantResponse: { content: string };
    if (!api_key_encrypted) {
        return handleError(reply, request, null, 400, 'API key for this model is not configured.');
    }
    const apiKey = decrypt(api_key_encrypted);

    if (provider.toLowerCase() === 'openai') {
      assistantResponse = await getOpenAICompletion(prompt, apiKey, model);
    } else if (provider.toLowerCase() === 'anthropic') {
      assistantResponse = await getAnthropicCompletion(prompt, apiKey, model);
    } else {
      return handleError(reply, request, null, 400, `Provider "${provider}" is not supported.`);
    }

    // 4. Save assistant's response for non-streaming providers
    const { data: assistantMessage, error: assistantMessageError } = await supabaseAdmin
      .from('messages')
      .insert({
        chat_id: chatId,
        role: 'assistant',
        content: assistantResponse.content,
        metadata: { provider, model }
      })
      .select()
      .single();

    if (assistantMessageError) throw new Error(`Failed to save assistant message: ${assistantMessageError.message}`);

    return sendResponse(reply, request, assistantMessage, null, 200);

  } catch (error) {
    return handleError(reply, request, error);
  }
}
