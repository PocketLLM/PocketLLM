import {
  Injectable,
  Logger,
  NotFoundException,
  ConflictException,
  InternalServerErrorException,
  UnauthorizedException,
} from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ProfileDto } from './dto/profile.dto';

@Injectable()
export class UsersService {
  private readonly logger = new Logger(UsersService.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  /**
   * Get user profile by user ID
   * @param userId The user ID
   * @returns User profile data
   */
  async getProfile(userId: string): Promise<ProfileDto> {
    if (!userId) {
      throw new UnauthorizedException('User authentication required to retrieve profile.');
    }

    try {
      const { data, error } = await this.supabaseService
        .from('profiles')
        .select('*')
        .eq('id', userId)
        .single();

      if (error) {
        this.logger.error('Supabase get profile error:', error);
        throw new NotFoundException('Profile not found.');
      }

      return data as ProfileDto;
    } catch (error) {
      this.logger.error('Failed to retrieve profile:', error);
      
      if (error instanceof NotFoundException) {
        throw error;
      }
      
      throw new InternalServerErrorException('Failed to retrieve profile.');
    }
  }

  /**
   * Update user profile
   * @param userId The user ID
   * @param updateProfileDto Profile update data
   * @returns Updated profile data
   */
  async updateProfile(userId: string, updateProfileDto: UpdateProfileDto): Promise<ProfileDto> {
    if (!userId) {
      throw new UnauthorizedException('User authentication required to update profile.');
    }

    try {
      const { data, error } = await this.supabaseService
        .from('profiles')
        .update(updateProfileDto)
        .eq('id', userId)
        .select()
        .single();

      if (error) {
        this.logger.error('Supabase update profile error:', error);
        
        // Handle unique constraint violation on username
        if (error.code === '23505') {
          throw new ConflictException('Username is already taken.');
        }
        
        throw new InternalServerErrorException('Failed to update profile.');
      }

      return data as ProfileDto;
    } catch (error) {
      this.logger.error('Failed to update profile:', error);
      
      if (error instanceof ConflictException || error instanceof InternalServerErrorException) {
        throw error;
      }
      
      throw new InternalServerErrorException('An unexpected error occurred while updating the profile.');
    }
  }

  /**
   * Delete user account and profile
   * @param userId The user ID
   * @returns Success message
   */
  async deleteProfile(userId: string): Promise<{ message: string }> {
    if (!userId) {
      throw new UnauthorizedException('User authentication required to delete profile.');
    }

    try {
      // Using the admin client to delete the user from auth.users.
      // The ON DELETE CASCADE in the profiles table will automatically delete the corresponding profile row.
      const { error } = await this.supabaseService.auth.admin.deleteUser(userId);

      if (error) {
        this.logger.error('Supabase delete user error:', error);
        throw new InternalServerErrorException('Failed to delete user account.');
      }

      return { message: 'User account permanently deleted.' };
    } catch (error) {
      this.logger.error('Failed to delete user account:', error);
      
      if (error instanceof InternalServerErrorException) {
        throw error;
      }
      
      throw new InternalServerErrorException('An unexpected error occurred while deleting the user account.');
    }
  }
}
