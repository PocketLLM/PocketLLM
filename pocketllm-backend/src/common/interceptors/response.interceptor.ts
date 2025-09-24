import {
  Injectable,
  NestInterceptor,
  ExecutionContext,
  CallHandler,
} from '@nestjs/common';
import { Observable } from 'rxjs';
import { map } from 'rxjs/operators';
import { Request, Response } from 'express';
import { v4 as uuidv4 } from 'uuid';

export interface ResponseMetadata {
  timestamp: string;
  requestId: string;
  processingTime: number;
}

export interface ApiResponse<T> {
  success: boolean;
  data: T | null;
  error: { message: string } | null;
  metadata: ResponseMetadata;
}

@Injectable()
export class ResponseInterceptor<T> implements NestInterceptor<T, ApiResponse<T>> {
  intercept(context: ExecutionContext, next: CallHandler): Observable<ApiResponse<T>> {
    const request = context.switchToHttp().getRequest<Request>();
    const startTime = Date.now();
    
    // Add request ID if not already present
    if (!request['requestId']) {
      request['requestId'] = uuidv4();
    }

    return next.handle().pipe(
      map((data) => {
        const processingTime = Date.now() - startTime;
        
        return {
          success: true,
          data: data,
          error: null,
          metadata: {
            timestamp: new Date().toISOString(),
            requestId: request['requestId'],
            processingTime: parseFloat(processingTime.toFixed(2)),
          },
        };
      }),
    );
  }
}
