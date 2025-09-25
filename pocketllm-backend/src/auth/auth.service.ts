import {
  Injectable,
  Logger,
  BadRequestException,
  UnauthorizedException,
  InternalServerErrorException,
} from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { SignUpRequest, SignInRequest, AuthResponse } from '../api/v1/schemas/auth.schemas';
import { PostgrestError } from '@supabase/supabase-js';

@Injectable()
export class AuthService {
  private readonly logger = new Logger(AuthService.name);

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

      return {
        user: user as any,
        session: null,
        message: 'User created successfully. Please sign in to get a session.',
      };
    } catch (error) {
      this.logger.error('Failed to sign up user:', error);
      
      if (error instanceof BadRequestException) {
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
      const { data: existingProfile, error: lookupError } = await this.supabaseService
        .from('profiles')
        .select('id, email')
        .eq('id', userId)
        .maybeSingle();

      if (lookupError) {
        this.logger.error(`Failed to look up profile for user ${userId}:`, lookupError);
        throw new InternalServerErrorException('Unable to verify profile state.');
      }

      if (existingProfile) {
        await this.updateEmailIfMissing(userId, existingProfile.email, email);
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

      const { error: insertError } = await this.supabaseService
        .from('profiles')
        .insert(profilePayload);

      if (insertError) {
        this.logger.error(`Failed to provision profile for user ${userId}:`, insertError);
        throw new InternalServerErrorException('Unable to create user profile.');
      }
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
}
