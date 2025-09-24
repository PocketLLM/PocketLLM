import { asConst } from 'fastify-zod'
import { z } from 'zod'

// Core properties for a model configuration.
// The `api_key` is received in plain text for creation/update but never stored or returned as such.
const modelConfigCore = {
  name: z.string().min(1, 'Name cannot be empty.'),
  provider: z.string().min(1, 'Provider cannot be empty.'),
  base_url: z.string().url('Invalid URL format.').optional().nullable(),
  model: z.string().min(1, 'Model cannot be empty.'),
  system_prompt: z.string().optional().nullable(),
  temperature: z.number().min(0).max(2).default(0.7),
  max_tokens: z.number().int().positive().default(2048),
  top_p: z.number().min(0).max(1).default(1.0),
  frequency_penalty: z.number().min(0).max(2).default(0.0),
  presence_penalty: z.number().min(0).max(2).default(0.0),
  is_default: z.boolean().default(false),
};

// The shape of the data returned from the database.
// Note: It does not include the plain-text `api_key`.
const modelConfigResponseObject = z.object({
  id: z.string().uuid(),
  user_id: z.string().uuid(),
  ...modelConfigCore,
  // The `api_key_encrypted` field is what's stored in the DB, but we won't expose it.
  // We can add a field to indicate if a key is set.
  is_api_key_set: z.boolean(),
  created_at: z.string().datetime(),
  updated_at: z.string().datetime(),
});


export const createModelConfigSchema = asConst({
  body: z.object({
    ...modelConfigCore,
    api_key: z.string().min(1, 'API Key is required.'),
  }),
  response: { 201: modelConfigResponseObject }
});

export const listModelConfigsSchema = asConst({
  response: { 200: z.array(modelConfigResponseObject) }
});

export const getModelConfigSchema = asConst({
  params: z.object({ id: z.string().uuid() }),
  response: { 200: modelConfigResponseObject }
});

export const updateModelConfigSchema = asConst({
  params: z.object({ id: z.string().uuid() }),
  // For update, all fields are optional, including the api_key.
  body: z.object({
    ...modelConfigCore,
    api_key: z.string().optional(),
  }).partial(),
  response: { 200: modelConfigResponseObject }
});

export const deleteModelConfigSchema = asConst({
  params: z.object({ id: z.string().uuid() }),
  response: { 204: z.null() } // Use z.null() for empty response body
});

// =================================================================
// Schemas for interacting with the Ollama API
// =================================================================

// Schema for the details of a single Ollama model tag from /api/tags
export const ollamaModelDetailsSchema = z.object({
  format: z.string(),
  family: z.string(),
  families: z.array(z.string()).nullable(),
  parameter_size: z.string(),
  quantization_level: z.string(),
});

// Schema for a single Ollama model from the /api/tags endpoint
export const ollamaModelSchema = z.object({
  name: z.string(),
  modified_at: z.string(),
  size: z.number(),
  digest: z.string(),
  details: ollamaModelDetailsSchema,
});

// Schema for the response from the GET /api/tags endpoint
export const ollamaListModelsResponseSchema = z.object({
  models: z.array(ollamaModelSchema),
});

// Schema for the detailed response from the POST /api/show endpoint
export const ollamaShowModelResponseSchema = z.object({
    modelfile: z.string(),
    parameters: z.string(),
    template: z.string(),
    details: ollamaModelDetailsSchema.extend({
        parent_model: z.string(),
    }),
    model_info: z.record(z.any()), // This is a large, dynamic object that we don't need to strictly validate
    capabilities: z.array(z.string()).optional(),
});
