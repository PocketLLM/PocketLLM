import { ApiProperty } from '@nestjs/swagger';
import { IsArray, IsOptional, IsString } from 'class-validator';

export class OnboardingDetailsDto {
  @ApiProperty({
    description: 'Primary goal or reason for using PocketLLM',
    example: 'Improve daily productivity with AI assistance',
    required: false,
  })
  @IsOptional()
  @IsString()
  primary_goal?: string;

  @ApiProperty({
    description: 'Topics or interests the user cares about',
    example: ['Productivity', 'Coding'],
    required: false,
    type: [String],
  })
  @IsOptional()
  @IsArray()
  @IsString({ each: true })
  interests?: string[];

  @ApiProperty({
    description: 'User self-reported experience level with AI tools',
    example: 'Intermediate',
    required: false,
  })
  @IsOptional()
  @IsString()
  experience_level?: string;

  @ApiProperty({
    description: 'How frequently the user expects to use the product',
    example: 'Daily',
    required: false,
  })
  @IsOptional()
  @IsString()
  usage_frequency?: string;

  @ApiProperty({
    description: 'Any additional notes captured during onboarding',
    example: 'Prefers concise answers and actionable steps.',
    required: false,
  })
  @IsOptional()
  @IsString()
  other_notes?: string;
}
