import { FastifyReply, FastifyRequest } from 'fastify'
import { sendResponse } from './responseHandler.ts'

/**
 * Standardized error handler for Fastify routes.
 * Logs the full error to the console and sends a sanitized, user-friendly error response
 * using the standard response format.
 * @param reply The Fastify reply object.
 * @param request The Fastify request object.
 * @param error The error caught in the catch block.
 * @param statusCode The HTTP status code to return.
 * @param defaultMessage A default message to send if the error is not an instance of Error.
 */
export function handleError(
  reply: FastifyReply,
  request: FastifyRequest,
  error: unknown,
  statusCode: number = 500,
  defaultMessage: string = 'An unexpected internal server error occurred.'
) {
  console.error('[API Error]:', error);

  let errorMessage = defaultMessage;
  if (error instanceof Error) {
    // For Supabase errors, the message can be more specific
    if ('__isAuthError' in error || 'code' in error) {
        errorMessage = error.message;
    }
  }

  if (!reply.sent) {
    sendResponse(reply, request, null, errorMessage, statusCode);
  }
}
