import { z } from 'zod';

// Profile Schema
export const profileSchema = z.object({
  id: z.string().uuid(),
  full_name: z.string().nullable(),
  username: z.string().nullable(),
  bio: z.string().nullable(),
  date_of_birth: z.string().nullable(),
  profession: z.string().nullable(),
  avatar_url: z.string().url().nullable(),
  survey_completed: z.boolean(),
  created_at: z.string(),
  updated_at: z.string(),
});

// Update Profile Schema
export const updateProfileSchema = {
  body: z.object({
    full_name: z.string().min(1, 'Full name cannot be empty.').nullable().optional(),
    username: z.string().min(3, 'Username must be at least 3 characters.').nullable().optional(),
    bio: z.string().max(500, 'Bio cannot exceed 500 characters.').nullable().optional(),
    date_of_birth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date of birth must be in YYYY-MM-DD format.').nullable().optional(),
    profession: z.string().nullable().optional(),
    avatar_url: z.string().url('Invalid URL format for avatar.').nullable().optional(),
    survey_completed: z.boolean().optional(),
  }),
};

// Get Profile Schema (for params)
export const getProfileSchema = {
  params: z.object({
    userId: z.string().uuid('Invalid user ID format.').optional(),
  }),
};

// Type exports for TypeScript
export type Profile = z.infer<typeof profileSchema>;
export type UpdateProfileRequest = z.infer<typeof updateProfileSchema.body>;
export type GetProfileParams = z.infer<typeof getProfileSchema.params>;
