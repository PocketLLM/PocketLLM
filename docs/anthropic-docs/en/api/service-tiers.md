# Service tiers - Claude Docs> Source: https://docs.claude.com/en/api/service-tiersAgent Skills are now available! [Learn more about extending Claude's capabilities with Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview).
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
Support & configuration
Service tiers
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
  * [Standard Tier](https://docs.claude.com/en/api/service-tiers#standard-tier)
  * [Priority Tier](https://docs.claude.com/en/api/service-tiers#priority-tier)
  * [How requests get assigned tiers](https://docs.claude.com/en/api/service-tiers#how-requests-get-assigned-tiers)
  * [Using service tiers](https://docs.claude.com/en/api/service-tiers#using-service-tiers)
  * [Get started with Priority Tier](https://docs.claude.com/en/api/service-tiers#get-started-with-priority-tier)
  * [Supported models](https://docs.claude.com/en/api/service-tiers#supported-models)
  * [How to access Priority Tier](https://docs.claude.com/en/api/service-tiers#how-to-access-priority-tier)


Support & configuration
# Service tiers
Copy page
Different tiers of service allow you to balance availability, performance, and predictable costs based on your application’s needs.
Copy page
We offer three service tiers:
  * **Priority Tier:** Best for workflows deployed in production where time, availability, and predictable pricing are important
  * **Standard:** Default tier for both piloting and scaling everyday use cases
  * **Batch:** Best for asynchronous workflows which can wait or benefit from being outside your normal capacity


## 
[​](https://docs.claude.com/en/api/service-tiers#standard-tier)
Standard Tier
The standard tier is the default service tier for all API requests. Requests in this tier are prioritized alongside all other requests and observe best-effort availability.
## 
[​](https://docs.claude.com/en/api/service-tiers#priority-tier)
Priority Tier
Requests in this tier are prioritized over all other requests to Anthropic. This prioritization helps minimize [“server overloaded” errors](https://docs.claude.com/en/api/errors#http-errors), even during peak times. For more information, see [Get started with Priority Tier](https://docs.claude.com/en/api/service-tiers#get-started-with-priority-tier)
## 
[​](https://docs.claude.com/en/api/service-tiers#how-requests-get-assigned-tiers)
How requests get assigned tiers
When handling a request, Anthropic decides to assign a request to Priority Tier in the following scenarios:
  * Your organization has sufficient priority tier capacity **input** tokens per minute
  * Your organization has sufficient priority tier capacity **output** tokens per minute

Anthropic counts usage against Priority Tier capacity as follows: **Input Tokens**
  * Cache reads as 0.1 tokens per token read from the cache
  * Cache writes as 1.25 tokens per token written to the cache with a 5 minute TTL
  * Cache writes as 2.00 tokens per token written to the cache with a 1 hour TTL
  * For [long-context](https://docs.claude.com/en/docs/build-with-claude/context-windows) (>200k input tokens) requests, input tokens are 2 tokens per token
  * All other input tokens are 1 token per token

**Output Tokens**
  * For [long-context](https://docs.claude.com/en/docs/build-with-claude/context-windows) (>200k input tokens) requests, output tokens are 1.5 tokens per token
  * All other output tokens are 1 token per token

Otherwise, requests proceed at standard tier.
Requests assigned Priority Tier pull from both the Priority Tier capacity and the regular rate limits. If servicing the request would exceed the rate limits, the request is declined.
## 
[​](https://docs.claude.com/en/api/service-tiers#using-service-tiers)
Using service tiers
You can control which service tiers can be used for a request by setting the `service_tier` parameter:
Copy
```
message = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=[{"role": "user", "content": "Hello, Claude!"}],
    service_tier="auto"  # Automatically use Priority Tier when available, fallback to standard
)

```

The `service_tier` parameter accepts the following values:
  * `"auto"` (default) - Uses the Priority Tier capacity if available, falling back to your other capacity if not
  * `"standard_only"` - Only use standard tier capacity, useful if you don’t want to use your Priority Tier capacity

The response `usage` object also includes the service tier assigned to the request:
Copy
```
{
  "usage": {
    "input_tokens": 410,
    "cache_creation_input_tokens": 0,
    "cache_read_input_tokens": 0,
    "output_tokens": 585,
    "service_tier": "priority"
  }
}

```

This allows you to determine which service tier was assigned to the request. When requesting `service_tier="auto"` with a model with a Priority Tier commitment, these response headers provide insights:
Copy
```
anthropic-priority-input-tokens-limit: 10000
anthropic-priority-input-tokens-remaining: 9618
anthropic-priority-input-tokens-reset: 2025-01-12T23:11:59Z
anthropic-priority-output-tokens-limit: 10000
anthropic-priority-output-tokens-remaining: 6000
anthropic-priority-output-tokens-reset: 2025-01-12T23:12:21Z

```

You can use the presence of these headers to detect if your request was eligible for Priority Tier, even if it was over the limit.
## 
[​](https://docs.claude.com/en/api/service-tiers#get-started-with-priority-tier)
Get started with Priority Tier
You may want to commit to Priority Tier capacity if you are interested in:
  * **Higher availability** : Target 99.5% uptime with prioritized computational resources
  * **Cost Control** : Predictable spend and discounts for longer commitments
  * **Flexible overflow** : Automatically falls back to standard tier when you exceed your committed capacity

Committing to Priority Tier will involve deciding:
  * A number of input tokens per minute
  * A number of output tokens per minute
  * A commitment duration (1, 3, 6, or 12 months)
  * A specific model version


The ratio of input to output tokens you purchase matters. Sizing your Priority Tier capacity to align with your actual traffic patterns helps you maximize utilization of your purchased tokens.
### 
[​](https://docs.claude.com/en/api/service-tiers#supported-models)
Supported models
Priority Tier is supported by:
  * Claude Opus 4.1
  * Claude Opus 4
  * Claude Sonnet 4
  * Claude Sonnet 3.7
  * Claude Haiku 3.5

Check the [model overview page](https://docs.claude.com/en/docs/about-claude/models/overview) for more details on our models.
### 
[​](https://docs.claude.com/en/api/service-tiers#how-to-access-priority-tier)
How to access Priority Tier
To begin using Priority Tier:
  1. [Contact sales](https://claude.com/contact-sales/priority-tier) to complete provisioning
  2. (Optional) Update your API requests to optionally set the `service_tier` parameter to `auto`
  3. Monitor your usage through response headers and the Claude Console


Was this page helpful?
YesNo
[Rate limits](https://docs.claude.com/en/api/rate-limits)[Versions](https://docs.claude.com/en/api/versioning)
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
