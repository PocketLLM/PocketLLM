import { z } from 'zod'

export const createImageJobSchema = {
  body: z.object({
    prompt: z.string().min(1, 'Prompt cannot be empty.'),
    model: z.string().min(1, 'Model cannot be empty.'),
    quality: z.enum(['auto', 'low', 'medium', 'high']).default('auto'),
    size: z.string().default('auto'),
  }),
  response: {
    202: z.object({
      jobId: z.string().uuid(),
    }),
  },
}

export const getJobStatusSchema = {
  params: z.object({
    jobId: z.string().uuid('Invalid job ID format.'),
  }),
  response: {
    200: z.object({
      id: z.string().uuid(),
      status: z.enum(['pending', 'processing', 'completed', 'failed']),
      output_data: z.record(z.any()).nullable(),
      error_log: z.string().nullable(),
    }),
  },
}