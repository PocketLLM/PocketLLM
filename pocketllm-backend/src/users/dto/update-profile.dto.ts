import { IsString, IsOptional, IsUrl, IsBoolean, MinLength, MaxLength, Matches } from 'class-validator';
import { ApiProperty } from '@nestjs/swagger';

export class UpdateProfileDto {
  @ApiProperty({
    description: 'User full name',
    example: 'John Doe',
    required: false,
  })
  @IsOptional()
  @IsString()
  @MinLength(1, { message: 'Full name cannot be empty.' })
  full_name?: string | null;

  @ApiProperty({
    description: 'Username (minimum 3 characters)',
    example: 'johndoe',
    required: false,
  })
  @IsOptional()
  @IsString()
  @MinLength(3, { message: 'Username must be at least 3 characters.' })
  username?: string | null;

  @ApiProperty({
    description: 'User bio (maximum 500 characters)',
    example: 'Software developer passionate about AI',
    required: false,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500, { message: 'Bio cannot exceed 500 characters.' })
  bio?: string | null;

  @ApiProperty({
    description: 'Date of birth in YYYY-MM-DD format',
    example: '1990-01-15',
    required: false,
  })
  @IsOptional()
  @IsString()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'Date of birth must be in YYYY-MM-DD format.' })
  date_of_birth?: string | null;

  @ApiProperty({
    description: 'User profession',
    example: 'Software Engineer',
    required: false,
  })
  @IsOptional()
  @IsString()
  profession?: string | null;

  @ApiProperty({
    description: 'Avatar URL',
    example: 'https://example.com/avatar.jpg',
    required: false,
  })
  @IsOptional()
  @IsUrl({}, { message: 'Invalid URL format for avatar.' })
  avatar_url?: string | null;

  @ApiProperty({
    description: 'Whether user has completed the survey',
    example: true,
    required: false,
  })
  @IsOptional()
  @IsBoolean()
  survey_completed?: boolean;
}
