import { FastifyRequest, FastifyReply } from 'fastify'
import { supabaseAdmin } from '../../../shared/supabaseClient.ts'
import { handleError } from '../../../shared/utils/errorHandler.ts'
import { encrypt } from '../../../shared/utils/encryption.ts'
import { z } from 'zod'
import { createModelConfigSchema, updateModelConfigSchema, getModelConfigSchema, deleteModelConfigSchema } from '../schemas/modelSchemas.ts'

// Helper function to format the database record for the client response.
// It removes the encrypted API key and adds a boolean to indicate if a key is set.
const formatResponse = (dbRecord: any) => {
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
                api_key_encrypted: encrypt(api_key),
                user_id: userId,
            })
            .select()
            .single();

        if (error) throw error;
        return reply.status(201).send(formatResponse(data));
    } catch (err) {
        handleError(reply, err, 'Failed to create model configuration.');
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
        return reply.status(200).send(data.map(formatResponse));
    } catch (err) {
        handleError(reply, err, 'Failed to list model configurations.');
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

        if (error) return reply.status(404).send({ error: 'Model configuration not found.' });
        return reply.status(200).send(formatResponse(data));
    } catch (err) {
        handleError(reply, err, 'Failed to retrieve model configuration.');
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
        return reply.status(200).send(formatResponse(data));
    } catch (err) {
        handleError(reply, err, 'Failed to update model configuration.');
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
            // This can happen if the row doesn't exist or RLS fails.
            return reply.status(404).send({ error: 'Model configuration not found or you do not have permission to delete it.' });
        }

        return reply.status(204).send(null);
    } catch (err) {
        handleError(reply, err, 'Failed to delete model configuration.');
    }
}
