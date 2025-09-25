# API Documentation Maintenance Guide

This guide explains how to maintain and update API documentation in the PocketLLM project, ensuring that all documentation stays synchronized with code changes.

## 📋 Documentation Files

The PocketLLM project maintains API documentation in multiple formats:

1. **Swagger/OpenAPI Documentation** - Automatically generated from code
2. **Postman Collection Guide** - [POSTMAN_API_GUIDE.md](../pocketllm-backend/POSTMAN_API_GUIDE.md)
3. **Comprehensive API Guide** - [api-documentation.md](api-documentation.md)

## 🔄 Keeping Documentation in Sync

### When to Update Documentation

Documentation should be updated whenever:

1. **New endpoints are added**
2. **Existing endpoints are modified**
3. **Request/response schemas change**
4. **Authentication methods are updated**
5. **Error handling is modified**
6. **New features are implemented**

### Update Process

#### 1. Code-First Approach (Swagger)

The backend uses NestJS Swagger decorators to automatically generate API documentation:

```typescript
@ApiOperation({ summary: 'Create a new chat' })
@ApiCreatedResponse({ type: Chat })
@Post()
async create(@Body() createChatDto: CreateChatDto) {
  // Implementation
}
```

When you modify controller methods, the Swagger documentation updates automatically.

#### 2. Postman Guide Updates

When modifying the Postman guide ([POSTMAN_API_GUIDE.md](../pocketllm-backend/POSTMAN_API_GUIDE.md)):

1. Update the relevant endpoint section
2. Modify request examples to match new schemas
3. Update response examples
4. Add new endpoints in the proper format

Format for each endpoint:
```markdown
### [HTTP Method] [Endpoint Path]
**Group:** [module name]  
**URL:** `http://localhost:8000/v1/[endpoint]`

**Headers:**
```
Authorization: Bearer <access_token>
```

**Body (JSON):**
```json
{
  "field": "value"
}
```

**Response:**
```json
{
  "success": true,
  "data": { ... }
}
```
```

#### 3. Comprehensive API Guide Updates

When updating the comprehensive API guide ([api-documentation.md](api-documentation.md)):

1. Update endpoint descriptions
2. Modify request/response examples
3. Add new sections for new features
4. Update error handling documentation

## 🛠️ Tools for Documentation Maintenance

### Swagger UI

The backend automatically generates Swagger documentation available at:
```
http://localhost:8000/api/docs (or http://localhost:8000/docs)
```

Production demo:
```
https://pocket-llm-lemon.vercel.app/docs (legacy path https://pocket-llm-lemon.vercel.app/api/docs)
```

To view the latest documentation:
1. Start the backend server: `npm run start:dev`
2. Navigate to the Swagger URL
3. Review and test endpoints

### Postman Collection

To maintain the Postman collection:

1. Import the existing collection
2. Update or add new requests
3. Export the updated collection
4. Update the examples in [POSTMAN_API_GUIDE.md](../pocketllm-backend/POSTMAN_API_GUIDE.md)

## 📝 Documentation Standards

### Consistency Guidelines

1. **Endpoint Descriptions**: Use clear, concise language
2. **Examples**: Provide realistic, working examples
3. **Response Formats**: Follow the standardized response format
4. **Error Handling**: Document common error scenarios
5. **Authentication**: Clearly indicate which endpoints require authentication

### Response Format Standard

All API responses should follow this format:

```json
{
  "success": true,
  "data": { ... },
  "error": null,
  "metadata": {
    "timestamp": "ISO timestamp",
    "requestId": "UUID",
    "processingTime": 123.45
  }
}
```

Error responses:
```json
{
  "success": false,
  "data": null,
  "error": {
    "message": "Error description"
  },
  "metadata": {
    "timestamp": "ISO timestamp",
    "requestId": "UUID",
    "processingTime": 123.45
  }
}
```

### HTTP Status Codes

Use standard HTTP status codes:

- **200**: Success
- **201**: Created
- **400**: Bad Request
- **401**: Unauthorized
- **403**: Forbidden
- **404**: Not Found
- **500**: Internal Server Error

## 🧪 Testing Documentation

### Verify Examples

1. Test all request examples to ensure they work
2. Verify response examples match actual output
3. Check that authentication examples are correct

### Update Process

1. Make code changes
2. Test endpoints with Swagger UI
3. Update Postman collection
4. Update documentation files
5. Verify all examples work

## 📚 Versioning Documentation

### API Versioning

The API uses URL versioning:
```
http://localhost:8000/v1/[endpoint]
```

When creating new API versions:
1. Create new directory in [pocketllm-backend/src/api/](../pocketllm-backend/src/api/)
2. Update documentation to reflect version differences
3. Maintain backward compatibility when possible

### Documentation Versioning

For major documentation changes:
1. Create versioned documentation files
2. Update README references
3. Maintain changelog of documentation changes

## 🔄 Automation Opportunities

### Future Improvements

1. **Automated Example Testing**: Create scripts to test all documentation examples
2. **Documentation Generation**: Generate documentation from code annotations
3. **Version Comparison**: Tools to compare API versions
4. **Interactive Documentation**: Enhanced Swagger with more examples

## 📋 Checklist for Documentation Updates

When making code changes that affect the API:

- [ ] Update controller method documentation
- [ ] Update Swagger annotations
- [ ] Test endpoint with Swagger UI
- [ ] Update Postman collection
- [ ] Update [POSTMAN_API_GUIDE.md](../pocketllm-backend/POSTMAN_API_GUIDE.md)
- [ ] Update [api-documentation.md](api-documentation.md)
- [ ] Verify all examples work
- [ ] Update README if needed
- [ ] Create pull request with changes

## 🆘 Troubleshooting Documentation Issues

### Common Problems

1. **Documentation Out of Sync**: Compare with actual endpoint behavior
2. **Broken Examples**: Test with curl or Postman
3. **Missing Endpoints**: Ensure all controllers are properly decorated
4. **Incorrect Response Formats**: Verify interceptors are working

### Resolution Steps

1. Identify the discrepancy
2. Test actual endpoint behavior
3. Update documentation to match reality
4. Verify changes with team
5. Commit updates

## 🤝 Contributing to Documentation

### Guidelines for Contributors

1. **Clarity**: Write clearly and concisely
2. **Accuracy**: Ensure all examples work
3. **Completeness**: Document all endpoints and parameters
4. **Consistency**: Follow existing formatting conventions
5. **Timeliness**: Update documentation with code changes

### Review Process

1. Submit documentation changes with code changes
2. Have team members review for accuracy
3. Test all examples before merging
4. Update related documentation files

By following this guide, you can ensure that the PocketLLM API documentation remains accurate, up-to-date, and useful for developers working with the API.