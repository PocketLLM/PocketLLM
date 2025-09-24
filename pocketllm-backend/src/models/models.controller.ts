import { Body, Controller, Delete, Get, Param, Post, Req, UseGuards, UsePipes } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import { ModelsService } from './models.service';
import {
  ImportModelsRequest,
  ModelIdParams,
  importModelsSchema,
  modelIdParamsSchema,
} from '../api/v1/schemas/models.schemas';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';

@ApiTags('Models')
@ApiBearerAuth()
@Controller('models')
@UseGuards(SupabaseAuthGuard)
export class ModelsController {
  constructor(private readonly modelsService: ModelsService) {}

  @Get()
  @ApiOperation({
    summary: 'List saved models',
    description: 'Returns the models configured by the authenticated user',
  })
  async listModels(@Req() request: any) {
    return this.modelsService.listModels(request.user.id);
  }

  @Post('import')
  @UsePipes(new ZodValidationPipe(importModelsSchema.body))
  @ApiOperation({
    summary: 'Import models from a provider',
    description: 'Imports one or more models from the selected provider into the user\'s workspace',
  })
  async importModels(@Body() body: ImportModelsRequest, @Req() request: any) {
    return this.modelsService.importModels(request.user.id, body);
  }

  @Get(':modelId')
  @ApiOperation({
    summary: 'Get model details',
    description: 'Returns configuration and metadata for a specific model',
  })
  async getModel(
    @Param(new ZodValidationPipe(modelIdParamsSchema.params)) params: ModelIdParams,
    @Req() request: any,
  ) {
    return this.modelsService.getModel(request.user.id, params.modelId);
  }

  @Delete(':modelId')
  @ApiOperation({
    summary: 'Delete model',
    description: 'Remove a model from the authenticated user\'s workspace',
  })
  async deleteModel(
    @Param(new ZodValidationPipe(modelIdParamsSchema.params)) params: ModelIdParams,
    @Req() request: any,
  ) {
    return this.modelsService.deleteModel(request.user.id, params.modelId);
  }

  @Post(':modelId/default')
  @ApiOperation({
    summary: 'Set default model',
    description: 'Marks the selected model as the default for the authenticated user',
  })
  async setDefaultModel(
    @Param(new ZodValidationPipe(modelIdParamsSchema.params)) params: ModelIdParams,
    @Req() request: any,
  ) {
    return this.modelsService.setDefaultModel(request.user.id, params.modelId);
  }
}

