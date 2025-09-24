import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { ProviderConfigsService } from '../provider-configs/provider-configs.service';
import { ImportModelsRequest } from '../api/v1/schemas/models.schemas';
import { ProviderCode } from '../api/v1/schemas/providers.schemas';

@Injectable()
export class ModelsService {
  private readonly logger = new Logger(ModelsService.name);
  private static readonly PROVIDER_SELECT =
    '*, provider_account:providers!model_configs_provider_id_fkey(*)';

  constructor(
    private readonly supabase: SupabaseService,
    private readonly providerConfigsService: ProviderConfigsService,
  ) {}

  async listModels(userId: string) {
    const { data, error } = await this.supabase
      .from('model_configs')
      .select(ModelsService.PROVIDER_SELECT)
      .eq('user_id', userId)
      .order('updated_at', { ascending: false });

    if (error) {
      this.logger.error('Failed to load models', error);
      throw new BadRequestException('Failed to load models');
    }

    return (data ?? []).map(row => this.sanitizeModel(row));
  }

  async importModels(userId: string, request: ImportModelsRequest) {
    const providerRecord = request.providerId
      ? await this.getProviderById(userId, request.providerId)
      : await this.providerConfigsService.getProviderRecord(userId, request.provider as ProviderCode);

    if (!providerRecord) {
      throw new BadRequestException('Provider configuration not found');
    }

    if (providerRecord.provider !== request.provider) {
      throw new BadRequestException('Provider identifier mismatch');
    }

    if (!providerRecord.is_active) {
      throw new BadRequestException('Provider must be active to import models');
    }

    const sharedSettings = this.normalizeSettings(request.sharedSettings);
    const rows = request.models.map(model => {
      const mergedSettings = {
        ...sharedSettings,
        ...this.normalizeSettings(model.settings),
      };
      const metadata = this.prepareMetadata(model.description, model.metadata);

      return {
        user_id: userId,
        provider: request.provider,
        provider_id: providerRecord.id,
        name: model.name || model.id,
        display_name: model.name || model.id,
        model: model.id,
        description: metadata?.description ?? null,
        metadata,
        base_url: providerRecord.base_url ?? null,
        system_prompt: mergedSettings.systemPrompt ?? null,
        temperature: mergedSettings.temperature ?? 0.7,
        max_tokens: mergedSettings.maxTokens ?? null,
        top_p: mergedSettings.topP ?? 1.0,
        frequency_penalty: mergedSettings.frequencyPenalty ?? 0.0,
        presence_penalty: mergedSettings.presencePenalty ?? 0.0,
        settings: Object.keys(mergedSettings).length ? mergedSettings : null,
        is_active: true,
        updated_at: new Date().toISOString(),
      };
    });

    const { data, error } = await this.supabase
      .from('model_configs')
      .upsert(rows, { onConflict: 'user_id,provider,model' })
      .select(ModelsService.PROVIDER_SELECT);

    if (error) {
      this.logger.error('Failed to import models', error);
      throw new BadRequestException('Failed to import models');
    }

    return (data ?? []).map(row => this.sanitizeModel(row));
  }

  async getModel(userId: string, modelId: string) {
    const { data, error } = await this.supabase
      .from('model_configs')
      .select(ModelsService.PROVIDER_SELECT)
      .eq('user_id', userId)
      .eq('id', modelId)
      .single();

    if (error) {
      this.logger.error('Failed to load model', error);
      throw new NotFoundException('Model not found');
    }

    return this.sanitizeModel(data);
  }

  async deleteModel(userId: string, modelId: string) {
    const { error } = await this.supabase
      .from('model_configs')
      .delete()
      .eq('user_id', userId)
      .eq('id', modelId);

    if (error) {
      this.logger.error('Failed to delete model', error);
      throw new BadRequestException('Failed to delete model');
    }

    return { success: true };
  }

  async setDefaultModel(userId: string, modelId: string) {
    const { error: fetchError } = await this.supabase
      .from('model_configs')
      .select('id')
      .eq('user_id', userId)
      .eq('id', modelId)
      .single();

    if (fetchError) {
      this.logger.warn(`Model ${modelId} not found for user ${userId}`, fetchError);
      throw new NotFoundException('Model not found');
    }

    const now = new Date().toISOString();

    const { error: clearError } = await this.supabase
      .from('model_configs')
      .update({ is_default: false, updated_at: now })
      .eq('user_id', userId)
      .neq('id', modelId);

    if (clearError) {
      this.logger.error('Failed to clear previous default models', clearError);
      throw new BadRequestException('Failed to update default model');
    }

    const { data, error } = await this.supabase
      .from('model_configs')
      .update({ is_default: true, updated_at: now })
      .eq('user_id', userId)
      .eq('id', modelId)
      .select(ModelsService.PROVIDER_SELECT)
      .single();

    if (error) {
      this.logger.error('Failed to set default model', error);
      throw new BadRequestException('Failed to set default model');
    }

    return this.sanitizeModel(data);
  }

  private sanitizeModel(row: any) {
    if (!row) {
      return null;
    }

    return {
      id: row.id,
      name: row.name,
      displayName: row.display_name ?? row.name,
      provider: row.provider,
      providerId: row.provider_id,
      model: row.model,
      baseUrl: row.base_url,
      description: row.description,
      metadata: row.metadata,
      systemPrompt: row.system_prompt,
      temperature: row.temperature,
      maxTokens: row.max_tokens,
      topP: row.top_p,
      frequencyPenalty: row.frequency_penalty,
      presencePenalty: row.presence_penalty,
      additionalParams: row.settings,
      isDefault: row.is_default,
      isActive: row.is_active,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      providerDetails: row.provider_account
        ? {
            id: row.provider_account.id,
            provider: row.provider_account.provider,
            displayName: row.provider_account.display_name,
            baseUrl: row.provider_account.base_url,
            isActive: row.provider_account.is_active,
            hasApiKey: Boolean(row.provider_account.api_key_hash),
            apiKeyPreview: row.provider_account.api_key_preview,
          }
        : null,
    };
  }

  private async getProviderById(userId: string, providerId: string) {
    const { data, error } = await this.supabase
      .from('providers')
      .select('*')
      .eq('user_id', userId)
      .eq('id', providerId)
      .single();

    if (error) {
      this.logger.error('Failed to fetch provider by id', error);
      throw new BadRequestException('Failed to load provider configuration');
    }

    return data;
  }

  private normalizeSettings(settings?: Record<string, any> | null) {
    if (!settings) {
      return {} as Record<string, any>;
    }

    const normalized: Record<string, any> = {};

    if (typeof settings.systemPrompt === 'string' && settings.systemPrompt.trim()) {
      normalized.systemPrompt = settings.systemPrompt.trim();
    }

    if (typeof settings.temperature === 'number' && Number.isFinite(settings.temperature)) {
      normalized.temperature = settings.temperature;
    }

    if (typeof settings.maxTokens === 'number' && Number.isFinite(settings.maxTokens)) {
      normalized.maxTokens = Math.max(1, Math.floor(settings.maxTokens));
    }

    if (typeof settings.topP === 'number' && Number.isFinite(settings.topP)) {
      normalized.topP = settings.topP;
    }

    if (typeof settings.frequencyPenalty === 'number' && Number.isFinite(settings.frequencyPenalty)) {
      normalized.frequencyPenalty = settings.frequencyPenalty;
    }

    if (typeof settings.presencePenalty === 'number' && Number.isFinite(settings.presencePenalty)) {
      normalized.presencePenalty = settings.presencePenalty;
    }

    return normalized;
  }

  private prepareMetadata(description?: string | null, metadata?: Record<string, any> | null) {
    if (metadata && Object.keys(metadata).length > 0) {
      if (description && !metadata.description) {
        return { ...metadata, description };
      }
      return metadata;
    }

    if (description) {
      return { description };
    }

    return null;
  }
}

