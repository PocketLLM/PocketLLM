import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { OpenAIService } from '../providers/openai.service';
import { AnthropicService } from '../providers/anthropic.service';
import { OllamaService } from '../providers/ollama.service';

@Injectable()
export class ModelsService {
  private readonly logger = new Logger(ModelsService.name);

  // Available models configuration
  private readonly availableModels = {
    openai: [
      { id: 'gpt-4', name: 'GPT-4', description: 'Most capable GPT-4 model', requiresApiKey: true },
      { id: 'gpt-4-turbo', name: 'GPT-4 Turbo', description: 'Faster and more efficient GPT-4', requiresApiKey: true },
      { id: 'gpt-3.5-turbo', name: 'GPT-3.5 Turbo', description: 'Fast and efficient model', requiresApiKey: true },
    ],
    anthropic: [
      { id: 'claude-3-opus-20240229', name: 'Claude 3 Opus', description: 'Most powerful Claude model', requiresApiKey: true },
      { id: 'claude-3-sonnet-20240229', name: 'Claude 3 Sonnet', description: 'Balanced Claude model', requiresApiKey: true },
      { id: 'claude-3-haiku-20240307', name: 'Claude 3 Haiku', description: 'Fastest Claude model', requiresApiKey: true },
    ],
    ollama: [
      { id: 'llama2', name: 'Llama 2', description: 'Open source model by Meta', requiresApiKey: false },
      { id: 'codellama', name: 'Code Llama', description: 'Code-focused Llama model', requiresApiKey: false },
      { id: 'mistral', name: 'Mistral', description: 'Efficient open source model', requiresApiKey: false },
    ],
  };

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly openaiService: OpenAIService,
    private readonly anthropicService: AnthropicService,
    private readonly ollamaService: OllamaService,
  ) {}

  /**
   * Get all available models
   */
  async getAvailableModels() {
    return {
      providers: Object.keys(this.availableModels),
      models: this.availableModels,
    };
  }

  /**
   * Get user model configurations
   */
  async getUserModelConfigs(userId: string) {
    try {
      const { data, error } = await this.supabaseService
        .from('user_model_configs')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) {
        this.logger.error('Failed to get user model configs:', error);
        throw new BadRequestException('Failed to retrieve model configurations');
      }

      return data;
    } catch (error) {
      this.logger.error('Error getting user model configs:', error);
      throw error;
    }
  }

  /**
   * Save user model configuration
   */
  async saveUserModelConfig(userId: string, configDto: any) {
    try {
      const { data, error } = await this.supabaseService
        .from('user_model_configs')
        .insert({
          user_id: userId,
          name: configDto.name,
          provider: configDto.provider,
          model: configDto.model,
          api_key: configDto.apiKey,
          system_prompt: configDto.systemPrompt,
          temperature: configDto.temperature,
          max_tokens: configDto.maxTokens,
          is_default: configDto.isDefault || false,
        })
        .select()
        .single();

      if (error) {
        this.logger.error('Failed to save user model config:', error);
        throw new BadRequestException('Failed to save model configuration');
      }

      // If this is set as default, update other configs to not be default
      if (configDto.isDefault) {
        await this.updateDefaultConfig(userId, data.id);
      }

      return data;
    } catch (error) {
      this.logger.error('Error saving user model config:', error);
      throw error;
    }
  }

  /**
   * Update user model configuration
   */
  async updateUserModelConfig(configId: string, userId: string, configDto: any) {
    try {
      const { data, error } = await this.supabaseService
        .from('user_model_configs')
        .update({
          name: configDto.name,
          provider: configDto.provider,
          model: configDto.model,
          api_key: configDto.apiKey,
          system_prompt: configDto.systemPrompt,
          temperature: configDto.temperature,
          max_tokens: configDto.maxTokens,
          is_default: configDto.isDefault || false,
        })
        .eq('id', configId)
        .eq('user_id', userId)
        .select()
        .single();

      if (error || !data) {
        throw new NotFoundException('Model configuration not found or update failed');
      }

      // If this is set as default, update other configs to not be default
      if (configDto.isDefault) {
        await this.updateDefaultConfig(userId, configId);
      }

      return data;
    } catch (error) {
      this.logger.error('Error updating user model config:', error);
      throw error;
    }
  }

  /**
   * Delete user model configuration
   */
  async deleteUserModelConfig(configId: string, userId: string) {
    try {
      const { error } = await this.supabaseService
        .from('user_model_configs')
        .delete()
        .eq('id', configId)
        .eq('user_id', userId);

      if (error) {
        this.logger.error('Failed to delete user model config:', error);
        throw new BadRequestException('Failed to delete model configuration');
      }

      return { message: 'Model configuration deleted successfully' };
    } catch (error) {
      this.logger.error('Error deleting user model config:', error);
      throw error;
    }
  }

  /**
   * Test model configuration
   */
  async testModelConfig(testDto: any) {
    try {
      const { provider, model, apiKey, systemPrompt } = testDto;
      const testPrompt = testDto.testPrompt || 'Hello, please respond with a brief greeting.';

      let response;
      switch (provider) {
        case 'openai':
          response = await this.openaiService.getCompletion(testPrompt, apiKey, model, systemPrompt);
          break;
        case 'anthropic':
          response = await this.anthropicService.getCompletion(testPrompt, apiKey, model, systemPrompt);
          break;
        case 'ollama':
          response = await this.ollamaService.getCompletion(testPrompt, model, systemPrompt);
          break;
        default:
          throw new BadRequestException('Unsupported provider');
      }

      return {
        success: true,
        response: response.content,
        message: 'Model configuration test successful',
      };
    } catch (error) {
      this.logger.error('Error testing model config:', error);
      return {
        success: false,
        error: error.message,
        message: 'Model configuration test failed',
      };
    }
  }

  /**
   * Get supported providers
   */
  async getSupportedProviders() {
    return Object.keys(this.availableModels).map(provider => ({
      id: provider,
      name: provider.charAt(0).toUpperCase() + provider.slice(1),
      models: this.availableModels[provider],
    }));
  }

  /**
   * Get models for a specific provider
   */
  async getProviderModels(provider: string) {
    if (!this.availableModels[provider]) {
      throw new NotFoundException('Provider not found');
    }

    return {
      provider,
      models: this.availableModels[provider],
    };
  }

  /**
   * Update default configuration (set others to false)
   */
  private async updateDefaultConfig(userId: string, newDefaultId: string) {
    await this.supabaseService
      .from('user_model_configs')
      .update({ is_default: false })
      .eq('user_id', userId)
      .neq('id', newDefaultId);
  }
}
