import { Controller, Get, Put, Delete, Body, UseGuards, Req } from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiBearerAuth } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { UpdateProfileDto } from './dto/update-profile.dto';
import { ProfileDto } from './dto/profile.dto';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';

@ApiTags('Users')
@Controller('users')
@UseGuards(SupabaseAuthGuard)
@ApiBearerAuth()
export class UsersController {
  constructor(private readonly usersService: UsersService) {}

  @Get('profile')
  @ApiOperation({ 
    summary: 'Get user profile',
    description: 'Retrieve the current user\'s profile information'
  })
  @ApiResponse({
    status: 200,
    description: 'Profile retrieved successfully',
    type: ProfileDto,
  })
  @ApiResponse({
    status: 404,
    description: 'Profile not found',
  })
  async getProfile(@Req() request: any): Promise<ProfileDto> {
    const userId = request.user?.id;
    return this.usersService.getProfile(userId);
  }

  @Put('profile')
  @ApiOperation({ 
    summary: 'Update user profile',
    description: 'Update the current user\'s profile information'
  })
  @ApiBody({ type: UpdateProfileDto })
  @ApiResponse({
    status: 200,
    description: 'Profile updated successfully',
    type: ProfileDto,
  })
  @ApiResponse({
    status: 409,
    description: 'Username is already taken',
  })
  async updateProfile(
    @Req() request: any,
    @Body() updateProfileDto: UpdateProfileDto,
  ): Promise<ProfileDto> {
    const userId = request.user?.id;
    return this.usersService.updateProfile(userId, updateProfileDto);
  }

  @Delete('profile')
  @ApiOperation({ 
    summary: 'Delete user account',
    description: 'Permanently delete the current user\'s account and all associated data'
  })
  @ApiResponse({
    status: 200,
    description: 'User account deleted successfully',
    schema: {
      type: 'object',
      properties: {
        message: { type: 'string', example: 'User account permanently deleted.' }
      }
    }
  })
  async deleteProfile(@Req() request: any): Promise<{ message: string }> {
    const userId = request.user?.id;
    return this.usersService.deleteProfile(userId);
  }
}
