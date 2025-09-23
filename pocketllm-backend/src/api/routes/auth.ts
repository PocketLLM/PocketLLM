import { FastifyInstance, FastifyPluginOptions } from 'fastify'
import { signUpHandler, signInHandler } from '../v1/controllers/authController.ts'
import { signUpSchema, signInSchema } from '../v1/schemas/authSchemas.ts'

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

}
