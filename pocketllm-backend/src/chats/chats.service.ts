import { Injectable, Logger, NotFoundException, ForbiddenException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { OpenAIService } from '../providers/openai.service';
import { AnthropicService } from '../providers/anthropic.service';
import { OllamaService } from '../providers/ollama.service';

@Injectable()
export class ChatsService {
  private readonly logger = new Logger(ChatsService.name);

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly openaiService: OpenAIService,
    private readonly anthropicService: AnthropicService,
    private readonly ollamaService: OllamaService,
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
    try {
      const { data, error } = await this.supabaseService
        .from('chats')
        .insert({
          user_id: userId,
          title: createChatDto.title || 'New Chat',
          model_config: createChatDto.model_config || {},
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
      await this.getChat(chatId, userId);

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
      const aiResponse = await this.getAIResponse(messageDto.content, messageDto.model_config);

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
    const { provider, model, apiKey, systemPrompt } = modelConfig;

    try {
      switch (provider) {
        case 'openai':
          return await this.openaiService.getCompletion(prompt, apiKey, model, systemPrompt);
        case 'anthropic':
          return await this.anthropicService.getCompletion(prompt, apiKey, model, systemPrompt);
        case 'ollama':
          return await this.ollamaService.getCompletion(prompt, model, systemPrompt);
        default:
          throw new BadRequestException('Unsupported AI provider');
      }
    } catch (error) {
      this.logger.error('Error getting AI response:', error);
      throw new BadRequestException('Failed to get AI response');
    }
  }
}
