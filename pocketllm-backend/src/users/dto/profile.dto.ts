import { ApiProperty } from '@nestjs/swagger';
import { OnboardingDetailsDto } from './onboarding-details.dto';

export class ProfileDto {
  @ApiProperty({ description: 'Profile ID (UUID)' })
  id: string;

  @ApiProperty({ description: 'User email address' })
  email: string;

  @ApiProperty({ description: 'User full name', nullable: true })
  full_name: string | null;

  @ApiProperty({ description: 'Username', nullable: true })
  username: string | null;

  @ApiProperty({ description: 'User bio', nullable: true })
  bio: string | null;

  @ApiProperty({ description: 'Date of birth in YYYY-MM-DD format', nullable: true })
  date_of_birth: string | null;

  @ApiProperty({ description: 'User profession', nullable: true })
  profession: string | null;

  @ApiProperty({ description: 'How the user heard about the product', nullable: true })
  heard_from: string | null;

  @ApiProperty({ description: 'Avatar URL', nullable: true })
  avatar_url: string | null;

  @ApiProperty({ description: 'User age', nullable: true, example: 27 })
  age: number | null;

  @ApiProperty({
    description: 'Structured onboarding responses captured during signup',
    nullable: true,
    type: () => OnboardingDetailsDto,
  })
  onboarding: OnboardingDetailsDto | null;

  @ApiProperty({ description: 'Whether user has completed the survey' })
  survey_completed: boolean;

  @ApiProperty({ description: 'Account deletion status', example: 'active' })
  deletion_status: string;

  @ApiProperty({ description: 'Timestamp when account deletion was requested', nullable: true })
  deletion_requested_at: string | null;

  @ApiProperty({ description: 'Scheduled timestamp for account deletion', nullable: true })
  deletion_scheduled_for: string | null;

  @ApiProperty({ description: 'Profile creation timestamp' })
  created_at: string;

  @ApiProperty({ description: 'Profile last update timestamp' })
  updated_at: string;
}
