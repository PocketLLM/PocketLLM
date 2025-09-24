import { z } from 'zod';

// Sign Up Schema
export const signUpSchema = {
  body: z.object({
    email: z.string().email('Invalid email format.'),
    password: z.string().min(8, 'Password must be at least 8 characters long.'),
  }),
};

// Sign In Schema
export const signInSchema = {
  body: z.object({
    email: z.string().email('Invalid email format.'),
    password: z.string().min(8, 'Password must be at least 8 characters long.'),
  }),
};

// User Schema
export const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  created_at: z.string(),
  aud: z.string().optional(),
  role: z.string().optional(),
});

// Session Schema
export const sessionSchema = z.object({
  access_token: z.string(),
  refresh_token: z.string(),
  expires_in: z.number(),
  token_type: z.string(),
  user: userSchema,
});

// Auth Response Schema
export const authResponseSchema = z.object({
  user: userSchema.nullable(),
  session: sessionSchema.nullable(),
  message: z.string().optional(),
});

// Type exports for TypeScript
export type SignUpRequest = z.infer<typeof signUpSchema.body>;
export type SignInRequest = z.infer<typeof signInSchema.body>;
export type User = z.infer<typeof userSchema>;
export type Session = z.infer<typeof sessionSchema>;
export type AuthResponse = z.infer<typeof authResponseSchema>;
