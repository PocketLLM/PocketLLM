import { z } from 'zod';

// Model Configuration Schema
export const modelConfigSchema = z.object({
  provider: z.enum(['openai', 'anthropic', 'ollama']),
  model: z.string(),
  apiKey: z.string().optional(),
  systemPrompt: z.string().optional(),
  temperature: z.number().min(0).max(2).optional(),
  maxTokens: z.number().positive().optional(),
});

// Create Chat Schema
export const createChatSchema = {
  body: z.object({
    title: z.string().min(1, 'Chat title is required').max(255, 'Title too long'),
    model_config: modelConfigSchema.optional(),
  }),
};

// Update Chat Schema
export const updateChatSchema = {
  body: z.object({
    title: z.string().min(1, 'Chat title is required').max(255, 'Title too long').optional(),
    model_config: modelConfigSchema.optional(),
  }),
};

// Send Message Schema
export const sendMessageSchema = {
  body: z.object({
    content: z.string().min(1, 'Message content is required'),
    model_config: modelConfigSchema,
  }),
};

// Chat Schema
export const chatSchema = z.object({
  id: z.string().uuid(),
  user_id: z.string().uuid(),
  title: z.string(),
  model_config: modelConfigSchema.nullable(),
  created_at: z.string(),
  updated_at: z.string(),
});

// Message Schema
export const messageSchema = z.object({
  id: z.string().uuid(),
  chat_id: z.string().uuid(),
  content: z.string(),
  role: z.enum(['user', 'assistant']),
  created_at: z.string(),
});

// Get Messages Query Schema
export const getMessagesQuerySchema = {
  query: z.object({
    limit: z.coerce.number().positive().max(100).optional(),
    offset: z.coerce.number().min(0).optional(),
  }),
};

// Chat Params Schema
export const chatParamsSchema = {
  params: z.object({
    chatId: z.string().uuid('Invalid chat ID format'),
  }),
};

// Type exports for TypeScript
export type ModelConfig = z.infer<typeof modelConfigSchema>;
export type CreateChatRequest = z.infer<typeof createChatSchema.body>;
export type UpdateChatRequest = z.infer<typeof updateChatSchema.body>;
export type SendMessageRequest = z.infer<typeof sendMessageSchema.body>;
export type Chat = z.infer<typeof chatSchema>;
export type Message = z.infer<typeof messageSchema>;
export type GetMessagesQuery = z.infer<typeof getMessagesQuerySchema.query>;
export type ChatParams = z.infer<typeof chatParamsSchema.params>;
