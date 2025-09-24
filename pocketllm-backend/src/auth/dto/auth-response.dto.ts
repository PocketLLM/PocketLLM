import { ApiProperty } from '@nestjs/swagger';

export class UserDto {
  @ApiProperty({ description: 'User ID' })
  id: string;

  @ApiProperty({ description: 'User email' })
  email: string;

  @ApiProperty({ description: 'User creation timestamp' })
  created_at: string;

  @ApiProperty({ description: 'User audience' })
  aud?: string;

  @ApiProperty({ description: 'User role' })
  role?: string;
}

export class SessionDto {
  @ApiProperty({ description: 'Access token' })
  access_token: string;

  @ApiProperty({ description: 'Refresh token' })
  refresh_token: string;

  @ApiProperty({ description: 'Token expiration time in seconds' })
  expires_in: number;

  @ApiProperty({ description: 'Token type', example: 'bearer' })
  token_type: string;

  @ApiProperty({ description: 'User information', type: UserDto })
  user: UserDto;
}

export class AuthResponseDto {
  @ApiProperty({ description: 'User information', type: UserDto, nullable: true })
  user: UserDto | null;

  @ApiProperty({ description: 'Session information', type: SessionDto, nullable: true })
  session: SessionDto | null;

  @ApiProperty({ description: 'Additional message', required: false })
  message?: string;
}
