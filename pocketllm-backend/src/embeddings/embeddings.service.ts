import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { OpenAIService } from '../providers/openai.service';

@Injectable()
export class EmbeddingsService {
  private readonly logger = new Logger(EmbeddingsService.name);

  // Available embedding models
  private readonly embeddingModels = {
    'text-embedding-3-large': {
      name: 'Text Embedding 3 Large',
      provider: 'openai',
      dimensions: 3072,
      maxTokens: 8191,
      pricing: 0.00013, // per 1K tokens
    },
    'text-embedding-3-small': {
      name: 'Text Embedding 3 Small',
      provider: 'openai',
      dimensions: 1536,
      maxTokens: 8191,
      pricing: 0.00002, // per 1K tokens
    },
    'text-embedding-ada-002': {
      name: 'Text Embedding Ada 002',
      provider: 'openai',
      dimensions: 1536,
      maxTokens: 8191,
      pricing: 0.0001, // per 1K tokens
    },
  };

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly openaiService: OpenAIService,
  ) {}

  /**
   * Generate embeddings for text
   */
  async generateEmbeddings(userId: string, embeddingDto: any) {
    try {
      const { text, model, collectionId, metadata } = embeddingDto;

      // Validate model
      if (!this.embeddingModels[model]) {
        throw new BadRequestException('Invalid embedding model');
      }

      // Generate embedding using OpenAI
      const embedding = await this.generateEmbeddingVector(text, model, embeddingDto.apiKey);

      // Save embedding to database
      const { data, error } = await this.supabaseService
        .from('embeddings')
        .insert({
          user_id: userId,
          collection_id: collectionId,
          text: text,
          model: model,
          embedding: embedding,
          metadata: metadata || {},
          token_count: this.estimateTokenCount(text),
        })
        .select()
        .single();

      if (error) {
        this.logger.error('Failed to save embedding:', error);
        throw new BadRequestException('Failed to save embedding');
      }

      return data;
    } catch (error) {
      this.logger.error('Error generating embeddings:', error);
      throw error;
    }
  }

  /**
   * Search for similar embeddings
   */
  async searchEmbeddings(userId: string, searchDto: any) {
    try {
      const { query, model, collectionId, limit = 10, threshold = 0.8 } = searchDto;

      // Generate embedding for search query
      const queryEmbedding = await this.generateEmbeddingVector(query, model, searchDto.apiKey);

      // Perform vector similarity search using Supabase's vector extension
      const { data, error } = await this.supabaseService
        .rpc('search_embeddings', {
          query_embedding: queryEmbedding,
          match_threshold: threshold,
          match_count: limit,
          collection_id: collectionId,
          user_id: userId,
        });

      if (error) {
        this.logger.error('Failed to search embeddings:', error);
        throw new BadRequestException('Failed to search embeddings');
      }

      return data;
    } catch (error) {
      this.logger.error('Error searching embeddings:', error);
      throw error;
    }
  }

  /**
   * Get user's embedding collections
   */
  async getCollections(userId: string) {
    try {
      const { data, error } = await this.supabaseService
        .from('embedding_collections')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (error) {
        this.logger.error('Failed to get collections:', error);
        throw new BadRequestException('Failed to retrieve collections');
      }

      return data;
    } catch (error) {
      this.logger.error('Error getting collections:', error);
      throw error;
    }
  }

  /**
   * Create embedding collection
   */
  async createCollection(userId: string, collectionDto: any) {
    try {
      const { data, error } = await this.supabaseService
        .from('embedding_collections')
        .insert({
          user_id: userId,
          name: collectionDto.name,
          description: collectionDto.description,
          metadata: collectionDto.metadata || {},
        })
        .select()
        .single();

      if (error) {
        this.logger.error('Failed to create collection:', error);
        throw new BadRequestException('Failed to create collection');
      }

      return data;
    } catch (error) {
      this.logger.error('Error creating collection:', error);
      throw error;
    }
  }

  /**
   * Get embeddings from a collection
   */
  async getCollectionEmbeddings(collectionId: string, userId: string, options: any) {
    try {
      // Verify collection ownership
      await this.verifyCollectionOwnership(collectionId, userId);

      let query = this.supabaseService
        .from('embeddings')
        .select('*')
        .eq('collection_id', collectionId)
        .order('created_at', { ascending: false });

      if (options.limit) {
        query = query.limit(options.limit);
      }

      if (options.offset) {
        query = query.range(options.offset, options.offset + (options.limit || 50) - 1);
      }

      const { data, error } = await query;

      if (error) {
        this.logger.error('Failed to get collection embeddings:', error);
        throw new BadRequestException('Failed to retrieve embeddings');
      }

      return data;
    } catch (error) {
      this.logger.error('Error getting collection embeddings:', error);
      throw error;
    }
  }

  /**
   * Delete collection and all its embeddings
   */
  async deleteCollection(collectionId: string, userId: string) {
    try {
      // Verify collection ownership
      await this.verifyCollectionOwnership(collectionId, userId);

      // Delete collection (embeddings will be deleted via cascade)
      const { error } = await this.supabaseService
        .from('embedding_collections')
        .delete()
        .eq('id', collectionId);

      if (error) {
        this.logger.error('Failed to delete collection:', error);
        throw new BadRequestException('Failed to delete collection');
      }

      return { message: 'Collection deleted successfully' };
    } catch (error) {
      this.logger.error('Error deleting collection:', error);
      throw error;
    }
  }

  /**
   * Get specific embedding
   */
  async getEmbedding(embeddingId: string, userId: string) {
    try {
      const { data, error } = await this.supabaseService
        .from('embeddings')
        .select('*')
        .eq('id', embeddingId)
        .eq('user_id', userId)
        .single();

      if (error || !data) {
        throw new NotFoundException('Embedding not found');
      }

      return data;
    } catch (error) {
      this.logger.error('Error getting embedding:', error);
      throw error;
    }
  }

  /**
   * Delete specific embedding
   */
  async deleteEmbedding(embeddingId: string, userId: string) {
    try {
      const { error } = await this.supabaseService
        .from('embeddings')
        .delete()
        .eq('id', embeddingId)
        .eq('user_id', userId);

      if (error) {
        this.logger.error('Failed to delete embedding:', error);
        throw new BadRequestException('Failed to delete embedding');
      }

      return { message: 'Embedding deleted successfully' };
    } catch (error) {
      this.logger.error('Error deleting embedding:', error);
      throw error;
    }
  }

  /**
   * Get available embedding models
   */
  async getAvailableEmbeddingModels() {
    return {
      models: this.embeddingModels,
    };
  }

  /**
   * Generate embedding vector using OpenAI
   */
  private async generateEmbeddingVector(text: string, model: string, apiKey: string): Promise<number[]> {
    try {
      // This would use the OpenAI embeddings API
      // For now, returning a mock embedding vector
      const response = await this.openaiService.getEmbedding(text, apiKey, model);
      return response.embedding;
    } catch (error) {
      this.logger.error('Failed to generate embedding vector:', error);
      throw new BadRequestException('Failed to generate embedding vector');
    }
  }

  /**
   * Estimate token count for text
   */
  private estimateTokenCount(text: string): number {
    // Rough estimation: 1 token ≈ 4 characters
    return Math.ceil(text.length / 4);
  }

  /**
   * Verify collection ownership
   */
  private async verifyCollectionOwnership(collectionId: string, userId: string) {
    const { data, error } = await this.supabaseService
      .from('embedding_collections')
      .select('id')
      .eq('id', collectionId)
      .eq('user_id', userId)
      .single();

    if (error || !data) {
      throw new NotFoundException('Collection not found');
    }
  }
}
