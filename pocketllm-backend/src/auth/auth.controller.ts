import { Controller, Post, Body, HttpCode, HttpStatus, UsePipes } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody } from '@nestjs/swagger';
import { AuthService } from './auth.service';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';
import { signUpSchema, signInSchema, SignUpRequest, SignInRequest, AuthResponse } from '../api/v1/schemas/auth.schemas';

@ApiTags('Authentication')
@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Post('signup')
  @HttpCode(HttpStatus.CREATED)
  @UsePipes(new ZodValidationPipe(signUpSchema.body))
  @ApiOperation({
    summary: 'Sign up a new user',
    description: 'Register a new user account with email and password'
  })
  @ApiResponse({
    status: 201,
    description: 'User successfully created',
  })
  @ApiResponse({
    status: 400,
    description: 'Bad request - invalid input',
  })
  @ApiResponse({
    status: 409,
    description: 'Conflict - user already exists',
  })
  async signUp(@Body() signUpDto: SignUpRequest): Promise<AuthResponse> {
    return this.authService.signUp(signUpDto);
  }

  @Post('signin')
  @HttpCode(HttpStatus.OK)
  @UsePipes(new ZodValidationPipe(signInSchema.body))
  @ApiOperation({
    summary: 'Sign in an existing user',
    description: 'Authenticate a user with email and password'
  })
  @ApiResponse({
    status: 200,
    description: 'User successfully authenticated',
  })
  @ApiResponse({
    status: 401,
    description: 'Unauthorized - invalid credentials',
  })
  async signIn(@Body() signInDto: SignInRequest): Promise<AuthResponse> {
    return this.authService.signIn(signInDto);
  }
}
