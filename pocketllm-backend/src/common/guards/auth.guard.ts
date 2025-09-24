import {
  CanActivate,
  ExecutionContext,
  Injectable,
  Logger,
  UnauthorizedException,
} from '@nestjs/common';
import { SupabaseService } from '../services/supabase.service';

@Injectable()
export class AuthGuard implements CanActivate {
  private readonly logger = new Logger(AuthGuard.name);

  constructor(private readonly supabaseService: SupabaseService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest();
    const authorization =
      request.headers['authorization'] ?? request.headers['Authorization'];

    if (!authorization || typeof authorization !== 'string') {
      throw new UnauthorizedException('Authorization header is missing.');
    }

    const [scheme, token] = authorization.split(' ');

    if (scheme !== 'Bearer' || !token) {
      throw new UnauthorizedException('Invalid authorization header format.');
    }

    try {
      const { data, error } = await this.supabaseService.auth.getUser(token);

      if (error || !data?.user) {
        throw new UnauthorizedException('Invalid or expired token.');
      }

      request.user = data.user;
      return true;
    } catch (error) {
      if (error instanceof UnauthorizedException) {
        throw error;
      }

      this.logger.error('Authentication guard failed', error as Error);
      throw new UnauthorizedException('Authentication failed.');
    }
  }
}
