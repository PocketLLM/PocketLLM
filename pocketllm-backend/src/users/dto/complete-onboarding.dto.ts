import { ApiProperty } from '@nestjs/swagger';
import {
  IsBoolean,
  IsDateString,
  IsInt,
  IsOptional,
  IsString,
  IsUrl,
  MaxLength,
  Min,
  Max,
  MinLength,
  ValidateNested,
} from 'class-validator';
import { Type } from 'class-transformer';
import { OnboardingDetailsDto } from './onboarding-details.dto';

export class CompleteOnboardingDto {
  @ApiProperty({ description: 'User full name', example: 'Ada Lovelace' })
  @IsString()
  @MinLength(1, { message: 'Full name cannot be empty.' })
  full_name!: string;

  @ApiProperty({ description: 'Unique username', example: 'adalovelace' })
  @IsString()
  @MinLength(3, { message: 'Username must be at least 3 characters.' })
  username!: string;

  @ApiProperty({
    description: 'Short biography',
    example: 'Working on AI productivity workflows',
    required: false,
  })
  @IsOptional()
  @IsString()
  @MaxLength(500, { message: 'Bio cannot exceed 500 characters.' })
  bio?: string | null;

  @ApiProperty({
    description: 'Date of birth in ISO 8601 format',
    example: '1995-06-15',
    required: false,
  })
  @IsOptional()
  @IsDateString({}, { message: 'Date of birth must be a valid ISO date string.' })
  date_of_birth?: string | null;

  @ApiProperty({ description: 'Profession', example: 'Software Engineer', required: false })
  @IsOptional()
  @IsString()
  profession?: string | null;

  @ApiProperty({
    description: 'How the user heard about PocketLLM',
    example: 'Friend recommendation',
    required: false,
  })
  @IsOptional()
  @IsString()
  heard_from?: string | null;

  @ApiProperty({
    description: 'Avatar URL or selected asset path',
    example: 'https://example.com/avatar.png',
    required: false,
  })
  @IsOptional()
  @IsUrl({}, { message: 'Invalid URL format for avatar.' })
  avatar_url?: string | null;

  @ApiProperty({
    description: 'User age',
    example: 28,
    required: false,
    minimum: 13,
    maximum: 120,
  })
  @IsOptional()
  @IsInt()
  @Min(13)
  @Max(120)
  age?: number | null;

  @ApiProperty({
    description: 'Whether onboarding survey is completed',
    example: true,
    required: false,
  })
  @IsOptional()
  @IsBoolean()
  survey_completed?: boolean;

  @ApiProperty({
    description: 'Structured onboarding answers',
    required: false,
    type: () => OnboardingDetailsDto,
  })
  @IsOptional()
  @ValidateNested()
  @Type(() => OnboardingDetailsDto)
  onboarding?: OnboardingDetailsDto | null;
}
