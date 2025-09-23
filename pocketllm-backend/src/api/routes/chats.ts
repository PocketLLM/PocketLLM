import { FastifyInstance, FastifyPluginOptions } from 'fastify'
import { handleNewMessage } from '../v1/controllers/chatController.ts'
import { createMessageSchema } from '../v1/schemas/chatSchemas.ts'

export default async function(fastify: FastifyInstance, opts: FastifyPluginOptions) {
  fastify.route({
    method: 'POST',
    url: '/v1/chats/:chatId/messages',
    schema: createMessageSchema,
    // The 'authenticate' preHandler should be applied in the parent plugin or globally
    // to ensure request.user is populated.
    handler: handleNewMessage
  })
}
