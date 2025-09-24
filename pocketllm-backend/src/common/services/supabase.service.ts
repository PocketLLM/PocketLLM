import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { createClient, SupabaseClient } from '@supabase/supabase-js';

@Injectable()
export class SupabaseService {
  private readonly logger = new Logger(SupabaseService.name);
  private readonly supabaseAdmin: SupabaseClient;

  constructor(private configService: ConfigService) {
    const supabaseUrl = this.configService.get<string>('app.supabase.url');
    const supabaseServiceRoleKey = this.configService.get<string>('app.supabase.serviceRoleKey');

    if (!supabaseUrl || !supabaseServiceRoleKey) {
      const errorMessage = 'Supabase environment variables (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY) are not set!';
      this.logger.error(errorMessage);
      throw new Error('Supabase URL and service role key are required for server-side client.');
    }

    this.supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey);
    this.logger.log('Supabase client initialized successfully');
  }

  /**
   * Get the Supabase admin client instance
   * This client has administrative access and should be used carefully
   */
  getClient(): SupabaseClient {
    return this.supabaseAdmin;
  }

  /**
   * Get the auth admin client for user management
   */
  get auth() {
    return this.supabaseAdmin.auth;
  }

  /**
   * Get a table reference for database operations
   * @param tableName The name of the table
   */
  from(tableName: string) {
    return this.supabaseAdmin.from(tableName);
  }

  /**
   * Get the storage client for file operations
   */
  get storage() {
    return this.supabaseAdmin.storage;
  }

  /**
   * Execute a raw SQL query
   * @param query The SQL query to execute
   * @param params Optional parameters for the query
   */
  async rpc(functionName: string, params?: any) {
    return this.supabaseAdmin.rpc(functionName, params);
  }
}
