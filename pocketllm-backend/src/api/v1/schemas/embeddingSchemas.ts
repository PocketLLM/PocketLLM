import { z } from 'zod'

// Schema for the request to the /api/embed endpoint.
// The model is specified in the request body, allowing flexibility.
export const createEmbeddingSchema = {
  body: z.object({
    model_config_id: z.string().uuid('A valid model configuration ID is required.'),
    input: z.union([
      z.string().min(1, "Input cannot be empty."),
      z.array(z.string().min(1, "Input strings cannot be empty.")).min(1, "Input array cannot be empty.")
    ]),
  }).strip(),
  response: {
    200: z.object({
        // The structure from Ollama's /api/embed is an object containing an array of embeddings.
        embeddings: z.array(z.array(z.number())),
    }),
  },
};
