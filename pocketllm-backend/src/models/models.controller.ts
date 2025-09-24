import { 
  Controller, 
  Get, 
  Post, 
  Put, 
  Delete, 
  Body, 
  Param, 
  Req, 
  HttpCode, 
  HttpStatus 
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiBearerAuth } from '@nestjs/swagger';
import { ModelsService } from './models.service';

@ApiTags('Models')
@Controller('models')
@ApiBearerAuth()
export class ModelsController {
  constructor(private readonly modelsService: ModelsService) {}

  @Get()
  @ApiOperation({ 
    summary: 'Get available models',
    description: 'Retrieve all available AI models and their configurations'
  })
  @ApiResponse({
    status: 200,
    description: 'Models retrieved successfully',
  })
  async getModels() {
    return this.modelsService.getAvailableModels();
  }

  @Get('user')
  @ApiOperation({ 
    summary: 'Get user model configurations',
    description: 'Retrieve user-specific model configurations'
  })
  @ApiResponse({
    status: 200,
    description: 'User model configurations retrieved successfully',
  })
  async getUserModelConfigs(@Req() request: any) {
    const userId = request.user?.id;
    return this.modelsService.getUserModelConfigs(userId);
  }

  @Post('user')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ 
    summary: 'Save user model configuration',
    description: 'Save or update a user-specific model configuration'
  })
  @ApiResponse({
    status: 201,
    description: 'Model configuration saved successfully',
  })
  async saveUserModelConfig(@Body() configDto: any, @Req() request: any) {
    const userId = request.user?.id;
    return this.modelsService.saveUserModelConfig(userId, configDto);
  }

  @Put('user/:configId')
  @ApiOperation({ 
    summary: 'Update user model configuration',
    description: 'Update an existing user model configuration'
  })
  @ApiResponse({
    status: 200,
    description: 'Model configuration updated successfully',
  })
  async updateUserModelConfig(
    @Param('configId') configId: string,
    @Body() configDto: any,
    @Req() request: any
  ) {
    const userId = request.user?.id;
    return this.modelsService.updateUserModelConfig(configId, userId, configDto);
  }

  @Delete('user/:configId')
  @ApiOperation({ 
    summary: 'Delete user model configuration',
    description: 'Delete a user-specific model configuration'
  })
  @ApiResponse({
    status: 200,
    description: 'Model configuration deleted successfully',
  })
  async deleteUserModelConfig(@Param('configId') configId: string, @Req() request: any) {
    const userId = request.user?.id;
    return this.modelsService.deleteUserModelConfig(configId, userId);
  }

  @Post('test')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Test model configuration',
    description: 'Test a model configuration with a sample prompt'
  })
  @ApiResponse({
    status: 200,
    description: 'Model test completed successfully',
  })
  async testModelConfig(@Body() testDto: any) {
    return this.modelsService.testModelConfig(testDto);
  }

  @Get('providers')
  @ApiOperation({ 
    summary: 'Get supported providers',
    description: 'Retrieve list of supported AI providers'
  })
  @ApiResponse({
    status: 200,
    description: 'Providers retrieved successfully',
  })
  async getSupportedProviders() {
    return this.modelsService.getSupportedProviders();
  }

  @Get('providers/:provider/models')
  @ApiOperation({ 
    summary: 'Get models for provider',
    description: 'Retrieve available models for a specific provider'
  })
  @ApiResponse({
    status: 200,
    description: 'Provider models retrieved successfully',
  })
  async getProviderModels(@Param('provider') provider: string) {
    return this.modelsService.getProviderModels(provider);
  }
}
