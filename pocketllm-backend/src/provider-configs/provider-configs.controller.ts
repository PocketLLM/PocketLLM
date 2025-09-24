import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  Patch,
  Post,
  Query,
  Req,
  UseGuards,
  UsePipes,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiResponse, ApiTags } from '@nestjs/swagger';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { ProviderConfigsService } from './provider-configs.service';
import {
  ActivateProviderRequest,
  ProviderModelsQuery,
  ProviderParams,
  UpdateProviderRequest,
  activateProviderSchema,
  providerModelsQuerySchema,
  providerParamsSchema,
  updateProviderSchema,
  providerCodeSchema,
} from '../api/v1/schemas/providers.schemas';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';

@ApiTags('Providers')
@ApiBearerAuth()
@Controller('providers')
@UseGuards(SupabaseAuthGuard)
export class ProviderConfigsController {
  constructor(private readonly providerConfigsService: ProviderConfigsService) {}

  @Get()
  @ApiOperation({
    summary: 'List configured providers',
    description: 'Returns all providers configured for the authenticated user',
  })
  async listProviders(@Req() request: any) {
    return this.providerConfigsService.listProviders(request.user.id);
  }

  @Post('activate')
  @UsePipes(new ZodValidationPipe(activateProviderSchema.body))
  @ApiOperation({
    summary: 'Activate provider',
    description: 'Create or update provider credentials for the authenticated user',
  })
  @ApiResponse({ status: 200, description: 'Provider activated successfully' })
  async activateProvider(@Body() body: ActivateProviderRequest, @Req() request: any) {
    return this.providerConfigsService.activateProvider(request.user.id, body);
  }

  @Patch(':provider')
  @UsePipes(new ZodValidationPipe(updateProviderSchema.body))
  @ApiOperation({
    summary: 'Update provider configuration',
    description: 'Update provider metadata, base URL, or API key',
  })
  async updateProvider(
    @Param(new ZodValidationPipe(providerParamsSchema.params)) params: ProviderParams,
    @Body() body: UpdateProviderRequest,
    @Req() request: any,
  ) {
    return this.providerConfigsService.updateProvider(request.user.id, params.provider, body);
  }

  @Delete(':provider')
  @UsePipes(new ZodValidationPipe(providerParamsSchema.params))
  @ApiOperation({
    summary: 'Deactivate provider',
    description: 'Disable a provider and remove any stored API keys',
  })
  async deactivateProvider(
    @Param(new ZodValidationPipe(providerParamsSchema.params)) params: ProviderParams,
    @Req() request: any,
  ) {
    return this.providerConfigsService.deactivateProvider(request.user.id, params.provider);
  }

  @Get(':provider/models')
  @ApiOperation({
    summary: 'List available provider models',
    description: 'Returns models accessible for the provider configuration',
  })
  async getProviderModels(
    @Param(new ZodValidationPipe(providerParamsSchema.params)) params: ProviderParams,
    @Query(new ZodValidationPipe(providerModelsQuerySchema.query)) query: ProviderModelsQuery,
    @Req() request: any,
  ) {
    return this.providerConfigsService.getAvailableModels(
      request.user.id,
      providerCodeSchema.parse(params.provider),
      query.search,
    );
  }
}

