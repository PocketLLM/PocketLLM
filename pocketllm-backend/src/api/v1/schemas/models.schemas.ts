import { z } from 'zod';

// User Model Configuration Schema
export const userModelConfigSchema = z.object({
  name: z.string().min(1, 'Configuration name is required').max(100, 'Name too long'),
  provider: z.enum(['openai', 'anthropic', 'ollama']),
  model: z.string().min(1, 'Model is required'),
  apiKey: z.string().optional(),
  systemPrompt: z.string().max(2000, 'System prompt too long').optional(),
  temperature: z.number().min(0).max(2).optional(),
  maxTokens: z.number().positive().max(4000).optional(),
  isDefault: z.boolean().optional(),
});

// Save Model Config Schema
export const saveModelConfigSchema = {
  body: userModelConfigSchema,
};

// Update Model Config Schema
export const updateModelConfigSchema = {
  body: userModelConfigSchema.partial(),
};

// Test Model Config Schema
export const testModelConfigSchema = {
  body: z.object({
    provider: z.enum(['openai', 'anthropic', 'ollama']),
    model: z.string().min(1, 'Model is required'),
    apiKey: z.string().optional(),
    systemPrompt: z.string().optional(),
    testPrompt: z.string().optional(),
    temperature: z.number().min(0).max(2).optional(),
    maxTokens: z.number().positive().max(4000).optional(),
  }),
};

// Stored User Model Config Schema
export const storedUserModelConfigSchema = z.object({
  id: z.string().uuid(),
  user_id: z.string().uuid(),
  name: z.string(),
  provider: z.enum(['openai', 'anthropic', 'ollama']),
  model: z.string(),
  api_key: z.string().nullable(),
  system_prompt: z.string().nullable(),
  temperature: z.number().nullable(),
  max_tokens: z.number().nullable(),
  is_default: z.boolean(),
  created_at: z.string(),
  updated_at: z.string(),
});

// Available Model Schema
export const availableModelSchema = z.object({
  id: z.string(),
  name: z.string(),
  description: z.string(),
  requiresApiKey: z.boolean(),
});

// Provider Schema
export const providerSchema = z.object({
  id: z.string(),
  name: z.string(),
  models: z.array(availableModelSchema),
});

// Model Config Params Schema
export const modelConfigParamsSchema = {
  params: z.object({
    configId: z.string().uuid('Invalid configuration ID format'),
  }),
};

// Provider Params Schema
export const providerParamsSchema = {
  params: z.object({
    provider: z.enum(['openai', 'anthropic', 'ollama']),
  }),
};

// Type exports for TypeScript
export type UserModelConfigInput = z.infer<typeof userModelConfigSchema>;
export type SaveModelConfigRequest = z.infer<typeof saveModelConfigSchema.body>;
export type UpdateModelConfigRequest = z.infer<typeof updateModelConfigSchema.body>;
export type TestModelConfigRequest = z.infer<typeof testModelConfigSchema.body>;
export type StoredUserModelConfig = z.infer<typeof storedUserModelConfigSchema>;
export type AvailableModel = z.infer<typeof availableModelSchema>;
export type Provider = z.infer<typeof providerSchema>;
export type ModelConfigParams = z.infer<typeof modelConfigParamsSchema.params>;
export type ProviderParams = z.infer<typeof providerParamsSchema.params>;
