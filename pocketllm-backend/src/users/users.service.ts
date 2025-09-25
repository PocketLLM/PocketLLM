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
import { User } from '@supabase/supabase-js';

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
        .maybeSingle();

      if (error) {
        this.logger.error('Supabase get profile error:', error);
        throw new NotFoundException('Profile not found.');
      }

      if (!data) {
        throw new NotFoundException('Profile not found.');
      }

      const authUser = await this.fetchAuthUser(userId);
      return this.normalizeProfile(data, authUser);
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
        .maybeSingle();

      if (error) {
        this.logger.error('Supabase update profile error:', error);

        if (error.code === '23505') {
          throw new ConflictException('Username is already taken.');
        }

        throw new InternalServerErrorException('Failed to update profile.');
      }

      if (!data) {
        throw new InternalServerErrorException('Profile update did not return any data.');
      }

      const authUser = await this.fetchAuthUser(userId);
      return this.normalizeProfile(data, authUser);
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

  private async fetchAuthUser(userId: string): Promise<User | null> {
    try {
      const { data, error } = await this.supabaseService.auth.admin.getUserById(userId);
      if (error) {
        this.logger.warn(`Failed to fetch auth user ${userId}:`, error);
        return null;
      }
      return data?.user ?? null;
    } catch (error) {
      this.logger.warn(`Unexpected error while fetching auth user ${userId}:`, error);
      return null;
    }
  }

  private normalizeProfile(profile: any, authUser: User | null): ProfileDto {
    const email = this.resolveEmail(profile, authUser);

    const normalized: ProfileDto = {
      id: profile.id,
      email,
      full_name: this.normalizeNullableString(profile.full_name),
      username: this.normalizeNullableString(profile.username),
      bio: this.normalizeNullableString(profile.bio),
      date_of_birth: this.normalizeDateOfBirth(profile.date_of_birth),
      profession: this.normalizeNullableString(profile.profession),
      heard_from: this.normalizeNullableString(profile.heard_from),
      avatar_url: this.normalizeNullableString(profile.avatar_url),
      survey_completed: Boolean(profile.survey_completed),
      created_at: this.formatDate(profile.created_at) ?? new Date().toISOString(),
      updated_at: this.formatDate(profile.updated_at) ?? this.formatDate(profile.created_at) ?? new Date().toISOString(),
      deletion_status: profile.deletion_status ?? (profile.deletion_scheduled_for ? 'pending' : 'active'),
      deletion_requested_at: this.formatDate(profile.deletion_requested_at),
      deletion_scheduled_for: this.formatDate(profile.deletion_scheduled_for),
    };

    return normalized;
  }

  private resolveEmail(profile: any, authUser: User | null): string {
    const profileEmail = typeof profile?.email === 'string' ? profile.email : null;
    if (profileEmail && !this.isPlaceholderEmail(profileEmail)) {
      return profileEmail;
    }

    const candidateEmail = authUser?.email ?? authUser?.user_metadata?.email;
    if (candidateEmail && typeof candidateEmail === 'string') {
      return candidateEmail;
    }

    const identityEmail = authUser?.identities?.find((identity) => identity?.identity_data?.email)?.identity_data
      ?.email;
    if (identityEmail) {
      return identityEmail;
    }

    return '';
  }

  private formatDate(value: any): string | null {
    if (!value) {
      return null;
    }

    if (value instanceof Date) {
      return value.toISOString();
    }

    if (typeof value === 'string') {
      const parsed = new Date(value);
      if (!Number.isNaN(parsed.getTime())) {
        return parsed.toISOString();
      }
      return value;
    }

    if (typeof value === 'number') {
      const parsed = new Date(value);
      if (!Number.isNaN(parsed.getTime())) {
        return parsed.toISOString();
      }
    }

    return null;
  }

  private normalizeNullableString(value: any): string | null {
    if (value === null || value === undefined) {
      return null;
    }

    if (typeof value === 'string') {
      const trimmed = value.trim();
      return trimmed.length > 0 ? trimmed : null;
    }

    if (value instanceof Date) {
      return value.toISOString();
    }

    if (typeof value === 'number') {
      const parsed = new Date(value);
      if (!Number.isNaN(parsed.getTime())) {
        return parsed.toISOString();
      }
    }

    return String(value);
  }

  private normalizeDateOfBirth(value: any): string | null {
    const normalized = this.normalizeNullableString(value);
    if (!normalized) {
      return null;
    }

    if (/^\d{4}-\d{2}-\d{2}$/.test(normalized)) {
      return normalized;
    }

    const iso = this.formatDate(value);
    if (iso) {
      return iso.substring(0, 10);
    }

    return normalized;
  }

  private isPlaceholderEmail(email: string): boolean {
    return typeof email === 'string' && email.endsWith('@placeholder.pocketllm');
  }
}
