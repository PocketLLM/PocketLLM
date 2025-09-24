import { BadRequestException, Injectable, Logger, NotFoundException } from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { EncryptionService } from '../common/services/encryption.service';
import { HashService } from '../common/services/hash.service';
import { OllamaService } from '../providers/ollama.service';
import { OpenRouterService } from '../providers/openrouter.service';
import {
  ActivateProviderRequest,
  ProviderCode,
  UpdateProviderRequest,
} from '../api/v1/schemas/providers.schemas';

type ActivateProviderInput = ActivateProviderRequest;
type UpdateProviderInput = UpdateProviderRequest;

@Injectable()
export class ProviderConfigsService {
  private readonly logger = new Logger(ProviderConfigsService.name);

  constructor(
    private readonly supabase: SupabaseService,
    private readonly encryptionService: EncryptionService,
    private readonly hashService: HashService,
    private readonly ollamaService: OllamaService,
    private readonly openRouterService: OpenRouterService,
  ) {}

  async listProviders(userId: string) {
    const { data, error } = await this.supabase
      .from('providers')
      .select('*')
      .eq('user_id', userId)
      .order('provider', { ascending: true });

    if (error) {
      this.logger.error('Failed to list providers', error);
      throw new BadRequestException('Failed to load providers');
    }

    return (data ?? []).map(row => this.sanitizeProviderRow(row));
  }

  async activateProvider(userId: string, input: ActivateProviderInput) {
    const payload = await this.prepareUpsertPayload(userId, input.provider, input);

    const { data, error } = await this.supabase
      .from('providers')
      .upsert(payload, { onConflict: 'user_id,provider' })
      .select('*')
      .single();

    if (error) {
      this.logger.error('Failed to activate provider', error);
      throw new BadRequestException('Failed to activate provider');
    }

    return this.sanitizeProviderRow(data);
  }

  async updateProvider(userId: string, provider: ProviderCode, input: UpdateProviderInput) {
    const existing = await this.getProviderRecord(userId, provider);

    if (!existing) {
      throw new NotFoundException('Provider not configured');
    }

    const payload = await this.prepareUpsertPayload(userId, provider, {
      ...existing,
      ...input,
      provider,
    });

    const { data, error } = await this.supabase
      .from('providers')
      .update(payload)
      .eq('id', existing.id)
      .eq('user_id', userId)
      .select('*')
      .single();

    if (error) {
      this.logger.error('Failed to update provider', error);
      throw new BadRequestException('Failed to update provider');
    }

    return this.sanitizeProviderRow(data);
  }

  async deactivateProvider(userId: string, provider: ProviderCode) {
    const existing = await this.getProviderRecord(userId, provider);

    if (!existing) {
      throw new NotFoundException('Provider not configured');
    }

    const { data, error } = await this.supabase
      .from('providers')
      .update({
        is_active: false,
        api_key_encrypted: null,
        api_key_hash: null,
        api_key_preview: null,
        updated_at: new Date().toISOString(),
      })
      .eq('id', existing.id)
      .eq('user_id', userId)
      .select('*')
      .single();

    if (error) {
      this.logger.error('Failed to deactivate provider', error);
      throw new BadRequestException('Failed to deactivate provider');
    }

    return this.sanitizeProviderRow(data);
  }

  async getAvailableModels(userId: string, provider: ProviderCode, search?: string) {
    const record = await this.getProviderRecord(userId, provider);

    if (!record || !record.is_active) {
      throw new BadRequestException('Provider is not active');
    }

    let models: any[] = [];

    switch (provider) {
      case 'ollama': {
        if (!record.base_url) {
          throw new BadRequestException('Ollama base URL is not configured');
        }
        const response = await this.ollamaService.getModels(record.base_url);
        const ollamaModels = response?.models ?? [];
        models = ollamaModels.map(model => ({
          id: model.name,
          name: model.name,
          description: model.details?.description || null,
          size: model.size,
          digest: model.digest,
          modified_at: model.modified_at,
          tags: model.details?.tags,
          metadata: model,
        }));
        break;
      }
      case 'openrouter': {
        const apiKey = record.api_key_encrypted
          ? this.encryptionService.decrypt(record.api_key_encrypted)
          : null;

        if (!apiKey) {
          throw new BadRequestException('OpenRouter API key is missing');
        }

        const openRouterModels = await this.openRouterService.getModels(apiKey);
        models = openRouterModels.map(model => ({
          id: model.id,
          name: model.name || model.id,
          description: model.description || model.family,
          pricing: model.pricing,
          context_length: model.context_length,
          top_provider: model.top_provider,
          architecture: model.architecture,
          capabilities: model.capabilities,
          metadata: model,
        }));
        break;
      }
      default:
        throw new BadRequestException('Listing models is not supported for this provider yet');
    }

    if (search) {
      const normalized = search.toLowerCase();
      models = models.filter(model =>
        model.name?.toLowerCase().includes(normalized) ||
        model.id?.toLowerCase().includes(normalized) ||
        model.description?.toLowerCase().includes(normalized),
      );
    }

    return models;
  }

  async getProviderRecord(userId: string, provider: ProviderCode) {
    const { data, error } = await this.supabase
      .from('providers')
      .select('*')
      .eq('user_id', userId)
      .eq('provider', provider)
      .maybeSingle();

    if (error) {
      this.logger.error('Failed to load provider record', error);
      throw new BadRequestException('Failed to load provider configuration');
    }

    return data || null;
  }

  private async prepareUpsertPayload(
    userId: string,
    provider: ProviderCode,
    input: ActivateProviderInput | (UpdateProviderInput & { provider: ProviderCode; id?: string }),
  ) {
    if (!provider) {
      throw new BadRequestException('Provider is required');
    }

    if (provider === 'openrouter' && !input.apiKey && !(input as any).api_key_encrypted) {
      throw new BadRequestException('OpenRouter API key is required');
    }

    if (provider === 'ollama' && !input.baseUrl && !(input as any).base_url) {
      throw new BadRequestException('Ollama base URL is required');
    }

    const payload: any = {
      user_id: userId,
      provider,
      base_url: input.baseUrl ?? (input as any).base_url ?? null,
      metadata: input.metadata ?? (input as any).metadata ?? null,
      display_name: input.displayName ?? (input as any).display_name ?? null,
      is_active: input.isActive ?? (input as any).is_active ?? true,
      updated_at: new Date().toISOString(),
    };

    if ('id' in input && input.id) {
      payload.id = input.id;
    }

    if (input.apiKey === null) {
      payload.api_key_encrypted = null;
      payload.api_key_hash = null;
      payload.api_key_preview = null;
    } else if (input.apiKey) {
      payload.api_key_encrypted = this.encryptionService.encrypt(input.apiKey);
      payload.api_key_hash = this.hashService.hashSecret(input.apiKey);
      payload.api_key_preview = input.apiKey.slice(-4);
    } else if ((input as any).api_key_encrypted) {
      payload.api_key_encrypted = (input as any).api_key_encrypted;
      payload.api_key_hash = (input as any).api_key_hash;
      payload.api_key_preview = (input as any).api_key_preview;
    }

    if (!payload.display_name) {
      payload.display_name = this.getDefaultDisplayName(provider);
    }

    return payload;
  }

  private sanitizeProviderRow(row: any) {
    if (!row) {
      return null;
    }

    return {
      id: row.id,
      provider: row.provider,
      displayName: row.display_name,
      baseUrl: row.base_url,
      metadata: row.metadata,
      isActive: row.is_active,
      hasApiKey: Boolean(row.api_key_hash),
      apiKeyPreview: row.api_key_preview ?? null,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
    };
  }

  private getDefaultDisplayName(provider: ProviderCode) {
    switch (provider) {
      case 'ollama':
        return 'Ollama';
      case 'openrouter':
        return 'OpenRouter';
      case 'openai':
        return 'OpenAI';
      case 'anthropic':
        return 'Anthropic';
      default:
        return provider;
    }
  }
}

