import { FastifyInstance, FastifyPluginOptions } from 'fastify'
import { getProfileHandler, updateProfileHandler, deleteProfileHandler } from '../v1/controllers/profileController.ts'
import { getProfileSchema, updateProfileSchema } from '../v1/schemas/profileSchemas.ts'

/**
 * Plugin for profile-related routes.
 * These routes are protected and require authentication.
 * @param fastify The Fastify instance.
 * @param opts Options passed to the plugin.
 */
export default async function(fastify: FastifyInstance, opts: FastifyPluginOptions) {

  // Route to get the current authenticated user's profile
  fastify.route({
    method: 'GET',
    url: '/v1/profiles/me',
    schema: getProfileSchema,
    handler: getProfileHandler
  });

  // Route to update the current user's profile
  fastify.route({
    method: 'PUT',
    url: '/v1/profiles/me',
    schema: updateProfileSchema,
    handler: updateProfileHandler
  });

  // Route to delete the current user's account
  fastify.route({
    method: 'DELETE',
    url: '/v1/profiles/me',
    handler: deleteProfileHandler
  });

}
