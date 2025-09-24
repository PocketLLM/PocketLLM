import { z } from 'zod'

// Base schema for the public profile data
const profileCoreSchema = z.object({
  full_name: z.string().min(1, 'Full name cannot be empty.').nullable(),
  username: z.string().min(3, 'Username must be at least 3 characters.').nullable(),
  bio: z.string().max(500, 'Bio cannot exceed 500 characters.').nullable(),
  date_of_birth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date of birth must be in YYYY-MM-DD format.').nullable(),
  profession: z.string().nullable(),
  avatar_url: z.string().url('Invalid URL format for avatar.').nullable(),
  survey_completed: z.boolean().default(false),
});

// Schema for the full profile object including read-only fields
export const profileSchema = profileCoreSchema.extend({
  id: z.string().uuid(),
  created_at: z.string(),
  updated_at: z.string(),
});

// Schema for updating a user's profile. All fields are optional.
export const updateProfileSchema = {
  body: profileCoreSchema.partial().strip(), // .partial() makes all fields optional, .strip() removes unknown fields
};

// Schema for the response when fetching a profile
export const getProfileSchema = {
  response: {
    200: profileSchema,
  },
};
