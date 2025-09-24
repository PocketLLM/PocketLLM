import { 
  Controller, 
  Get, 
  Post, 
  Delete, 
  Body, 
  Param, 
  Query, 
  Req, 
  HttpCode, 
  HttpStatus 
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiBearerAuth } from '@nestjs/swagger';
import { EmbeddingsService } from './embeddings.service';

@ApiTags('Embeddings')
@Controller('embeddings')
@ApiBearerAuth()
export class EmbeddingsController {
  constructor(private readonly embeddingsService: EmbeddingsService) {}

  @Post('generate')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ 
    summary: 'Generate embeddings',
    description: 'Generate embeddings for text input'
  })
  @ApiResponse({
    status: 201,
    description: 'Embeddings generated successfully',
  })
  async generateEmbeddings(@Body() embeddingDto: any, @Req() request: any) {
    const userId = request.user?.id;
    return this.embeddingsService.generateEmbeddings(userId, embeddingDto);
  }

  @Post('search')
  @HttpCode(HttpStatus.OK)
  @ApiOperation({ 
    summary: 'Search embeddings',
    description: 'Search for similar embeddings using vector similarity'
  })
  @ApiResponse({
    status: 200,
    description: 'Search completed successfully',
  })
  async searchEmbeddings(@Body() searchDto: any, @Req() request: any) {
    const userId = request.user?.id;
    return this.embeddingsService.searchEmbeddings(userId, searchDto);
  }

  @Get('collections')
  @ApiOperation({ 
    summary: 'Get embedding collections',
    description: 'Retrieve all embedding collections for the user'
  })
  @ApiResponse({
    status: 200,
    description: 'Collections retrieved successfully',
  })
  async getCollections(@Req() request: any) {
    const userId = request.user?.id;
    return this.embeddingsService.getCollections(userId);
  }

  @Post('collections')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ 
    summary: 'Create embedding collection',
    description: 'Create a new embedding collection'
  })
  @ApiResponse({
    status: 201,
    description: 'Collection created successfully',
  })
  async createCollection(@Body() collectionDto: any, @Req() request: any) {
    const userId = request.user?.id;
    return this.embeddingsService.createCollection(userId, collectionDto);
  }

  @Get('collections/:collectionId')
  @ApiOperation({ 
    summary: 'Get collection embeddings',
    description: 'Retrieve embeddings from a specific collection'
  })
  @ApiResponse({
    status: 200,
    description: 'Collection embeddings retrieved successfully',
  })
  async getCollectionEmbeddings(
    @Param('collectionId') collectionId: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
    @Req() request?: any
  ) {
    const userId = request.user?.id;
    return this.embeddingsService.getCollectionEmbeddings(collectionId, userId, { limit, offset });
  }

  @Delete('collections/:collectionId')
  @ApiOperation({ 
    summary: 'Delete collection',
    description: 'Delete an embedding collection and all its embeddings'
  })
  @ApiResponse({
    status: 200,
    description: 'Collection deleted successfully',
  })
  async deleteCollection(@Param('collectionId') collectionId: string, @Req() request: any) {
    const userId = request.user?.id;
    return this.embeddingsService.deleteCollection(collectionId, userId);
  }

  @Get(':embeddingId')
  @ApiOperation({ 
    summary: 'Get embedding by ID',
    description: 'Retrieve a specific embedding by its ID'
  })
  @ApiResponse({
    status: 200,
    description: 'Embedding retrieved successfully',
  })
  async getEmbedding(@Param('embeddingId') embeddingId: string, @Req() request: any) {
    const userId = request.user?.id;
    return this.embeddingsService.getEmbedding(embeddingId, userId);
  }

  @Delete(':embeddingId')
  @ApiOperation({ 
    summary: 'Delete embedding',
    description: 'Delete a specific embedding'
  })
  @ApiResponse({
    status: 200,
    description: 'Embedding deleted successfully',
  })
  async deleteEmbedding(@Param('embeddingId') embeddingId: string, @Req() request: any) {
    const userId = request.user?.id;
    return this.embeddingsService.deleteEmbedding(embeddingId, userId);
  }

  @Get('models/available')
  @ApiOperation({ 
    summary: 'Get available embedding models',
    description: 'Retrieve list of available embedding models'
  })
  @ApiResponse({
    status: 200,
    description: 'Available models retrieved successfully',
  })
  async getAvailableModels() {
    return this.embeddingsService.getAvailableEmbeddingModels();
  }
}
