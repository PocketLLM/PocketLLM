import { PipeTransform, Injectable, ArgumentMetadata, BadRequestException } from '@nestjs/common';
import { ZodSchema, ZodError } from 'zod';

@Injectable()
export class ZodValidationPipe implements PipeTransform {
  constructor(private schema: ZodSchema) {}

  transform(value: any, metadata: ArgumentMetadata) {
    try {
      const parsedValue = this.schema.parse(value);
      return parsedValue;
    } catch (error) {
      if (error instanceof ZodError) {
        const errorMessages = error.errors.map(err => ({
          field: err.path.join('.'),
          message: err.message,
        }));
        throw new BadRequestException({
          message: 'Validation failed',
          errors: errorMessages,
        });
      }
      throw new BadRequestException('Validation failed');
    }
  }
}

// Helper function to create validation pipes for different parts of the request
export function createZodDto(schemas: {
  body?: ZodSchema;
  params?: ZodSchema;
  query?: ZodSchema;
}) {
  return function (target: any, propertyName: string, descriptor: PropertyDescriptor) {
    const method = descriptor.value;
    descriptor.value = async function (...args: any[]) {
      const [req] = args;
      
      // Validate body
      if (schemas.body && req.body) {
        try {
          req.body = schemas.body.parse(req.body);
        } catch (error) {
          if (error instanceof ZodError) {
            const errorMessages = error.errors.map(err => ({
              field: err.path.join('.'),
              message: err.message,
            }));
            throw new BadRequestException({
              message: 'Body validation failed',
              errors: errorMessages,
            });
          }
          throw new BadRequestException('Body validation failed');
        }
      }

      // Validate params
      if (schemas.params && req.params) {
        try {
          req.params = schemas.params.parse(req.params);
        } catch (error) {
          if (error instanceof ZodError) {
            const errorMessages = error.errors.map(err => ({
              field: err.path.join('.'),
              message: err.message,
            }));
            throw new BadRequestException({
              message: 'Params validation failed',
              errors: errorMessages,
            });
          }
          throw new BadRequestException('Params validation failed');
        }
      }

      // Validate query
      if (schemas.query && req.query) {
        try {
          req.query = schemas.query.parse(req.query);
        } catch (error) {
          if (error instanceof ZodError) {
            const errorMessages = error.errors.map(err => ({
              field: err.path.join('.'),
              message: err.message,
            }));
            throw new BadRequestException({
              message: 'Query validation failed',
              errors: errorMessages,
            });
          }
          throw new BadRequestException('Query validation failed');
        }
      }

      return method.apply(this, args);
    };
  };
}
