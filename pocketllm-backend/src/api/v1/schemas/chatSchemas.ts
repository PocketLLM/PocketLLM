import { asConst } from 'fastify-zod'
import { z } from 'zod'

export const createMessageSchema = asConst({
  body: z.object({
    prompt: z.string().min(1, 'Prompt cannot be empty.'),
  }),
  params: z.object({
    chatId: z.string().uuid('Invalid chat ID format.'),
  }),
  response: {
    200: z.object({
      id: z.string().uuid(),
      chat_id: z.string().uuid(),
      role: z.enum(['user', 'assistant', 'system']),
      content: z.string(),
      metadata: z.record(z.any()).nullable(),
      created_at: z.string().datetime(),
    }),
  },
})
