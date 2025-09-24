import { Injectable, Logger, NotFoundException, BadRequestException } from '@nestjs/common';
import { SupabaseService } from '../common/services/supabase.service';
import { ImageRouterService } from '../providers/image-router.service';

@Injectable()
export class JobsService {
  private readonly logger = new Logger(JobsService.name);

  // Available image models with pricing
  private readonly imageModels = {
    'dall-e-3': {
      name: 'DALL-E 3',
      provider: 'openai',
      sizes: ['1024x1024', '1792x1024', '1024x1792'],
      quality: ['standard', 'hd'],
      pricing: {
        'standard-1024x1024': 0.040,
        'standard-1792x1024': 0.080,
        'standard-1024x1792': 0.080,
        'hd-1024x1024': 0.080,
        'hd-1792x1024': 0.120,
        'hd-1024x1792': 0.120,
      },
    },
    'dall-e-2': {
      name: 'DALL-E 2',
      provider: 'openai',
      sizes: ['256x256', '512x512', '1024x1024'],
      quality: ['standard'],
      pricing: {
        'standard-256x256': 0.016,
        'standard-512x512': 0.018,
        'standard-1024x1024': 0.020,
      },
    },
    'midjourney': {
      name: 'Midjourney',
      provider: 'midjourney',
      sizes: ['1024x1024', '1792x1024', '1024x1792'],
      quality: ['standard', 'high'],
      pricing: {
        'standard-1024x1024': 0.025,
        'standard-1792x1024': 0.035,
        'standard-1024x1792': 0.035,
        'high-1024x1024': 0.050,
        'high-1792x1024': 0.070,
        'high-1024x1792': 0.070,
      },
    },
  };

  constructor(
    private readonly supabaseService: SupabaseService,
    private readonly imageRouterService: ImageRouterService,
  ) {}

  /**
   * Get jobs for a user
   */
  async getJobs(userId: string, filters: any) {
    try {
      let query = this.supabaseService
        .from('jobs')
        .select('*')
        .eq('user_id', userId)
        .order('created_at', { ascending: false });

      if (filters.status) {
        query = query.eq('status', filters.status);
      }

      if (filters.type) {
        query = query.eq('type', filters.type);
      }

      if (filters.limit) {
        query = query.limit(filters.limit);
      }

      if (filters.offset) {
        query = query.range(filters.offset, filters.offset + (filters.limit || 50) - 1);
      }

      const { data, error } = await query;

      if (error) {
        this.logger.error('Failed to get jobs:', error);
        throw new BadRequestException('Failed to retrieve jobs');
      }

      return data;
    } catch (error) {
      this.logger.error('Error getting jobs:', error);
      throw error;
    }
  }

  /**
   * Create image generation job
   */
  async createImageGenerationJob(userId: string, jobDto: any) {
    try {
      // Validate model and parameters
      const model = this.imageModels[jobDto.model];
      if (!model) {
        throw new BadRequestException('Invalid image model');
      }

      // Calculate cost
      const cost = this.calculateImageCost(jobDto);

      // Create job record
      const { data: job, error: jobError } = await this.supabaseService
        .from('jobs')
        .insert({
          user_id: userId,
          type: 'image_generation',
          status: 'pending',
          parameters: {
            prompt: jobDto.prompt,
            model: jobDto.model,
            size: jobDto.size,
            quality: jobDto.quality,
            style: jobDto.style,
            n: jobDto.n || 1,
          },
          estimated_cost: cost,
        })
        .select()
        .single();

      if (jobError) {
        this.logger.error('Failed to create job:', jobError);
        throw new BadRequestException('Failed to create image generation job');
      }

      // Start image generation process
      this.processImageGenerationJob(job.id, jobDto);

      return job;
    } catch (error) {
      this.logger.error('Error creating image generation job:', error);
      throw error;
    }
  }

  /**
   * Get specific job
   */
  async getJob(jobId: string, userId: string) {
    try {
      const { data, error } = await this.supabaseService
        .from('jobs')
        .select('*')
        .eq('id', jobId)
        .eq('user_id', userId)
        .single();

      if (error || !data) {
        throw new NotFoundException('Job not found');
      }

      return data;
    } catch (error) {
      this.logger.error('Error getting job:', error);
      throw error;
    }
  }

  /**
   * Delete/Cancel job
   */
  async deleteJob(jobId: string, userId: string) {
    try {
      const job = await this.getJob(jobId, userId);

      // If job is pending, cancel it
      if (job.status === 'pending' || job.status === 'processing') {
        await this.supabaseService
          .from('jobs')
          .update({ status: 'cancelled' })
          .eq('id', jobId);
      } else {
        // Delete completed/failed jobs
        await this.supabaseService
          .from('jobs')
          .delete()
          .eq('id', jobId)
          .eq('user_id', userId);
      }

      return { message: 'Job cancelled/deleted successfully' };
    } catch (error) {
      this.logger.error('Error deleting job:', error);
      throw error;
    }
  }

  /**
   * Retry failed job
   */
  async retryJob(jobId: string, userId: string) {
    try {
      const job = await this.getJob(jobId, userId);

      if (job.status !== 'failed') {
        throw new BadRequestException('Only failed jobs can be retried');
      }

      // Update job status to pending
      await this.supabaseService
        .from('jobs')
        .update({ 
          status: 'pending',
          error_message: null,
          updated_at: new Date().toISOString(),
        })
        .eq('id', jobId);

      // Restart the process
      if (job.type === 'image_generation') {
        this.processImageGenerationJob(jobId, job.parameters);
      }

      return { message: 'Job retry initiated successfully' };
    } catch (error) {
      this.logger.error('Error retrying job:', error);
      throw error;
    }
  }

  /**
   * Get available image models
   */
  async getAvailableImageModels() {
    return {
      models: this.imageModels,
    };
  }

  /**
   * Estimate image generation cost
   */
  async estimateImageGenerationCost(estimateDto: any) {
    try {
      const cost = this.calculateImageCost(estimateDto);
      return {
        estimatedCost: cost,
        currency: 'USD',
        breakdown: {
          model: estimateDto.model,
          size: estimateDto.size,
          quality: estimateDto.quality,
          quantity: estimateDto.n || 1,
          unitCost: cost / (estimateDto.n || 1),
        },
      };
    } catch (error) {
      this.logger.error('Error estimating cost:', error);
      throw new BadRequestException('Failed to estimate cost');
    }
  }

  /**
   * Calculate image generation cost
   */
  private calculateImageCost(params: any): number {
    const model = this.imageModels[params.model];
    if (!model) {
      throw new BadRequestException('Invalid model');
    }

    const quality = params.quality || 'standard';
    const size = params.size || '1024x1024';
    const quantity = params.n || 1;

    const priceKey = `${quality}-${size}`;
    const unitPrice = model.pricing[priceKey];

    if (!unitPrice) {
      throw new BadRequestException('Invalid size/quality combination for this model');
    }

    return unitPrice * quantity;
  }

  /**
   * Process image generation job (async)
   */
  private async processImageGenerationJob(jobId: string, parameters: any) {
    try {
      // Update job status to processing
      await this.supabaseService
        .from('jobs')
        .update({ status: 'processing' })
        .eq('id', jobId);

      // Generate image using ImageRouter service
      const result = await this.imageRouterService.generateImage(
        {
          prompt: parameters.prompt,
          model: parameters.model,
          size: parameters.size,
          quality: parameters.quality,
        },
        'your-api-key-here' // This should come from environment or user config
      );

      // Update job with results
      await this.supabaseService
        .from('jobs')
        .update({
          status: 'completed',
          result: result,
          completed_at: new Date().toISOString(),
        })
        .eq('id', jobId);

    } catch (error) {
      this.logger.error('Error processing image generation job:', error);

      // Update job with error
      await this.supabaseService
        .from('jobs')
        .update({
          status: 'failed',
          error_message: error.message,
        })
        .eq('id', jobId);
    }
  }
}
