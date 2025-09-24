import { Injectable, Logger, BadRequestException, UnauthorizedException } from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { SignUpRequest, SignInRequest, AuthResponse } from '../api/v1/schemas/auth.schemas';

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

      // Admin createUser doesn't return a session, only user data
      if (data.user) {
        return {
          user: data.user as any,
          session: null,
          message: 'User created successfully. Please sign in to get a session.',
        };
      }

      throw new BadRequestException('Failed to create user.');
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
}
