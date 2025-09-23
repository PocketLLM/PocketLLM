import { FastifyRequest, FastifyReply } from 'fastify'
import { supabaseAdmin } from '../../../shared/supabaseClient.ts'
import { handleError } from '../../../shared/utils/errorHandler.ts'
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
    // Note: We use the admin client here, but for user-level operations like sign-up,
    // it's functionally similar to the anon key client.
    const { data, error } = await supabaseAdmin.auth.signUp({
      email,
      password,
    })

    if (error) {
      return reply.status(error.status || 400).send({ data: null, error })
    }

    // Handle case where email confirmation is required
    if (data.user && !data.session) {
        return reply.status(200).send({
            data,
            error: { message: 'Sign up successful. Please check your email to confirm your account.' }
        })
    }

    return reply.status(200).send({ data, error: null })
  } catch (err) {
    return handleError(reply, err)
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
      return reply.status(error.status || 401).send({ data: null, error })
    }

    return reply.status(200).send({ data, error: null })
  } catch (err) {
    return handleError(reply, err)
  }
}
