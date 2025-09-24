import { Injectable, CanActivate, ExecutionContext, UnauthorizedException } from '@nestjs/common';
import { Request } from 'express';
import { AuthService } from '../auth.service';

type SupabaseRequest = Request & { user?: Record<string, any> };

@Injectable()
export class SupabaseAuthGuard implements CanActivate {
  constructor(private readonly authService: AuthService) {}

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const request = context.switchToHttp().getRequest<SupabaseRequest>();
    const token = this.extractToken(request);

    if (!token) {
      throw new UnauthorizedException('Authorization token is missing.');
    }

    const user = await this.authService.verifyToken(token);

    if (!user || !user.id) {
      throw new UnauthorizedException('Invalid Supabase user.');
    }

    request.user = {
      ...request.user,
      ...user,
    };

    return true;
  }

  private extractToken(request: SupabaseRequest): string | null {
    const header = request.headers?.authorization;

    if (!header || Array.isArray(header)) {
      return null;
    }

    const [type, token] = header.split(' ');

    if (type !== 'Bearer' || !token) {
      return null;
    }

    return token;
  }
}
