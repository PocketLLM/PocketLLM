import {
  Injectable,
  Logger,
  BadRequestException,
  UnauthorizedException,
  InternalServerErrorException,
  ConflictException,
} from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { SignUpRequest, SignInRequest, AuthResponse } from '../api/v1/schemas/auth.schemas';
import { PostgrestError } from '@supabase/supabase-js';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);
  private readonly optionalProfileColumns = new Set([
    'email',
    'heard_from',
    'deletion_status',
    'deletion_requested_at',
    'deletion_scheduled_for',
  ]);
  private profileEmailColumnSupported: boolean | null = null;

  constructor(private readonly supabaseService: SupabaseService) {}

  /**
   * Sign up a new user
   * @param signUpDto User registration data
   * @returns Authentication response with user and session data
   */
  async signUp(signUpDto: SignUpRequest): Promise<AuthResponse> {
    try {
      const { email, password } = signUpDto;
      
      const { data, error } = await this.supabaseService.auth.admin.createUser({
        email,
        password,
        email_confirm: true, // Auto-confirm email for admin creation
      });

      if (error) {
        this.logger.error('Supabase sign up error:', error);

        if (this.isDuplicateEmailError(error)) {
          throw new ConflictException('An account with this email already exists.');
        }

        throw new BadRequestException(error.message);
      }

      const user = data.user;

      if (!user) {
        throw new BadRequestException('Failed to create user.');
      }

      await this.ensureProfileForUser(user, {
        emailFallback: email,
        cleanupOnFailure: async () => {
          await this.safeDeleteUser(user.id);
        },
      });

      const { data: signInData, error: signInError } = await this.supabaseService.auth.signInWithPassword({
        email,
        password,
      });

      if (signInError) {
        this.logger.error('Supabase post-signup sign in error:', signInError);
        await this.safeDeleteUser(user.id);
        throw new InternalServerErrorException('Failed to establish session for the new account.');
      }

      await this.ensureProfileForUser(signInData.user, { emailFallback: email });

      return {
        user: signInData.user as any,
        session: signInData.session as any,
        message: 'Account created successfully.',
      };
    } catch (error) {
      this.logger.error('Failed to sign up user:', error);
      
      if (error instanceof BadRequestException || error instanceof ConflictException) {
        throw error;
      }
      
      throw new BadRequestException('Failed to sign up.');
    }
  }

  /**
   * Sign in an existing user
   * @param signInDto User login credentials
   * @returns Authentication response with user and session data
   */
  async signIn(signInDto: SignInRequest): Promise<AuthResponse> {
    try {
      const { email, password } = signInDto;
      
      const { data, error } = await this.supabaseService.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        this.logger.error('Supabase sign in error:', error);
        throw new UnauthorizedException(error.message);
      }

      await this.ensureProfileForUser(data.user, { emailFallback: email });

      return {
        user: data.user as any,
        session: data.session as any,
      };
    } catch (error) {
      this.logger.error('Failed to sign in user:', error);
      
      if (error instanceof UnauthorizedException) {
        throw error;
      }
      
      throw new UnauthorizedException('Failed to sign in.');
    }
  }

  /**
   * Verify a JWT token and get user information
   * @param token JWT token to verify
   * @returns User information if token is valid
   */
  async verifyToken(token: string): Promise<any> {
    try {
      const { data, error } = await this.supabaseService.auth.getUser(token);

      if (error) {
        throw new UnauthorizedException('Invalid token');
      }

      return data.user;
    } catch (error) {
      this.logger.error('Token verification failed:', error);
      throw new UnauthorizedException('Invalid token');
    }
  }

  private async ensureProfileForUser(
    user: any,
    options?: {
      emailFallback?: string;
      cleanupOnFailure?: () => Promise<void>;
    },
  ): Promise<void> {
    if (!user?.id) {
      throw new InternalServerErrorException('Supabase user payload missing identifier.');
    }

    const userId: string = user.id;
    const email = this.resolveEmail(user) ?? options?.emailFallback;

    try {
      const existingProfile = await this.lookupExistingProfile(userId);

      if (existingProfile.error) {
        this.logger.error(`Failed to look up profile for user ${userId}:`, existingProfile.error);
        throw new InternalServerErrorException('Unable to verify profile state.');
      }

      if (existingProfile.data) {
        await this.updateEmailIfMissing(userId, existingProfile.data.email ?? null, email);
        return;
      }

      const fallbackEmail = `${userId}@placeholder.pocketllm`;

      const profilePayload: Record<string, any> = {
        id: userId,
        email: email ?? fallbackEmail,
        full_name: this.extractMetadata(user, 'full_name'),
        username: this.extractMetadata(user, 'username') ?? this.extractMetadata(user, 'user_name'),
        bio: null,
        date_of_birth: null,
        profession: this.extractMetadata(user, 'profession'),
        heard_from: this.extractMetadata(user, 'heard_from'),
        avatar_url:
          this.extractMetadata(user, 'avatar_url') ?? this.extractMetadata(user, 'avatarUrl') ?? null,
        survey_completed: false,
        deletion_status: 'active',
      };

      await this.upsertProfileWithFallback(this.sanitizeProfilePayload(profilePayload));
    } catch (error) {
      if (options?.cleanupOnFailure) {
        await options.cleanupOnFailure().catch((cleanupError) => {
          this.logger.error(`Failed to clean up user ${userId} after profile error:`, cleanupError);
        });
      }

      if (error instanceof InternalServerErrorException) {
        throw error;
      }

      this.logger.error(`Unexpected error while ensuring profile for user ${userId}:`, error);
      throw new InternalServerErrorException('Unexpected error while preparing user profile.');
    }
  }

  private sanitizeProfilePayload(payload: Record<string, any>): Record<string, any> {
    return Object.fromEntries(
      Object.entries(payload).filter(([, value]) => value !== undefined),
    );
  }

  private resolveEmail(user: any): string | null {
    if (user?.email) {
      return user.email;
    }

    const metadataEmail = this.extractMetadata(user, 'email');
    if (metadataEmail) {
      return metadataEmail;
    }

    if (Array.isArray(user?.identities)) {
      for (const identity of user.identities) {
        const identityEmail = identity?.email ?? identity?.identity_data?.email;
        if (identityEmail) {
          return identityEmail;
        }
      }
    }

    return null;
  }

  private extractMetadata(user: any, key: string): string | null {
    const metadata = user?.user_metadata ?? user?.app_metadata ?? {};
    if (metadata && typeof metadata === 'object' && metadata[key]) {
      return metadata[key];
    }
    return null;
  }

  private async updateEmailIfMissing(userId: string, existingEmail: string | null, newEmail?: string | null) {
    if (!newEmail) {
      return;
    }

    if (this.profileEmailColumnSupported === false) {
      return;
    }

    if (existingEmail && !this.isPlaceholderEmail(existingEmail) && existingEmail === newEmail) {
      return;
    }

    if (existingEmail && !this.isPlaceholderEmail(existingEmail)) {
      return;
    }

    try {
      const { error } = await this.supabaseService
        .from('profiles')
        .update({ email: newEmail })
        .eq('id', userId);

      if (error) {
        this.handleProfileUpdateError('email backfill', userId, error);
        if (error.code === '42703') {
          this.profileEmailColumnSupported = false;
        }
      }
    } catch (error) {
      this.logger.warn(`Unexpected error while updating email for profile ${userId}:`, error);
    }
  }

  private handleProfileUpdateError(context: string, userId: string, error: PostgrestError) {
    // Ignore missing column errors to keep compatibility with older schemas.
    if (error?.code === '42703') {
      this.logger.warn(
        `Skipping ${context} for profile ${userId} because the target column is missing in the database schema.`,
      );
      return;
    }

    this.logger.error(`Failed to perform ${context} for profile ${userId}:`, error);
  }

  private async safeDeleteUser(userId: string): Promise<void> {
    try {
      const { error } = await this.supabaseService.auth.admin.deleteUser(userId);
      if (error) {
        this.logger.error(`Failed to delete Supabase user ${userId} after profile provisioning failure:`, error);
      }
    } catch (error) {
      this.logger.error(`Unexpected error while deleting Supabase user ${userId}:`, error);
    }
  }

  private isPlaceholderEmail(email: string): boolean {
    return typeof email === 'string' && email.endsWith('@placeholder.pocketllm');
  }

  private isDuplicateEmailError(error: { message?: string; status?: number; code?: string }): boolean {
    if (!error) {
      return false;
    }

    const normalizedMessage = error.message?.toLowerCase() ?? '';
    return (
      error.status === 409 ||
      error.code === '23505' ||
      normalizedMessage.includes('already registered') ||
      normalizedMessage.includes('duplicate key value violates unique constraint')
    );
  }

  private async lookupExistingProfile(
    userId: string,
  ): Promise<{ data: { id: string; email?: string | null } | null; error: PostgrestError | null }> {
    const selectColumns = this.profileEmailColumnSupported === false ? 'id' : 'id, email';

    const { data, error } = await this.supabaseService
      .from('profiles')
      .select(selectColumns)
      .eq('id', userId)
      .maybeSingle();

    if (error?.code === '42703' && this.profileEmailColumnSupported !== false) {
      this.logger.warn('Profiles table is missing the email column. Falling back to minimal selection.');
      this.profileEmailColumnSupported = false;
      return this.lookupExistingProfile(userId);
    }

    return { data, error };
  }

  private async upsertProfileWithFallback(payload: Record<string, any>): Promise<void> {
    let attempt = { ...payload };
    const attemptedColumns = new Set(Object.keys(attempt));

    while (true) {
      const { error } = await this.supabaseService
        .from('profiles')
        .upsert(attempt, { onConflict: 'id' });

      if (!error) {
        return;
      }

      if (error.code !== '42703') {
        throw error;
      }

      const missingColumn =
        this.extractMissingColumnName(error.message, attemptedColumns) ?? this.findOptionalColumnToRemove(attempt);

      if (!missingColumn) {
        throw error;
      }

      if (missingColumn === 'email') {
        this.profileEmailColumnSupported = false;
      }

      delete attempt[missingColumn];
      attemptedColumns.delete(missingColumn);
      this.optionalProfileColumns.delete(missingColumn);
      this.logger.warn(
        `Removing unsupported column "${missingColumn}" from profile payload to satisfy current schema.`,
      );
    }
  }

  private extractMissingColumnName(
    message: string | undefined,
    attemptedColumns: Set<string>,
  ): string | null {
    if (!message) {
      return null;
    }

    const match = message.match(/column\s+"?([a-zA-Z0-9_]+)"?/i);
    if (!match) {
      return null;
    }

    const candidate = match[1];
    return attemptedColumns.has(candidate) ? candidate : null;
  }

  private findOptionalColumnToRemove(payload: Record<string, any>): string | null {
    for (const column of this.optionalProfileColumns) {
      if (Object.prototype.hasOwnProperty.call(payload, column)) {
        return column;
      }
    }
    return null;
  }
}
