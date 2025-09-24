import { z } from 'zod';

// Generate Embeddings Schema
export const generateEmbeddingsSchema = {
  body: z.object({
    text: z.string().min(1, 'Text is required').max(8000, 'Text too long'),
    model: z.enum(['text-embedding-3-large', 'text-embedding-3-small', 'text-embedding-ada-002']),
    collectionId: z.string().uuid('Invalid collection ID').optional(),
    apiKey: z.string().min(1, 'API key is required'),
    metadata: z.record(z.any()).optional(),
  }),
};

// Search Embeddings Schema
export const searchEmbeddingsSchema = {
  body: z.object({
    query: z.string().min(1, 'Search query is required').max(1000, 'Query too long'),
    model: z.enum(['text-embedding-3-large', 'text-embedding-3-small', 'text-embedding-ada-002']),
    collectionId: z.string().uuid('Invalid collection ID').optional(),
    apiKey: z.string().min(1, 'API key is required'),
    limit: z.number().min(1).max(100).optional(),
    threshold: z.number().min(0).max(1).optional(),
  }),
};

// Create Collection Schema
export const createCollectionSchema = {
  body: z.object({
    name: z.string().min(1, 'Collection name is required').max(100, 'Name too long'),
    description: z.string().max(500, 'Description too long').optional(),
    metadata: z.record(z.any()).optional(),
  }),
};

// Collection Params Schema
export const collectionParamsSchema = {
  params: z.object({
    collectionId: z.string().uuid('Invalid collection ID format'),
  }),
};

// Embedding Params Schema
export const embeddingParamsSchema = {
  params: z.object({
    embeddingId: z.string().uuid('Invalid embedding ID format'),
  }),
};

// Collection Embeddings Query Schema
export const collectionEmbeddingsQuerySchema = {
  query: z.object({
    limit: z.coerce.number().positive().max(100).optional(),
    offset: z.coerce.number().min(0).optional(),
  }),
};

// Embedding Schema
export const embeddingSchema = z.object({
  id: z.string().uuid(),
  user_id: z.string().uuid(),
  collection_id: z.string().uuid().nullable(),
  text: z.string(),
  model: z.string(),
  embedding: z.array(z.number()),
  metadata: z.record(z.any()),
  token_count: z.number(),
  created_at: z.string(),
});

// Embedding Collection Schema
export const embeddingCollectionSchema = z.object({
  id: z.string().uuid(),
  user_id: z.string().uuid(),
  name: z.string(),
  description: z.string().nullable(),
  metadata: z.record(z.any()),
  embedding_count: z.number().optional(),
  created_at: z.string(),
  updated_at: z.string(),
});

// Embedding Model Schema
export const embeddingModelSchema = z.object({
  name: z.string(),
  provider: z.string(),
  dimensions: z.number(),
  maxTokens: z.number(),
  pricing: z.number(),
});

// Search Result Schema
export const searchResultSchema = z.object({
  id: z.string().uuid(),
  text: z.string(),
  metadata: z.record(z.any()),
  similarity: z.number(),
  created_at: z.string(),
});

// Type exports for TypeScript
export type GenerateEmbeddingsRequest = z.infer<typeof generateEmbeddingsSchema.body>;
export type SearchEmbeddingsRequest = z.infer<typeof searchEmbeddingsSchema.body>;
export type CreateCollectionRequest = z.infer<typeof createCollectionSchema.body>;
export type CollectionParams = z.infer<typeof collectionParamsSchema.params>;
export type EmbeddingParams = z.infer<typeof embeddingParamsSchema.params>;
export type CollectionEmbeddingsQuery = z.infer<typeof collectionEmbeddingsQuerySchema.query>;
export type Embedding = z.infer<typeof embeddingSchema>;
export type EmbeddingCollection = z.infer<typeof embeddingCollectionSchema>;
export type EmbeddingModel = z.infer<typeof embeddingModelSchema>;
export type SearchResult = z.infer<typeof searchResultSchema>;
