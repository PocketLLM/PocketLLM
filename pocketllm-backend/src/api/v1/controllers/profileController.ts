import { FastifyRequest, FastifyReply } from 'fastify'
import { supabaseAdmin } from '../../../shared/supabaseClient.ts'
import { handleError } from '../../../shared/utils/errorHandler.ts'
import { sendResponse } from '../../../shared/utils/responseHandler.ts'
import { z } from 'zod'
import { updateProfileSchema } from '../schemas/profileSchemas.ts'

type UpdateProfileRequest = FastifyRequest<{
  Body: z.infer<typeof updateProfileSchema.body>
}>

export async function getProfileHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = request.user.id;
    const { data, error } = await supabaseAdmin
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) {
      return handleError(reply, request, error, 404, 'Profile not found.');
    }

    return sendResponse(reply, request, data, null, 200);
  } catch (err) {
    return handleError(reply, request, err, 500, 'Failed to retrieve profile.');
  }
}

export async function updateProfileHandler(request: UpdateProfileRequest, reply: FastifyReply) {
  try {
    const userId = request.user.id;
    const { data, error } = await supabaseAdmin
      .from('profiles')
      .update(request.body)
      .eq('id', userId)
      .select()
      .single();

    if (error) {
      // Handle unique constraint violation on username
      if (error.code === '23505') {
        return handleError(reply, request, error, 409, 'Username is already taken.');
      }
      return handleError(reply, request, error, 500, 'Failed to update profile.');
    }

    return sendResponse(reply, request, data, null, 200);
  } catch (err) {
    return handleError(reply, request, err, 500, 'An unexpected error occurred while updating the profile.');
  }
}

export async function deleteProfileHandler(request: FastifyRequest, reply: FastifyReply) {
  try {
    const userId = request.user.id;

    // Using the admin client to delete the user from auth.users.
    // The ON DELETE CASCADE in the profiles table will automatically delete the corresponding profile row.
    const { error } = await supabaseAdmin.auth.admin.deleteUser(userId);

    if (error) {
      return handleError(reply, request, error, 500, 'Failed to delete user account.');
    }

    return sendResponse(reply, request, { message: 'User account permanently deleted.' }, null, 200);
  } catch (err) {
    return handleError(reply, request, err, 500, 'An unexpected error occurred while deleting the user account.');
  }
}
