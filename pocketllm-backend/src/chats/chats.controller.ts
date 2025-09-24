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
  UseGuards,
  HttpCode,
  HttpStatus
} from '@nestjs/common';
import { ApiTags, ApiOperation, ApiResponse, ApiBody, ApiBearerAuth } from '@nestjs/swagger';
import { ChatsService } from './chats.service';
import { AuthGuard } from '../common/guards/auth.guard';

@ApiTags('Chats')
@Controller('chats')
@UseGuards(AuthGuard)
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
  async getChat(@Param('chatId') chatId: string, @Req() request: any) {
    const userId = request.user?.id;
    return this.chatsService.getChat(chatId, userId);
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
  async updateChat(
    @Param('chatId') chatId: string, 
    @Body() updateChatDto: any, 
    @Req() request: any
  ) {
    const userId = request.user?.id;
    return this.chatsService.updateChat(chatId, userId, updateChatDto);
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
  async deleteChat(@Param('chatId') chatId: string, @Req() request: any) {
    const userId = request.user?.id;
    return this.chatsService.deleteChat(chatId, userId);
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
  async sendMessage(
    @Param('chatId') chatId: string,
    @Body() messageDto: any,
    @Req() request: any
  ) {
    const userId = request.user?.id;
    return this.chatsService.sendMessage(chatId, userId, messageDto);
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
    @Param('chatId') chatId: string,
    @Query('limit') limit?: number,
    @Query('offset') offset?: number,
    @Req() request?: any
  ) {
    const userId = request.user?.id;
    return this.chatsService.getMessages(chatId, userId, { limit, offset });
  }
}
