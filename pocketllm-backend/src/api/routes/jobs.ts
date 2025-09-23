import { FastifyInstance, FastifyPluginOptions } from 'fastify'
import { handleNewImageJob, getJobStatus } from '../v1/controllers/imageController.ts'
import { createImageJobSchema, getJobStatusSchema } from '../v1/schemas/imageSchemas.ts'

export default async function(fastify: FastifyInstance, opts: FastifyPluginOptions) {
  fastify.route({
    method: 'POST',
    url: '/v1/jobs/image-generation',
    schema: createImageJobSchema,
    handler: handleNewImageJob
  })

  fastify.route({
    method: 'GET',
    url: '/v1/jobs/:jobId',
    schema: getJobStatusSchema,
    handler: getJobStatus
  })
}
