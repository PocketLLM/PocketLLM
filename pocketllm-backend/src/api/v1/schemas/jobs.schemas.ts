import { z } from 'zod';

// Image Generation Job Schema
export const imageGenerationJobSchema = {
  body: z.object({
    prompt: z.string().min(1, 'Prompt is required').max(1000, 'Prompt too long'),
    model: z.enum(['dall-e-3', 'dall-e-2', 'midjourney']),
    size: z.enum(['256x256', '512x512', '1024x1024', '1792x1024', '1024x1792']),
    quality: z.enum(['standard', 'hd', 'high']).optional(),
    style: z.enum(['vivid', 'natural']).optional(),
    n: z.number().min(1).max(4).optional(),
  }),
};

// Job Query Schema
export const jobQuerySchema = {
  query: z.object({
    status: z.enum(['pending', 'processing', 'completed', 'failed', 'cancelled']).optional(),
    type: z.enum(['image_generation']).optional(),
    limit: z.coerce.number().positive().max(100).optional(),
    offset: z.coerce.number().min(0).optional(),
  }),
};

// Job Params Schema
export const jobParamsSchema = {
  params: z.object({
    jobId: z.string().uuid('Invalid job ID format'),
  }),
};

// Cost Estimation Schema
export const costEstimationSchema = {
  body: z.object({
    model: z.enum(['dall-e-3', 'dall-e-2', 'midjourney']),
    size: z.enum(['256x256', '512x512', '1024x1024', '1792x1024', '1024x1792']),
    quality: z.enum(['standard', 'hd', 'high']).optional(),
    n: z.number().min(1).max(4).optional(),
  }),
};

// Job Schema
export const jobSchema = z.object({
  id: z.string().uuid(),
  user_id: z.string().uuid(),
  type: z.enum(['image_generation']),
  status: z.enum(['pending', 'processing', 'completed', 'failed', 'cancelled']),
  parameters: z.object({
    prompt: z.string().optional(),
    model: z.string().optional(),
    size: z.string().optional(),
    quality: z.string().optional(),
    style: z.string().optional(),
    n: z.number().optional(),
  }),
  result: z.any().nullable(),
  estimated_cost: z.number().nullable(),
  actual_cost: z.number().nullable(),
  error_message: z.string().nullable(),
  created_at: z.string(),
  updated_at: z.string(),
  completed_at: z.string().nullable(),
});

// Image Model Schema
export const imageModelSchema = z.object({
  name: z.string(),
  provider: z.string(),
  sizes: z.array(z.string()),
  quality: z.array(z.string()),
  pricing: z.record(z.number()),
});

// Cost Breakdown Schema
export const costBreakdownSchema = z.object({
  model: z.string(),
  size: z.string(),
  quality: z.string(),
  quantity: z.number(),
  unitCost: z.number(),
});

// Cost Estimation Response Schema
export const costEstimationResponseSchema = z.object({
  estimatedCost: z.number(),
  currency: z.string(),
  breakdown: costBreakdownSchema,
});

// Type exports for TypeScript
export type ImageGenerationJobRequest = z.infer<typeof imageGenerationJobSchema.body>;
export type JobQuery = z.infer<typeof jobQuerySchema.query>;
export type JobParams = z.infer<typeof jobParamsSchema.params>;
export type CostEstimationRequest = z.infer<typeof costEstimationSchema.body>;
export type Job = z.infer<typeof jobSchema>;
export type ImageModel = z.infer<typeof imageModelSchema>;
export type CostBreakdown = z.infer<typeof costBreakdownSchema>;
export type CostEstimationResponse = z.infer<typeof costEstimationResponseSchema>;
