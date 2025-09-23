import { asConst } from 'fastify-zod'
import { z } from 'zod'

const userCore = {
  email: z.string().email('Invalid email format.'),
  password: z.string().min(8, 'Password must be at least 8 characters long.'),
}

const sessionObject = z.object({
  access_token: z.string(),
  refresh_token: z.string(),
  expires_in: z.number(),
  token_type: z.literal('bearer'),
  user: z.object({
    id: z.string().uuid(),
    aud: z.string(),
    role: z.string(),
    email: z.string().email(),
    created_at: z.string(),
  })
}).nullable()

export const signUpSchema = asConst({
  body: z.object({
    ...userCore
  }),
  response: {
    200: z.object({
      data: z.object({
        user: z.object({
          id: z.string().uuid(),
          email: z.string().email(),
          created_at: z.string(),
        }).nullable(),
        session: sessionObject,
      }),
      error: z.any().nullable(),
    })
  }
})

export const signInSchema = asConst({
  body: z.object({
    ...userCore
  }),
  response: signUpSchema.response // Sign-in and sign-up return the same session object
})
