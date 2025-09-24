import { FastifyRequest, FastifyReply } from 'fastify'
import { supabaseAdmin } from '../../../shared/supabaseClient.ts'
import { handleError } from '../../../shared/utils/errorHandler.ts'
import { sendResponse } from '../../../shared/utils/responseHandler.ts'
import { z } from 'zod'
import { signUpSchema, signInSchema } from '../schemas/authSchemas.ts'

type SignUpRequest = FastifyRequest<{
  Body: z.infer<typeof signUpSchema.body>
}>

type SignInRequest = FastifyRequest<{
  Body: z.infer<typeof signInSchema.body>
}>

export async function signUpHandler(request: SignUpRequest, reply: FastifyReply) {
  try {
    const { email, password } = request.body
    const { data, error } = await supabaseAdmin.auth.signUp({
      email,
      password,
    })

    if (error) {
      // Use handleError for consistency, passing Supabase error status
      return handleError(reply, request, error, error.status || 400, error.message);
    }

    // Handle case where email confirmation is required
    if (data.user && !data.session) {
        return sendResponse(reply, request, { ...data, message: 'Sign up successful. Please check your email to confirm your account.' }, null, 200);
    }

    return sendResponse(reply, request, data, null, 201);
  } catch (err) {
    return handleError(reply, request, err, 500, 'Failed to sign up.');
  }
}

export async function signInHandler(request: SignInRequest, reply: FastifyReply) {
  try {
    const { email, password } = request.body
    const { data, error } = await supabaseAdmin.auth.signInWithPassword({
      email,
      password,
    })

    if (error) {
      return handleError(reply, request, error, error.status || 401, error.message);
    }

    return sendResponse(reply, request, data, null, 200);
  } catch (err) {
    return handleError(reply, request, err, 500, 'Failed to sign in.');
  }
}
