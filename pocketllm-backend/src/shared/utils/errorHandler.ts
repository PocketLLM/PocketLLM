import { FastifyReply } from 'fastify'

/**
 * Standardized error handler for Fastify routes.
 * Logs the full error to the console and sends a sanitized, user-friendly error response.
 * @param reply The Fastify reply object.
 * @param error The error caught in the catch block.
 * @param defaultMessage A default message to send if the error is not an instance of Error.
 */
export function handleError(reply: FastifyReply, error: unknown, defaultMessage: string = 'An unexpected internal server error occurred.') {
  console.error('[API Error]:', error);

  let errorMessage = defaultMessage;
  if (error instanceof Error) {
    errorMessage = error.message;
  }

  // Avoid sending a 500 for client-side errors if they're identifiable
  // For now, we'll assume most caught errors are 500s unless specified otherwise.
  if (!reply.sent) {
    reply.status(500).send({
      statusCode: 500,
      error: 'Internal Server Error',
      message: errorMessage,
    });
  }
}
