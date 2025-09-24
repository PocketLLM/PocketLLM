import { z } from 'zod';
import { providerCodeSchema } from './providers.schemas';

const modelSettingsSchema = z.object({
  systemPrompt: z.string().optional(),
  temperature: z.number().min(0).max(2).optional(),
  maxTokens: z.number().positive().optional(),
  topP: z.number().min(0).max(1).optional(),
  presencePenalty: z.number().min(-2).max(2).optional(),
  frequencyPenalty: z.number().min(-2).max(2).optional(),
});

export const importModelsSchema = {
  body: z.object({
    provider: providerCodeSchema,
    providerId: z.string().uuid().optional(),
    models: z
      .array(
        z.object({
          id: z.string().min(1, 'Model identifier is required'),
          name: z.string().min(1).optional(),
          description: z.string().optional(),
          metadata: z.record(z.any()).optional(),
          settings: modelSettingsSchema.partial().optional(),
        }),
      )
      .min(1, 'At least one model must be selected'),
    sharedSettings: modelSettingsSchema.partial().optional(),
  }),
};

export const modelIdParamsSchema = {
  params: z.object({
    modelId: z.string().uuid('Invalid model ID format'),
  }),
};

export type ImportModelsRequest = z.infer<typeof importModelsSchema.body>;
export type ModelIdParams = z.infer<typeof modelIdParamsSchema.params>;

