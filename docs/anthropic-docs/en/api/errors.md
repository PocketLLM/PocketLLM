# Errors - Claude Docs> Source: https://docs.claude.com/en/api/errorsAgent Skills are now available! [Learn more about extending Claude's capabilities with Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview).
[Claude Docs home page![light logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/light.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=c877c45432515ee69194cb19e9f983a2)![dark logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/dark.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=f5bb877be0cb3cba86cf6d7c88185216)](https://docs.claude.com/)
![US](https://d3gk2c5xim1je2.cloudfront.net/flags/US.svg)
English
Search...
Ctrl K
  * [Console](https://console.anthropic.com/login)
  * [Support](https://support.claude.com/)
  * [Discord](https://www.anthropic.com/discord)
  * [Sign up](https://console.anthropic.com/login)
  * [Sign up](https://console.anthropic.com/login)


Search...
Navigation
Using the API
Errors
[Home](https://docs.claude.com/en/home)[Developer Guide](https://docs.claude.com/en/docs/intro)[API Reference](https://docs.claude.com/en/api/overview)[Model Context Protocol (MCP)](https://docs.claude.com/en/docs/mcp)[Resources](https://docs.claude.com/en/resources/overview)[Release Notes](https://docs.claude.com/en/release-notes/overview)
##### Using the API
  * [Features overview](https://docs.claude.com/en/api/overview)
  * [Client SDKs](https://docs.claude.com/en/api/client-sdks)
  * [Beta headers](https://docs.claude.com/en/api/beta-headers)
  * [Errors](https://docs.claude.com/en/api/errors)


##### Messages
  * [POSTMessages](https://docs.claude.com/en/api/messages)
  * [POSTCount Message tokens](https://docs.claude.com/en/api/messages-count-tokens)


##### Models
  * [GETList Models](https://docs.claude.com/en/api/models-list)
  * [GETGet a Model](https://docs.claude.com/en/api/models)


##### Message Batches
  * [POSTCreate a Message Batch](https://docs.claude.com/en/api/creating-message-batches)
  * [GETRetrieve a Message Batch](https://docs.claude.com/en/api/retrieving-message-batches)
  * [GETRetrieve Message Batch Results](https://docs.claude.com/en/api/retrieving-message-batch-results)
  * [GETList Message Batches](https://docs.claude.com/en/api/listing-message-batches)
  * [POSTCancel a Message Batch](https://docs.claude.com/en/api/canceling-message-batches)
  * [DELDelete a Message Batch](https://docs.claude.com/en/api/deleting-message-batches)


##### Files
  * [POSTCreate a File](https://docs.claude.com/en/api/files-create)
  * [GETList Files](https://docs.claude.com/en/api/files-list)
  * [GETGet File Metadata](https://docs.claude.com/en/api/files-metadata)
  * [GETDownload a File](https://docs.claude.com/en/api/files-content)
  * [DELDelete a File](https://docs.claude.com/en/api/files-delete)


##### Skills
  * Skill Management
  * Skill Versions


##### Admin API
  * Organization Info
  * Organization Member Management
  * Organization Invites
  * Workspace Management
  * Workspace Member Management
  * API Keys
  * Usage and Cost


##### Experimental APIs
  * Prompt tools


##### Text Completions (Legacy)
  * [Migrating from Text Completions](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages)


##### Support & configuration
  * [Rate limits](https://docs.claude.com/en/api/rate-limits)
  * [Service tiers](https://docs.claude.com/en/api/service-tiers)
  * [Versions](https://docs.claude.com/en/api/versioning)
  * [IP addresses](https://docs.claude.com/en/api/ip-addresses)
  * [Supported regions](https://docs.claude.com/en/api/supported-regions)
  * [OpenAI SDK compatibility](https://docs.claude.com/en/api/openai-sdk)


On this page
  * [HTTP errors](https://docs.claude.com/en/api/errors#http-errors)
  * [Request size limits](https://docs.claude.com/en/api/errors#request-size-limits)
  * [Error shapes](https://docs.claude.com/en/api/errors#error-shapes)
  * [Request id](https://docs.claude.com/en/api/errors#request-id)
  * [Long requests](https://docs.claude.com/en/api/errors#long-requests)


Using the API
# Errors
Copy page
Copy page
## 
[​](https://docs.claude.com/en/api/errors#http-errors)
HTTP errors
Our API follows a predictable HTTP error code format:
  * 400 - `invalid_request_error`: There was an issue with the format or content of your request. We may also use this error type for other 4XX status codes not listed below.
  * 401 - `authentication_error`: There’s an issue with your API key.
  * 403 - `permission_error`: Your API key does not have permission to use the specified resource.
  * 404 - `not_found_error`: The requested resource was not found.
  * 413 - `request_too_large`: Request exceeds the maximum allowed number of bytes. The maximum request size is 32 MB for standard API endpoints.
  * 429 - `rate_limit_error`: Your account has hit a rate limit.
  * 500 - `api_error`: An unexpected error has occurred internal to Anthropic’s systems.
  * 529 - `overloaded_error`: The API is temporarily overloaded.
529 errors can occur when APIs experience high traffic across all users.In rare cases, if your organization has a sharp increase in usage, you might see 429 errors due to acceleration limits on the API. To avoid hitting acceleration limits, ramp up your traffic gradually and maintain consistent usage patterns.

When receiving a [streaming](https://docs.claude.com/en/docs/build-with-claude/streaming) response via SSE, it’s possible that an error can occur after returning a 200 response, in which case error handling wouldn’t follow these standard mechanisms.
## 
[​](https://docs.claude.com/en/api/errors#request-size-limits)
Request size limits
The API enforces request size limits to ensure optimal performance: Endpoint Type | Maximum Request Size  
---|---  
Messages API | 32 MB  
Token Counting API | 32 MB  
[Batch API](https://docs.claude.com/en/docs/build-with-claude/batch-processing) | 256 MB  
[Files API](https://docs.claude.com/en/docs/build-with-claude/files) | 500 MB  
If you exceed these limits, you’ll receive a 413 `request_too_large` error. The error is returned from Cloudflare before the request reaches our API servers.
## 
[​](https://docs.claude.com/en/api/errors#error-shapes)
Error shapes
Errors are always returned as JSON, with a top-level `error` object that always includes a `type` and `message` value. The response also includes a `request_id` field for easier tracking and debugging. For example:
JSON
Copy
```
{
  "type": "error",
  "error": {
    "type": "not_found_error",
    "message": "The requested resource could not be found."
  },
  "request_id": "req_011CSHoEeqs5C35K2UUqR7Fy"
}

```

In accordance with our [versioning](https://docs.claude.com/en/api/versioning) policy, we may expand the values within these objects, and it is possible that the `type` values will grow over time.
## 
[​](https://docs.claude.com/en/api/errors#request-id)
Request id
Every API response includes a unique `request-id` header. This header contains a value such as `req_018EeWyXxfu5pfWkrYcMdjWG`. When contacting support about a specific request, please include this ID to help us quickly resolve your issue. Our official SDKs provide this value as a property on top-level response objects, containing the value of the `request-id` header:
Python
TypeScript
Copy
```
import anthropic
client = anthropic.Anthropic()
message = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "Hello, Claude"}
    ]
)
print(f"Request ID: {message._request_id}")

```

## 
[​](https://docs.claude.com/en/api/errors#long-requests)
Long requests
We highly encourage using the [streaming Messages API](https://docs.claude.com/en/docs/build-with-claude/streaming) or [Message Batches API](https://docs.claude.com/en/api/creating-message-batches) for long running requests, especially those over 10 minutes.
We do not recommend setting a large `max_tokens` values without using our [streaming Messages API](https://docs.claude.com/en/docs/build-with-claude/streaming) or [Message Batches API](https://docs.claude.com/en/api/creating-message-batches):
  * Some networks may drop idle connections after a variable period of time, which can cause the request to fail or timeout without receiving a response from Anthropic.
  * Networks differ in reliability; our [Message Batches API](https://docs.claude.com/en/api/creating-message-batches) can help you manage the risk of network issues by allowing you to poll for results rather than requiring an uninterrupted network connection.

If you are building a direct API integration, you should be aware that setting a [TCP socket keep-alive](https://tldp.org/HOWTO/TCP-Keepalive-HOWTO/programming.html) can reduce the impact of idle connection timeouts on some networks. Our [SDKs](https://docs.claude.com/en/api/client-sdks) will validate that your non-streaming Messages API requests are not expected to exceed a 10 minute timeout and also will set a socket option for TCP keep-alive.
Was this page helpful?
YesNo
[Beta headers](https://docs.claude.com/en/api/beta-headers)[Messages](https://docs.claude.com/en/api/messages)
Assistant
Responses are generated using AI and may contain mistakes.
[Claude Docs home page![light logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/light.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=c877c45432515ee69194cb19e9f983a2)![dark logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/dark.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=f5bb877be0cb3cba86cf6d7c88185216)](https://docs.claude.com/)
[x](https://x.com/AnthropicAI)[linkedin](https://www.linkedin.com/company/anthropicresearch)
Company
[Anthropic](https://www.anthropic.com/company)[Careers](https://www.anthropic.com/careers)[Economic Futures](https://www.anthropic.com/economic-futures)[Research](https://www.anthropic.com/research)[News](https://www.anthropic.com/news)[Trust center](https://trust.anthropic.com/)[Transparency](https://www.anthropic.com/transparency)
Help and security
[Availability](https://www.anthropic.com/supported-countries)[Status](https://status.anthropic.com/)[Support center](https://support.claude.com/)
Learn
[Courses](https://www.anthropic.com/learn)[MCP connectors](https://claude.com/partners/mcp)[Customer stories](https://www.claude.com/customers)[Engineering blog](https://www.anthropic.com/engineering)[Events](https://www.anthropic.com/events)[Powered by Claude](https://claude.com/partners/powered-by-claude)[Service partners](https://claude.com/partners/services)[Startups program](https://claude.com/programs/startups)
Terms and policies
[Privacy policy](https://www.anthropic.com/legal/privacy)[Disclosure policy](https://www.anthropic.com/responsible-disclosure-policy)[Usage policy](https://www.anthropic.com/legal/aup)[Commercial terms](https://www.anthropic.com/legal/commercial-terms)[Consumer terms](https://www.anthropic.com/legal/consumer-terms)
