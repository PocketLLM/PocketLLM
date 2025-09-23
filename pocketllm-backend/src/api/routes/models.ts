import { FastifyInstance, FastifyPluginOptions } from 'fastify'
import {
    createModelConfigHandler,
    listModelConfigsHandler,
    getModelConfigHandler,
    updateModelConfigHandler,
    deleteModelConfigHandler
} from '../v1/controllers/modelController.ts'
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

}
