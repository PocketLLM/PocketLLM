import { Injectable, Logger, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { OpenAIService } from '../providers/openai.service';
import { AnthropicService } from '../providers/anthropic.service';
import { OllamaService } from '../providers/ollama.service';
import { OpenRouterService } from '../providers/openrouter.service';
import { EncryptionService } from '../common/services/encryption.service';

@Injectable()
export class ChatsService {
  private readonly logger = new Logger(ChatsService.name);
  private static readonly MODEL_SELECT =
    '*, provider_account:providers!model_configs_provider_id_fkey(*)';

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly openaiService: OpenAIService,
    private readonly anthropicService: AnthropicService,
    private readonly ollamaService: OllamaService,
    private readonly openRouterService: OpenRouterService,
    private readonly encryptionService: EncryptionService,
  ) {}

  /**
   * Get all chats for a user
   */
  async getChats(userId: string) {
    try {
      const { data, error } = await this.supabaseService
        .from('chats')
        .select('*')
        .eq('user_id', userId)
        .order('updated_at', { ascending: false });

      if (error) {
        this.logger.error('Failed to get chats:', error);
        throw new BadRequestException('Failed to retrieve chats');
      }

      return data;
    } catch (error) {
      this.logger.error('Error getting chats:', error);
      throw error;
    }
  }

  /**
   * Create a new chat
   */
  async createChat(userId: string, createChatDto: any) {
    const modelConfigId = createChatDto.model_config_id;

    if (!modelConfigId) {
      throw new BadRequestException('Model configuration is required');
    }

    await this.ensureModelConfigOwnership(modelConfigId, userId);

    try {
      const { data, error } = await this.supabaseService
        .from('chats')
        .insert({
          user_id: userId,
          title: createChatDto.title || 'New Chat',
          model_config_id: modelConfigId,
        })
        .select()
        .single();

      if (error) {
        this.logger.error('Failed to create chat:', error);
        throw new BadRequestException('Failed to create chat');
      }

      return data;
    } catch (error) {
      this.logger.error('Error creating chat:', error);
      throw error;
    }
  }

  /**
   * Get a specific chat
   */
  async getChat(chatId: string, userId: string) {
    try {
      const { data, error } = await this.supabaseService
        .from('chats')
        .select('*')
        .eq('id', chatId)
        .eq('user_id', userId)
        .single();

      if (error || !data) {
        throw new NotFoundException('Chat not found');
      }

      return data;
    } catch (error) {
      this.logger.error('Error getting chat:', error);
      throw error;
    }
  }

  /**
   * Update a chat
   */
  async updateChat(chatId: string, userId: string, updateChatDto: any) {
    try {
      if (updateChatDto.model_config_id) {
        await this.ensureModelConfigOwnership(updateChatDto.model_config_id, userId);
      }

      const { data, error } = await this.supabaseService
        .from('chats')
        .update(updateChatDto)
        .eq('id', chatId)
        .eq('user_id', userId)
        .select()
        .single();

      if (error || !data) {
        throw new NotFoundException('Chat not found or update failed');
      }

      return data;
    } catch (error) {
      this.logger.error('Error updating chat:', error);
      throw error;
    }
  }

  /**
   * Delete a chat
   */
  async deleteChat(chatId: string, userId: string) {
    try {
      const { error } = await this.supabaseService
        .from('chats')
        .delete()
        .eq('id', chatId)
        .eq('user_id', userId);

      if (error) {
        this.logger.error('Failed to delete chat:', error);
        throw new BadRequestException('Failed to delete chat');
      }

      return { message: 'Chat deleted successfully' };
    } catch (error) {
      this.logger.error('Error deleting chat:', error);
      throw error;
    }
  }

  /**
   * Send a message and get AI response
   */
  async sendMessage(chatId: string, userId: string, messageDto: any) {
    try {
      // Verify chat ownership
      const chat = await this.getChat(chatId, userId);

      const modelConfigId = messageDto.model_config_id || chat.model_config_id;

      if (!modelConfigId) {
        throw new BadRequestException('Chat is not associated with a model configuration');
      }

      const modelConfig = await this.getModelConfiguration(modelConfigId, userId);

      // Save user message
      const { data: userMessage, error: userMessageError } = await this.supabaseService
        .from('messages')
        .insert({
          chat_id: chatId,
          content: messageDto.content,
          role: 'user',
        })
        .select()
        .single();

      if (userMessageError) {
        throw new BadRequestException('Failed to save user message');
      }

      // Get AI response based on model configuration
      const aiResponse = await this.getAIResponse(messageDto.content, modelConfig);

      // Save AI response
      const { data: aiMessage, error: aiMessageError } = await this.supabaseService
        .from('messages')
        .insert({
          chat_id: chatId,
          content: aiResponse.content,
          role: 'assistant',
        })
        .select()
        .single();

      if (aiMessageError) {
        throw new BadRequestException('Failed to save AI response');
      }

      return {
        userMessage,
        aiMessage,
      };
    } catch (error) {
      this.logger.error('Error sending message:', error);
      throw error;
    }
  }

  /**
   * Get messages for a chat
   */
  async getMessages(chatId: string, userId: string, options: { limit?: number; offset?: number }) {
    try {
      // Verify chat ownership
      await this.getChat(chatId, userId);

      let query = this.supabaseService
        .from('messages')
        .select('*')
        .eq('chat_id', chatId)
        .order('created_at', { ascending: true });

      if (options.limit) {
        query = query.limit(options.limit);
      }

      if (options.offset) {
        query = query.range(options.offset, options.offset + (options.limit || 50) - 1);
      }

      const { data, error } = await query;

      if (error) {
        this.logger.error('Failed to get messages:', error);
        throw new BadRequestException('Failed to retrieve messages');
      }

      return data;
    } catch (error) {
      this.logger.error('Error getting messages:', error);
      throw error;
    }
  }

  /**
   * Get AI response based on model configuration
   */
  private async getAIResponse(prompt: string, modelConfig: any): Promise<{ content: string }> {
    const provider = modelConfig.provider;
    const model = modelConfig.model;
    const systemPrompt = modelConfig.system_prompt;
    const providerAccount = modelConfig.provider_account;

    try {
      switch (provider) {
        case 'openai':
          if (!providerAccount?.api_key_encrypted) {
            throw new BadRequestException('OpenAI API key is not configured');
          }
          return await this.openaiService.getCompletion(
            prompt,
            this.encryptionService.decrypt(providerAccount.api_key_encrypted),
            model,
            systemPrompt,
          );
        case 'anthropic':
          if (!providerAccount?.api_key_encrypted) {
            throw new BadRequestException('Anthropic API key is not configured');
          }
          return await this.anthropicService.getCompletion(
            prompt,
            this.encryptionService.decrypt(providerAccount.api_key_encrypted),
            model,
            systemPrompt,
          );
        case 'ollama':
          return await this.ollamaService.getCompletion(
            prompt,
            model,
            systemPrompt,
            providerAccount?.base_url || modelConfig.base_url || undefined,
          );
        case 'openrouter':
          if (!providerAccount?.api_key_encrypted) {
            throw new BadRequestException('OpenRouter API key is not configured');
          }
          return await this.openRouterService.getCompletion(
            prompt,
            this.encryptionService.decrypt(providerAccount.api_key_encrypted),
            model,
            systemPrompt,
          );
        default:
          throw new BadRequestException('Unsupported AI provider');
      }
    } catch (error) {
      this.logger.error('Error getting AI response:', error);
      if (error instanceof BadRequestException) {
        throw error;
      }
      throw new BadRequestException(error?.message || 'Failed to get AI response');
    }
  }

  private async getModelConfiguration(modelConfigId: string, userId: string) {
    const { data, error } = await this.supabaseService
      .from('model_configs')
      .select(ChatsService.MODEL_SELECT)
      .eq('id', modelConfigId)
      .eq('user_id', userId)
      .single();

    if (error || !data) {
      throw new BadRequestException('Model configuration not found');
    }

    const providerAccount = await this.ensureProviderAccount(data, userId);

    if (!providerAccount.is_active) {
      throw new BadRequestException('Provider is inactive');
    }

    return { ...data, provider_account: providerAccount };
  }

  private async ensureProviderAccount(modelConfig: any, userId: string) {
    if (modelConfig.provider_account) {
      return modelConfig.provider_account;
    }

    let query = this.supabaseService
      .from('providers')
      .select('*')
      .eq('user_id', userId)
      .limit(1);

    if (modelConfig.provider_id) {
      query = query.eq('id', modelConfig.provider_id);
    } else {
      query = query.eq('provider', modelConfig.provider);
    }

    const { data, error } = await query.maybeSingle();

    if (error) {
      this.logger.error('Failed to load provider account for model', error);
      throw new BadRequestException('Provider configuration not available');
    }

    if (!data) {
      throw new BadRequestException('Provider configuration not available');
    }

    return data;
  }

  private async ensureModelConfigOwnership(modelConfigId: string, userId: string) {
    const { error, data } = await this.supabaseService
      .from('model_configs')
      .select('id')
      .eq('id', modelConfigId)
      .eq('user_id', userId)
      .single();

    if (error || !data) {
      throw new ForbiddenException('Model configuration not found or access denied');
    }
  }
}
