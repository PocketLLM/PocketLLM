import { FastifyInstance, FastifyPluginOptions, FastifyRequest, FastifyReply } from 'fastify'
import { signUpHandler, signInHandler } from '../v1/controllers/authController.ts'
import { signUpSchema, signInSchema } from '../v1/schemas/authSchemas.ts'
import { sendResponse } from '../../shared/utils/responseHandler.ts'

export default async function(fastify: FastifyInstance, opts: FastifyPluginOptions) {

  fastify.route({
    method: 'POST',
    url: '/v1/auth/signup',
    schema: signUpSchema,
    handler: signUpHandler
  })

  fastify.route({
    method: 'POST',
    url: '/v1/auth/signin',
    schema: signInSchema,
    handler: signInHandler
  })

  // "Coming Soon" placeholder handler for OAuth providers
  const comingSoonHandler = (request: FastifyRequest, reply: FastifyReply) => {
    return sendResponse(reply, request, null, 'OAuth integration is coming soon.', 501);
  }

  // Placeholder routes for future OAuth integration
  fastify.get('/v1/auth/google', {}, comingSoonHandler);
  fastify.get('/v1/auth/github', {}, comingSoonHandler);
  fastify.get('/v1/auth/facebook', {}, comingSoonHandler);

}
