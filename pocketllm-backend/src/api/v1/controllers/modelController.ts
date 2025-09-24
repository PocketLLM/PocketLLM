import { FastifyRequest, FastifyReply } from 'fastify'
import fetch from 'node-fetch'
import { supabaseAdmin } from '../../../shared/supabaseClient.ts'
import { handleError } from '../../../shared/utils/errorHandler.ts'
import { sendResponse } from '../../../shared/utils/responseHandler.ts'
import { encrypt } from '../../../shared/utils/encryption.ts'
import { z } from 'zod'
import { createModelConfigSchema, updateModelConfigSchema, getModelConfigSchema, deleteModelConfigSchema } from '../schemas/modelSchemas.ts'

// Helper function to format the database record for the client response.
// It removes the encrypted API key and adds a boolean to indicate if a key is set.
const formatResponse = (dbRecord: any) => {
    if (!dbRecord) return null;
    const { api_key_encrypted, ...rest } = dbRecord;
    return {
        ...rest,
        is_api_key_set: !!api_key_encrypted,
    };
};

export async function createModelConfigHandler(request: FastifyRequest<{ Body: z.infer<typeof createModelConfigSchema.body> }>, reply: FastifyReply) {
    try {
        const userId = request.user.id;
        const { api_key, ...restOfBody } = request.body;

        const { data, error } = await supabaseAdmin
            .from('model_configs')
            .insert({
                ...restOfBody,
                api_key_encrypted: api_key ? encrypt(api_key) : null,
                user_id: userId,
            })
            .select()
            .single();

        if (error) throw error;
        return sendResponse(reply, request, formatResponse(data), null, 201);
    } catch (err) {
        handleError(reply, request, err, 500, 'Failed to create model configuration.');
    }
}

export async function listModelConfigsHandler(request: FastifyRequest, reply: FastifyReply) {
    try {
        const userId = request.user.id;
        const { data, error } = await supabaseAdmin
            .from('model_configs')
            .select()
            .eq('user_id', userId)
            .order('created_at', { ascending: false });

        if (error) throw error;
        return sendResponse(reply, request, data.map(formatResponse), null, 200);
    } catch (err) {
        handleError(reply, request, err, 500, 'Failed to list model configurations.');
    }
}

export async function getModelConfigHandler(request: FastifyRequest<{ Params: z.infer<typeof getModelConfigSchema.params> }>, reply: FastifyReply) {
    try {
        const userId = request.user.id;
        const { id } = request.params;
        const { data, error } = await supabaseAdmin
            .from('model_configs')
            .select()
            .eq('id', id)
            .eq('user_id', userId)
            .single();

        if (error || !data) {
            return handleError(reply, request, error, 404, 'Model configuration not found.');
        }
        return sendResponse(reply, request, formatResponse(data), null, 200);
    } catch (err) {
        handleError(reply, request, err, 500, 'Failed to retrieve model configuration.');
    }
}

export async function updateModelConfigHandler(request: FastifyRequest<{ Params: z.infer<typeof updateModelConfigSchema.params>, Body: z.infer<typeof updateModelConfigSchema.body> }>, reply: FastifyReply) {
    try {
        const userId = request.user.id;
        const { id } = request.params;
        const { api_key, ...restOfBody } = request.body;

        const updatePayload: Record<string, any> = { ...restOfBody };
        if (api_key) {
            updatePayload.api_key_encrypted = encrypt(api_key);
        }

        const { data, error } = await supabaseAdmin
            .from('model_configs')
            .update(updatePayload)
            .eq('id', id)
            .eq('user_id', userId)
            .select()
            .single();

        if (error) throw error;
        return sendResponse(reply, request, formatResponse(data), null, 200);
    } catch (err) {
        handleError(reply, request, err, 500, 'Failed to update model configuration.');
    }
}

export async function deleteModelConfigHandler(request: FastifyRequest<{ Params: z.infer<typeof deleteModelConfigSchema.params> }>, reply: FastifyReply) {
    try {
        const userId = request.user.id;
        const { id } = request.params;

        const { error } = await supabaseAdmin
            .from('model_configs')
            .delete()
            .eq('id', id)
            .eq('user_id', userId);

        if (error) {
            return handleError(reply, request, error, 404, 'Model configuration not found or you do not have permission to delete it.');
        }

        return sendResponse(reply, request, null, null, 204);
    } catch (err) {
        handleError(reply, request, err, 500, 'Failed to delete model configuration.');
    }
}

// =================================================================
// OLLAMA-SPECIFIC HANDLERS
// =================================================================

// Helper to get the default Ollama configuration for a user
async function getDefaultOllamaConfig(userId: string) {
    const { data, error } = await supabaseAdmin
        .from('model_configs')
        .select('base_url')
        .eq('user_id', userId)
        .eq('provider', 'ollama')
        .eq('is_default', true)
        .single();

    if (error || !data || !data.base_url) {
        throw new Error('A default Ollama configuration is required for this operation.');
    }
    return data;
}

export async function listOllamaModelsHandler(request: FastifyRequest, reply: FastifyReply) {
    try {
        const userId = request.user.id;
        const config = await getDefaultOllamaConfig(userId);

        const response = await fetch(`${config.base_url}/api/tags`);
        if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`Failed to fetch models from Ollama: ${response.statusText} - ${errorBody}`);
        }
        const jsonData = await response.json();
        // We don't need to validate here because we trust the Ollama API response format defined in our schemas
        // const validatedData = ollamaListModelsResponseSchema.parse(jsonData);

        return sendResponse(reply, request, jsonData, null, 200);
    } catch (err) {
        handleError(reply, request, err, 500, err.message);
    }
}

export async function getOllamaModelDetailHandler(request: FastifyRequest<{ Params: { modelName: string } }>, reply: FastifyReply) {
    try {
        const userId = request.user.id;
        const { modelName } = request.params;
        const config = await getDefaultOllamaConfig(userId);

        const response = await fetch(`${config.base_url}/api/show`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: modelName }),
        });

        if (!response.ok) {
            const errorBody = await response.text();
            throw new Error(`Failed to fetch model details from Ollama: ${response.statusText} - ${errorBody}`);
        }
        const jsonData = await response.json();
        // We don't need to validate here because we trust the Ollama API response format defined in our schemas
        // const validatedData = ollamaShowModelResponseSchema.parse(jsonData);

        return sendResponse(reply, request, jsonData, null, 200);
    } catch (err) {
        handleError(reply, request, err, 500, err.message);
    }
}
