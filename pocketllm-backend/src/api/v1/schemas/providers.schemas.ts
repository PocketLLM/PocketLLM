import { z } from 'zod';

export const providerCodeSchema = z.enum(['openai', 'anthropic', 'ollama', 'openrouter']);

const baseProviderSchema = z.object({
  provider: providerCodeSchema,
  apiKey: z.union([z.string().min(1), z.null()]).optional(),
  baseUrl: z.union([z.string().url('Base URL must be a valid URL'), z.null()]).optional(),
  metadata: z.record(z.any()).optional(),
  displayName: z.string().min(1).optional(),
  isActive: z.boolean().optional(),
});

export const activateProviderSchema = {
  body: baseProviderSchema.superRefine((data, ctx) => {
    if (data.provider === 'openrouter' && !data.apiKey) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'API key is required for OpenRouter.',
        path: ['apiKey'],
      });
    }

    if (data.provider === 'ollama' && !data.baseUrl) {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Base URL is required for Ollama.',
        path: ['baseUrl'],
      });
    }
  }),
};

export const updateProviderSchema = {
  body: baseProviderSchema.partial().superRefine((data, ctx) => {
    if (data.apiKey === '') {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'API key cannot be empty.',
        path: ['apiKey'],
      });
    }

    if (data.baseUrl === '') {
      ctx.addIssue({
        code: z.ZodIssueCode.custom,
        message: 'Base URL cannot be empty.',
        path: ['baseUrl'],
      });
    }
  }),
};

export const providerParamsSchema = {
  params: z.object({
    provider: providerCodeSchema,
  }),
};

export const providerModelsQuerySchema = {
  query: z.object({
    search: z.string().min(1).optional(),
  }),
};

export type ProviderCode = z.infer<typeof providerCodeSchema>;
export type ActivateProviderRequest = z.infer<typeof activateProviderSchema.body>;
export type UpdateProviderRequest = z.infer<typeof updateProviderSchema.body>;
export type ProviderParams = z.infer<typeof providerParamsSchema.params>;
export type ProviderModelsQuery = z.infer<typeof providerModelsQuerySchema.query>;

