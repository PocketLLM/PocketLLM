import { 
  Controller, 
  Get, 
  Post, 
  Delete, 
  Body,
  Param,
  Query,
  Req,
  UseGuards,
  HttpCode,
  HttpStatus
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiBearerAuth } from '@nestjs/swagger';
import { JobsService } from './jobs.service';
import { AuthGuard } from '../common/guards/auth.guard';

@ApiTags('Jobs')
@Controller('jobs')
@UseGuards(AuthGuard)
@ApiBearerAuth()
export class JobsController {
  constructor(private readonly jobsService: JobsService) {}

  @Get()
  @ApiOperation({ 
    summary: 'Get user jobs',
    description: 'Retrieve all jobs for the authenticated user'
  })
  @ApiResponse({
    status: 200,
    description: 'Jobs retrieved successfully',
  })
  async getJobs(
    @Req() request: any,
    @Query('status') status?: string,
    @Query('type') type?: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number
  ) {
    const userId = request.user?.id;
    return this.jobsService.getJobs(userId, { status, type, limit, offset });
  }

  @Post('image-generation')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ 
    summary: 'Create image generation job',
    description: 'Create a new image generation job'
  })
  @ApiResponse({
    status: 201,
    description: 'Image generation job created successfully',
  })
  async createImageGenerationJob(@Body() jobDto: any, @Req() request: any) {
    const userId = request.user?.id;
    return this.jobsService.createImageGenerationJob(userId, jobDto);
  }

  @Get(':jobId')
  @ApiOperation({ 
    summary: 'Get job by ID',
    description: 'Retrieve a specific job by its ID'
  })
  @ApiResponse({
    status: 200,
    description: 'Job retrieved successfully',
  })
  async getJob(@Param('jobId') jobId: string, @Req() request: any) {
    const userId = request.user?.id;
    return this.jobsService.getJob(jobId, userId);
  }

  @Delete(':jobId')
  @ApiOperation({ 
    summary: 'Cancel/Delete job',
    description: 'Cancel a pending job or delete a completed job'
  })
  @ApiResponse({
    status: 200,
    description: 'Job cancelled/deleted successfully',
  })
  async deleteJob(@Param('jobId') jobId: string, @Req() request: any) {
    const userId = request.user?.id;
    return this.jobsService.deleteJob(jobId, userId);
  }

  @Post(':jobId/retry')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Retry failed job',
    description: 'Retry a failed job'
  })
  @ApiResponse({
    status: 200,
    description: 'Job retry initiated successfully',
  })
  async retryJob(@Param('jobId') jobId: string, @Req() request: any) {
    const userId = request.user?.id;
    return this.jobsService.retryJob(jobId, userId);
  }

  @Get('image-generation/models')
  @ApiOperation({ 
    summary: 'Get available image models',
    description: 'Retrieve available image generation models and their pricing'
  })
  @ApiResponse({
    status: 200,
    description: 'Image models retrieved successfully',
  })
  async getImageModels() {
    return this.jobsService.getAvailableImageModels();
  }

  @Post('image-generation/estimate-cost')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Estimate image generation cost',
    description: 'Estimate the cost for image generation based on parameters'
  })
  @ApiResponse({
    status: 200,
    description: 'Cost estimation completed successfully',
  })
  async estimateImageCost(@Body() estimateDto: any) {
    return this.jobsService.estimateImageGenerationCost(estimateDto);
  }
}
