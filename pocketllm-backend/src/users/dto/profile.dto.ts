import { ApiProperty } from '@nestjs/swagger';

export class ProfileDto {
  @ApiProperty({ description: 'Profile ID (UUID)' })
  id: string;

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

  @ApiProperty({ description: 'Avatar URL', nullable: true })
  avatar_url: string | null;

  @ApiProperty({ description: 'Whether user has completed the survey' })
  survey_completed: boolean;

  @ApiProperty({ description: 'Profile creation timestamp' })
  created_at: string;

  @ApiProperty({ description: 'Profile last update timestamp' })
  updated_at: string;
}
