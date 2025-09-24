import { 
  Controller, 
  Get, 
  Post, 
  Put, 
  Delete, 
  Body, 
  Param, 
  Query, 
  Req, 
  HttpCode,
  HttpStatus,
  UseGuards,
  UsePipes,
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiBearerAuth } from '@nestjs/swagger';
import { ChatsService } from './chats.service';
import { SupabaseAuthGuard } from '../auth/guards/supabase-auth.guard';
import {
  createChatSchema,
  updateChatSchema,
  sendMessageSchema,
  chatParamsSchema,
  getMessagesQuerySchema,
} from '../api/v1/schemas/chats.schemas';
import { ZodValidationPipe } from '../common/pipes/zod-validation.pipe';

@ApiTags('Chats')
@Controller('chats')
@UseGuards(SupabaseAuthGuard)
@ApiBearerAuth()
export class ChatsController {
  constructor(private readonly chatsService: ChatsService) {}

  @Get()
  @ApiOperation({ 
    summary: 'Get user chats',
    description: 'Retrieve all chats for the authenticated user'
  })
  @ApiResponse({
    status: 200,
    description: 'Chats retrieved successfully',
  })
  async getChats(@Req() request: any) {
    const userId = request.user?.id;
    return this.chatsService.getChats(userId);
  }

  @Post()
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ 
    summary: 'Create a new chat',
    description: 'Create a new chat conversation'
  })
  @ApiResponse({
    status: 201,
    description: 'Chat created successfully',
  })
  @UsePipes(new ZodValidationPipe(createChatSchema.body))
  async createChat(@Body() createChatDto: any, @Req() request: any) {
    const userId = request.user?.id;
    return this.chatsService.createChat(userId, createChatDto);
  }

  @Get(':chatId')
  @ApiOperation({ 
    summary: 'Get chat by ID',
    description: 'Retrieve a specific chat with its messages'
  })
  @ApiResponse({
    status: 200,
    description: 'Chat retrieved successfully',
  })
  @UsePipes(new ZodValidationPipe(chatParamsSchema.params))
  async getChat(@Param() params: any, @Req() request: any) {
    const userId = request.user?.id;
    return this.chatsService.getChat(params.chatId, userId);
  }

  @Put(':chatId')
  @ApiOperation({ 
    summary: 'Update chat',
    description: 'Update chat information'
  })
  @ApiResponse({
    status: 200,
    description: 'Chat updated successfully',
  })
  @UsePipes(new ZodValidationPipe(chatParamsSchema.params))
  @UsePipes(new ZodValidationPipe(updateChatSchema.body))
  async updateChat(
    @Param() params: any,
    @Body() updateChatDto: any,
    @Req() request: any
  ) {
    const userId = request.user?.id;
    return this.chatsService.updateChat(params.chatId, userId, updateChatDto);
  }

  @Delete(':chatId')
  @ApiOperation({ 
    summary: 'Delete chat',
    description: 'Delete a chat and all its messages'
  })
  @ApiResponse({
    status: 200,
    description: 'Chat deleted successfully',
  })
  @UsePipes(new ZodValidationPipe(chatParamsSchema.params))
  async deleteChat(@Param() params: any, @Req() request: any) {
    const userId = request.user?.id;
    return this.chatsService.deleteChat(params.chatId, userId);
  }

  @Post(':chatId/messages')
  @HttpCode(HttpStatus.CREATED)
  @ApiOperation({ 
    summary: 'Send message',
    description: 'Send a message in a chat and get AI response'
  })
  @ApiResponse({
    status: 201,
    description: 'Message sent successfully',
  })
  @UsePipes(new ZodValidationPipe(chatParamsSchema.params))
  @UsePipes(new ZodValidationPipe(sendMessageSchema.body))
  async sendMessage(
    @Param() params: any,
    @Body() messageDto: any,
    @Req() request: any
  ) {
    const userId = request.user?.id;
    return this.chatsService.sendMessage(params.chatId, userId, messageDto);
  }

  @Get(':chatId/messages')
  @ApiOperation({ 
    summary: 'Get chat messages',
    description: 'Retrieve all messages for a specific chat'
  })
  @ApiResponse({
    status: 200,
    description: 'Messages retrieved successfully',
  })
  async getMessages(
    @Param(new ZodValidationPipe(chatParamsSchema.params)) params: any,
    @Query(new ZodValidationPipe(getMessagesQuerySchema.query)) query: any,
    @Req() request?: any
  ) {
    const userId = request.user?.id;
    return this.chatsService.getMessages(params.chatId, userId, { limit: query.limit, offset: query.offset });
  }
}
