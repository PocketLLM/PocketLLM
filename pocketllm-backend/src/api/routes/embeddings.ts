import { FastifyInstance, FastifyPluginOptions } from 'fastify'
import { createEmbeddingHandler } from '../v1/controllers/embeddingController.ts'
import { createEmbeddingSchema } from '../v1/schemas/embeddingSchemas.ts'

/**
 * Plugin for embedding-related routes.
 * @param fastify The Fastify instance.
 * @param opts Options passed to the plugin.
 */
export default async function(fastify: FastifyInstance, opts: FastifyPluginOptions) {

  // This route is protected by the global authentication hook
  fastify.route({
    method: 'POST',
    url: '/v1/ollama/embeddings',
    schema: createEmbeddingSchema,
    handler: createEmbeddingHandler
  });

}
