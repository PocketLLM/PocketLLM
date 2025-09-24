import { FastifyRequest, FastifyReply } from 'fastify'
import { supabaseAdmin } from '../../../shared/supabaseClient.ts'
import { handleError } from '../../../shared/utils/errorHandler.ts'
import { sendResponse } from '../../../shared/utils/responseHandler.ts'
import fetch from 'node-fetch'
import { z } from 'zod'
import { createEmbeddingSchema } from '../schemas/embeddingSchemas.ts'

type CreateEmbeddingRequest = FastifyRequest<{
  Body: z.infer<typeof createEmbeddingSchema.body>
}>

export async function createEmbeddingHandler(request: CreateEmbeddingRequest, reply: FastifyReply) {
  try {
    const userId = request.user.id;
    const { model_config_id, input } = request.body;

    // 1. Fetch the model configuration to get the base_url and model name
    const { data: config, error: configError } = await supabaseAdmin
      .from('model_configs')
      .select('base_url, model, provider')
      .eq('id', model_config_id)
      .eq('user_id', userId)
      .single();

    if (configError || !config) {
      return handleError(reply, request, configError, 404, 'Model configuration not found.');
    }
    if (config.provider !== 'ollama' || !config.base_url) {
      return handleError(reply, request, null, 400, 'The selected model configuration is not a valid Ollama provider with a base URL.');
    }

    // 2. Call the Ollama /api/embed endpoint
    const response = await fetch(`${config.base_url}/api/embed`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        model: config.model,
        input: input,
        stream: false, // Ensure we get a single response
      }),
    });

    if (!response.ok) {
      const errorBody = await response.text();
      throw new Error(`Ollama API error: ${response.statusText} - ${errorBody}`);
    }

    const jsonData = await response.json();

    // 3. Return the embeddings from the response
    return sendResponse(reply, request, jsonData, null, 200);

  } catch (err) {
    return handleError(reply, request, err, 500, err.message || 'Failed to generate embeddings.');
  }
}
