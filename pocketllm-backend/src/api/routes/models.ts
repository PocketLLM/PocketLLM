import { FastifyInstance, FastifyPluginOptions, FastifyRequest, FastifyReply } from 'fastify'
import {
    createModelConfigHandler,
    listModelConfigsHandler,
    getModelConfigHandler,
    updateModelConfigHandler,
    deleteModelConfigHandler,
    listOllamaModelsHandler,
    getOllamaModelDetailHandler
} from '../v1/controllers/modelController.ts'
import { sendResponse } from '../../shared/utils/responseHandler.ts'
import {
    createModelConfigSchema,
    listModelConfigsSchema,
    getModelConfigSchema,
    updateModelConfigSchema,
    deleteModelConfigSchema
} from '../v1/schemas/modelSchemas.ts'

export default async function(fastify: FastifyInstance, opts: FastifyPluginOptions) {

  fastify.route({
    method: 'POST',
    url: '/v1/model-configs',
    schema: createModelConfigSchema,
    handler: createModelConfigHandler
  })

  fastify.route({
    method: 'GET',
    url: '/v1/model-configs',
    schema: listModelConfigsSchema,
    handler: listModelConfigsHandler
  })

  fastify.route({
    method: 'GET',
    url: '/v1/model-configs/:id',
    schema: getModelConfigSchema,
    handler: getModelConfigHandler
  })

  fastify.route({
    method: 'PATCH',
    url: '/v1/model-configs/:id',
    schema: updateModelConfigSchema,
    handler: updateModelConfigHandler
  })

  fastify.route({
    method: 'DELETE',
    url: '/v1/model-configs/:id',
    schema: deleteModelConfigSchema,
    handler: deleteModelConfigHandler
  })

  // =================================================================
  // OLLAMA-SPECIFIC ROUTES
  // =================================================================

  fastify.route({
    method: 'GET',
    url: '/v1/ollama/models',
    // No schema here as the response comes directly from Ollama
    handler: listOllamaModelsHandler
  })

  fastify.route({
    method: 'GET',
    url: '/v1/ollama/models/:modelName',
    handler: getOllamaModelDetailHandler
  })

  // "Coming Soon" placeholder handler for more complex Ollama operations
  const comingSoonHandler = (request: FastifyRequest, reply: FastifyReply) => {
    return sendResponse(reply, request, null, 'This feature is coming soon.', 501);
  }

  fastify.post('/v1/ollama/models/pull', { handler: comingSoonHandler });
  fastify.delete('/v1/ollama/models', { handler: comingSoonHandler });
  fastify.post('/v1/ollama/models/copy', { handler: comingSoonHandler });
  fastify.post('/v1/ollama/models/push', { handler: comingSoonHandler });

}
