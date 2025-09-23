import { FastifyRequest, FastifyReply } from 'fastify'
import { supabaseAdmin } from '../../../shared/supabaseClient.ts'
import { decrypt } from '../../../shared/utils/encryption.ts'
import { getOpenAICompletion } from '../../../shared/providers/openai.ts'
import { getAnthropicCompletion } from '../../../shared/providers/anthropic.ts'
import { handleError } from '../../../shared/utils/errorHandler.ts'
import { z } from 'zod'
import { createMessageSchema } from '../schemas/chatSchemas.ts'

// This assumes a user object with an id is attached to the request by an auth pre-handler
type AuthenticatedRequest = FastifyRequest<{
  Body: z.infer<typeof createMessageSchema.body>,
  Params: z.infer<typeof createMessageSchema.params>,
  User: { id: string }
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

    // 2. Fetch chat and model config
    const { data: chat, error: chatError } = await supabaseAdmin
      .from('chats')
      .select('model_configs(*)')
      .eq('id', chatId)
      .eq('user_id', userId)
      .single()

    if (chatError || !chat || !chat.model_configs) {
      return reply.status(404).send({ error: `Chat not found or model configuration missing.` })
    }

    const { provider, model, api_key_encrypted } = chat.model_configs
    if (!api_key_encrypted) {
      return reply.status(400).send({ error: 'API key for this model is not configured.' })
    }

    // 3. Decrypt key and call provider
    const apiKey = decrypt(api_key_encrypted)
    let assistantResponse: { content: string }

    if (provider.toLowerCase() === 'openai') {
      assistantResponse = await getOpenAICompletion(prompt, apiKey, model)
    } else if (provider.toLowerCase() === 'anthropic') {
      assistantResponse = await getAnthropicCompletion(prompt, apiKey, model)
    } else {
      return reply.status(400).send({ error: `Provider "${provider}" is not supported.` })
    }

    // 4. Save assistant's response
    const { data: assistantMessage, error: assistantMessageError } = await supabaseAdmin
      .from('messages')
      .insert({
        chat_id: chatId,
        role: 'assistant',
        content: assistantResponse.content,
        metadata: { provider, model }
      })
      .select()
      .single()

    if (assistantMessageError) throw new Error(`Failed to save assistant message: ${assistantMessageError.message}`)

    return reply.status(200).send(assistantMessage)

  } catch (error) {
    return handleError(reply, error)
  }
}
