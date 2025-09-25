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
import { CompleteOnboardingDto } from './dto/complete-onboarding.dto';
import { OnboardingDetailsDto } from './dto/onboarding-details.dto';

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
      const authUser = await this.fetchAuthUser(userId);
      const profileRecord = await this.ensureProfileExists(userId, authUser);

      if (!profileRecord) {
        throw new NotFoundException('Profile not found.');
      }

      return this.normalizeProfile(profileRecord, authUser);
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
      const authUser = await this.fetchAuthUser(userId);
      await this.ensureProfileExists(userId, authUser);

      const updatePayload = this.buildProfileMutationPayload(updateProfileDto);

      if (Object.keys(updatePayload).length === 0) {
        const profileRecord = await this.ensureProfileExists(userId, authUser);
        return this.normalizeProfile(profileRecord, authUser);
      }

      const { data, error } = await this.supabaseService
        .from('profiles')
        .update(updatePayload)
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

      const profileRecord = data ?? (await this.ensureProfileExists(userId, authUser));
      return this.normalizeProfile(profileRecord, authUser);
    } catch (error) {
      this.logger.error('Failed to update profile:', error);

      if (error instanceof ConflictException || error instanceof InternalServerErrorException) {
        throw error;
      }

      throw new InternalServerErrorException('An unexpected error occurred while updating the profile.');
    }
  }

  /**
   * Complete onboarding survey and store responses
   * @param userId The user ID
   * @param completeOnboardingDto Onboarding responses
   * @returns Updated profile data
   */
  async completeOnboarding(
    userId: string,
    completeOnboardingDto: CompleteOnboardingDto,
  ): Promise<ProfileDto> {
    if (!userId) {
      throw new UnauthorizedException('User authentication required to complete onboarding.');
    }

    try {
      const authUser = await this.fetchAuthUser(userId);
      const existingProfile = await this.ensureProfileExists(userId, authUser);

      const mutation = this.buildProfileMutationPayload({
        ...completeOnboardingDto,
        survey_completed: completeOnboardingDto.survey_completed ?? true,
      });

      const upsertPayload = this.sanitizeProfilePayload({
        id: userId,
        email:
          this.normalizeIncomingString(existingProfile?.email) ??
          this.resolveEmailFromAuth(authUser) ??
          `${userId}@placeholder.pocketllm`,
        ...mutation,
        survey_completed: completeOnboardingDto.survey_completed ?? true,
      });

      const { data, error } = await this.supabaseService
        .from('profiles')
        .upsert(upsertPayload, { onConflict: 'id' })
        .select()
        .maybeSingle();

      if (error) {
        this.logger.error('Supabase onboarding upsert error:', error);

        if (error.code === '23505') {
          throw new ConflictException('Username is already taken.');
        }

        throw new InternalServerErrorException('Failed to save onboarding responses.');
      }

      const profileRecord = data ?? (await this.ensureProfileExists(userId, authUser));
      return this.normalizeProfile(profileRecord, authUser);
    } catch (error) {
      this.logger.error('Failed to save onboarding responses:', error);

      if (error instanceof ConflictException || error instanceof InternalServerErrorException) {
        throw error;
      }

      throw new InternalServerErrorException('An unexpected error occurred while saving onboarding responses.');
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

  private async ensureProfileExists(userId: string, authUser?: User | null): Promise<any> {
    const { data, error } = await this.supabaseService
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .maybeSingle();

    if (error && error.code !== 'PGRST116') {
      this.logger.error(`Failed to look up profile for user ${userId}:`, error);
      throw new InternalServerErrorException('Unable to verify profile state.');
    }

    if (data) {
      return data;
    }

    const resolvedAuthUser = authUser ?? (await this.fetchAuthUser(userId));
    const fallbackEmail =
      this.resolveEmailFromAuth(resolvedAuthUser) ?? `${userId}@placeholder.pocketllm`;

    const profilePayload = this.sanitizeProfilePayload({
      id: userId,
      email: fallbackEmail,
      full_name: this.normalizeIncomingString(resolvedAuthUser?.user_metadata?.full_name),
      username:
        this.normalizeIncomingString(resolvedAuthUser?.user_metadata?.username) ??
        this.normalizeIncomingString(resolvedAuthUser?.user_metadata?.user_name),
      bio: null,
      date_of_birth: null,
      profession: this.normalizeIncomingString(resolvedAuthUser?.user_metadata?.profession),
      heard_from: this.normalizeIncomingString(resolvedAuthUser?.user_metadata?.heard_from),
      avatar_url:
        this.normalizeIncomingString(resolvedAuthUser?.user_metadata?.avatar_url) ??
        this.normalizeIncomingString(resolvedAuthUser?.user_metadata?.avatarUrl),
      survey_completed: false,
      deletion_status: 'active',
    });

    const { data: created, error: insertError } = await this.supabaseService
      .from('profiles')
      .upsert(profilePayload, { onConflict: 'id' })
      .select()
      .maybeSingle();

    if (insertError) {
      this.logger.error(`Failed to provision profile for user ${userId}:`, insertError);
      throw new InternalServerErrorException('Unable to create user profile.');
    }

    return created;
  }

  private buildProfileMutationPayload(input: Record<string, any>): Record<string, any> {
    const payload: Record<string, any> = {};

    if (Object.prototype.hasOwnProperty.call(input, 'full_name')) {
      payload.full_name = this.normalizeIncomingString(input.full_name);
    }

    if (Object.prototype.hasOwnProperty.call(input, 'username')) {
      payload.username = this.normalizeIncomingString(input.username);
    }

    if (Object.prototype.hasOwnProperty.call(input, 'bio')) {
      payload.bio = this.normalizeIncomingString(input.bio);
    }

    if (Object.prototype.hasOwnProperty.call(input, 'date_of_birth')) {
      payload.date_of_birth = this.formatDateInput(input.date_of_birth);
    }

    if (Object.prototype.hasOwnProperty.call(input, 'profession')) {
      payload.profession = this.normalizeIncomingString(input.profession);
    }

    if (Object.prototype.hasOwnProperty.call(input, 'heard_from')) {
      payload.heard_from = this.normalizeIncomingString(input.heard_from);
    }

    if (Object.prototype.hasOwnProperty.call(input, 'avatar_url')) {
      payload.avatar_url = this.normalizeIncomingString(input.avatar_url);
    }

    if (Object.prototype.hasOwnProperty.call(input, 'survey_completed')) {
      const value = input.survey_completed;
      payload.survey_completed = value === null || value === undefined ? null : Boolean(value);
    }

    if (Object.prototype.hasOwnProperty.call(input, 'age')) {
      payload.age = this.parseAge(input.age);
    }

    if (Object.prototype.hasOwnProperty.call(input, 'onboarding')) {
      payload.onboarding_responses = this.prepareOnboardingResponses(input.onboarding);
    }

    return this.sanitizeProfilePayload(payload);
  }

  private sanitizeProfilePayload(payload: Record<string, any>): Record<string, any> {
    return Object.fromEntries(
      Object.entries(payload).filter(([, value]) => value !== undefined),
    );
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
      age: this.parseAge(profile.age),
      onboarding: this.normalizeOnboardingResponses(profile.onboarding_responses),
      created_at: this.formatDate(profile.created_at) ?? new Date().toISOString(),
      updated_at:
        this.formatDate(profile.updated_at) ??
        this.formatDate(profile.created_at) ??
        new Date().toISOString(),
      deletion_status: profile.deletion_status ?? (profile.deletion_scheduled_for ? 'pending' : 'active'),
      deletion_requested_at: this.formatDate(profile.deletion_requested_at),
      deletion_scheduled_for: this.formatDate(profile.deletion_scheduled_for),
    };

    return normalized;
  }

  private resolveEmail(profile: any, authUser: User | null): string {
    const profileEmail = this.normalizeNullableString(profile?.email);
    if (profileEmail && !this.isPlaceholderEmail(profileEmail)) {
      return profileEmail;
    }

    const authEmail = this.resolveEmailFromAuth(authUser);
    if (authEmail) {
      return authEmail;
    }

    return '';
  }

  private resolveEmailFromAuth(authUser: User | null): string | null {
    const candidateEmail = authUser?.email ?? authUser?.user_metadata?.email;
    if (candidateEmail && typeof candidateEmail === 'string') {
      return candidateEmail;
    }

    const identityEmail = authUser?.identities?.find((identity) => identity?.identity_data?.email)
      ?.identity_data?.email;
    if (identityEmail) {
      return identityEmail;
    }

    return null;
  }

  private prepareOnboardingResponses(
    onboarding: OnboardingDetailsDto | null | undefined,
  ): Record<string, any> | null {
    if (!onboarding) {
      return null;
    }

    const sanitizedEntries = Object.entries(onboarding).reduce<Record<string, any>>(
      (acc, [key, value]) => {
        if (value === undefined || value === null) {
          return acc;
        }

        if (Array.isArray(value)) {
          const cleanedArray = value
            .map((entry) => (typeof entry === 'string' ? entry.trim() : entry))
            .filter((entry) => entry !== null && entry !== undefined && entry !== '');

          if (cleanedArray.length > 0) {
            acc[key] = cleanedArray;
          }
          return acc;
        }

        if (typeof value === 'string') {
          const trimmed = value.trim();
          if (trimmed.length > 0) {
            acc[key] = trimmed;
          }
          return acc;
        }

        acc[key] = value;
        return acc;
      },
      {},
    );

    return Object.keys(sanitizedEntries).length > 0 ? sanitizedEntries : null;
  }

  private normalizeOnboardingResponses(value: any): OnboardingDetailsDto | null {
    if (!value || typeof value !== 'object') {
      return null;
    }

    const result: OnboardingDetailsDto = {};

    if (typeof value.primary_goal === 'string') {
      const trimmed = value.primary_goal.trim();
      if (trimmed) {
        result.primary_goal = trimmed;
      }
    }

    if (Array.isArray(value.interests)) {
      const interests = value.interests
        .filter((item: any) => typeof item === 'string' && item.trim().length > 0)
        .map((item: string) => item.trim());
      if (interests.length > 0) {
        result.interests = interests;
      }
    }

    if (typeof value.experience_level === 'string') {
      const trimmed = value.experience_level.trim();
      if (trimmed) {
        result.experience_level = trimmed;
      }
    }

    if (typeof value.usage_frequency === 'string') {
      const trimmed = value.usage_frequency.trim();
      if (trimmed) {
        result.usage_frequency = trimmed;
      }
    }

    if (typeof value.other_notes === 'string') {
      const trimmed = value.other_notes.trim();
      if (trimmed) {
        result.other_notes = trimmed;
      }
    }

    return Object.keys(result).length > 0 ? result : null;
  }

  private parseAge(value: any): number | null {
    if (value === null || value === undefined) {
      return null;
    }

    const parsed = Number(value);
    if (Number.isNaN(parsed)) {
      return null;
    }

    if (!Number.isFinite(parsed)) {
      return null;
    }

    const rounded = Math.trunc(parsed);
    if (rounded < 13 || rounded > 120) {
      return null;
    }

    return rounded;
  }

  private formatDateInput(value: any): string | null {
    if (value === null || value === undefined) {
      return null;
    }

    if (typeof value === 'string' && /^\d{4}-\d{2}-\d{2}$/.test(value.trim())) {
      return value.trim();
    }

    const parsed = new Date(value);
    if (Number.isNaN(parsed.getTime())) {
      return null;
    }

    return parsed.toISOString().substring(0, 10);
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

  private normalizeIncomingString(value: any): string | null | undefined {
    if (value === undefined) {
      return undefined;
    }

    if (value === null) {
      return null;
    }

    if (typeof value === 'string') {
      const trimmed = value.trim();
      return trimmed.length > 0 ? trimmed : null;
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
