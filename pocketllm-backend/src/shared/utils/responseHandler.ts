import { FastifyReply, FastifyRequest, FastifyInstance } from 'fastify'

// Augment FastifyRequest to include our custom properties for metadata.
declare module 'fastify' {
  interface FastifyRequest {
    requestId: string;
    startTime: [number, number];
  }
}

interface ResponseMetadata {
  timestamp: string;
  requestId: string;
  processingTime: number;
}

interface ApiResponse<T> {
  success: boolean;
  data: T | null;
  error: { message: string } | null;
  metadata: ResponseMetadata;
}

/**
 * Sends a standardized JSON response.
 * @param reply The Fastify reply object.
 * @param request The Fastify request object.
 * @param data The payload to send.
 * @param error An error message, if any.
 * @param statusCode The HTTP status code.
 */
export function sendResponse<T>(
  reply: FastifyReply,
  request: FastifyRequest,
  data: T | null,
  error: string | null = null,
  statusCode: number = 200
) {
  // Calculate processing time from the start time set by the onRequest hook.
  const processingTime = process.hrtime(request.startTime);
  const processingTimeMs = processingTime[0] * 1000 + processingTime[1] / 1e6;

  const response: ApiResponse<T> = {
    success: !error,
    data: data,
    error: error ? { message: error } : null,
    metadata: {
      timestamp: new Date().toISOString(),
      requestId: request.requestId,
      processingTime: parseFloat(processingTimeMs.toFixed(2)),
    },
  };

  reply.code(statusCode).send(response);
}

/**
 * Registers hooks with the Fastify instance to add metadata to each request.
 * This should be called once when the Fastify server is initialized.
 * @param fastify The Fastify instance.
 */
export function addRequestHooks(fastify: FastifyInstance) {
  fastify.addHook('onRequest', (request, reply, done) => {
    // Deno has a global crypto object.
    request.requestId = crypto.randomUUID();
    request.startTime = process.hrtime();
    done();
  });
}
