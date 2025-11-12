# OpenAI SDK compatibility - Claude Docs> Source: https://docs.claude.com/en/api/openai-sdkAgent Skills are now available! [Learn more about extending Claude's capabilities with Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview).
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
OpenAI SDK compatibility
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
  * [Getting started with the OpenAI SDK](https://docs.claude.com/en/api/openai-sdk#getting-started-with-the-openai-sdk)
  * [Quick start example](https://docs.claude.com/en/api/openai-sdk#quick-start-example)
  * [Important OpenAI compatibility limitations](https://docs.claude.com/en/api/openai-sdk#important-openai-compatibility-limitations)
  * [API behavior](https://docs.claude.com/en/api/openai-sdk#api-behavior)
  * [Output quality considerations](https://docs.claude.com/en/api/openai-sdk#output-quality-considerations)
  * [System / Developer message hoisting](https://docs.claude.com/en/api/openai-sdk#system-%2F-developer-message-hoisting)
  * [Extended thinking support](https://docs.claude.com/en/api/openai-sdk#extended-thinking-support)
  * [Rate limits](https://docs.claude.com/en/api/openai-sdk#rate-limits)
  * [Detailed OpenAI Compatible API Support](https://docs.claude.com/en/api/openai-sdk#detailed-openai-compatible-api-support)
  * [Request fields](https://docs.claude.com/en/api/openai-sdk#request-fields)
  * [Simple fields](https://docs.claude.com/en/api/openai-sdk#simple-fields)
  * [tools / functions fields](https://docs.claude.com/en/api/openai-sdk#tools-%2F-functions-fields)
  * [messages array fields](https://docs.claude.com/en/api/openai-sdk#messages-array-fields)
  * [Response fields](https://docs.claude.com/en/api/openai-sdk#response-fields)
  * [Error message compatibility](https://docs.claude.com/en/api/openai-sdk#error-message-compatibility)
  * [Header compatibility](https://docs.claude.com/en/api/openai-sdk#header-compatibility)


Support & configuration
# OpenAI SDK compatibility
Copy page
Anthropic provides a compatibility layer that enables you to use the OpenAI SDK to test the Claude API. With a few code changes, you can quickly evaluate Anthropic model capabilities.
Copy page
This compatibility layer is primarily intended to test and compare model capabilities, and is not considered a long-term or production-ready solution for most use cases. While we do intend to keep it fully functional and not make breaking changes, our priority is the reliability and effectiveness of the [Claude API](https://docs.claude.com/en/api/overview).For more information on known compatibility limitations, see [Important OpenAI compatibility limitations](https://docs.claude.com/en/api/openai-sdk#important-openai-compatibility-limitations).If you encounter any issues with the OpenAI SDK compatibility feature, please let us know [here](https://forms.gle/oQV4McQNiuuNbz9n8).
For the best experience and access to Claude API full feature set ([PDF processing](https://docs.claude.com/en/docs/build-with-claude/pdf-support), [citations](https://docs.claude.com/en/docs/build-with-claude/citations), [extended thinking](https://docs.claude.com/en/docs/build-with-claude/extended-thinking), and [prompt caching](https://docs.claude.com/en/docs/build-with-claude/prompt-caching)), we recommend using the native [Claude API](https://docs.claude.com/en/api/overview).
## 
[​](https://docs.claude.com/en/api/openai-sdk#getting-started-with-the-openai-sdk)
Getting started with the OpenAI SDK
To use the OpenAI SDK compatibility feature, you’ll need to:
  1. Use an official OpenAI SDK
  2. Change the following 
     * Update your base URL to point to the Claude API
     * Replace your API key with an [Claude API key](https://console.anthropic.com/settings/keys)
     * Update your model name to use a [Claude model](https://docs.claude.com/en/docs/about-claude/models/overview)
  3. Review the documentation below for what features are supported


### 
[​](https://docs.claude.com/en/api/openai-sdk#quick-start-example)
Quick start example
Python
TypeScript
Copy
```
from openai import OpenAI
client = OpenAI(
    api_key="ANTHROPIC_API_KEY",  # Your Claude API key
    base_url="https://api.anthropic.com/v1/"  # the Claude API endpoint
)
response = client.chat.completions.create(
    model="claude-sonnet-4-5", # Anthropic model name
    messages=[
        {"role": "system", "content": "You are a helpful assistant."},
        {"role": "user", "content": "Who are you?"}
    ],
)
print(response.choices[0].message.content)

```

## 
[​](https://docs.claude.com/en/api/openai-sdk#important-openai-compatibility-limitations)
Important OpenAI compatibility limitations
#### 
[​](https://docs.claude.com/en/api/openai-sdk#api-behavior)
API behavior
Here are the most substantial differences from using OpenAI:
  * The `strict` parameter for function calling is ignored, which means the tool use JSON is not guaranteed to follow the supplied schema.
  * Audio input is not supported; it will simply be ignored and stripped from input
  * Prompt caching is not supported, but it is supported in [the Anthropic SDK](https://docs.claude.com/en/api/client-sdks)
  * System/developer messages are hoisted and concatenated to the beginning of the conversation, as Anthropic only supports a single initial system message.

Most unsupported fields are silently ignored rather than producing errors. These are all documented below.
#### 
[​](https://docs.claude.com/en/api/openai-sdk#output-quality-considerations)
Output quality considerations
If you’ve done lots of tweaking to your prompt, it’s likely to be well-tuned to OpenAI specifically. Consider using our [prompt improver in the Claude Console](https://console.anthropic.com/dashboard) as a good starting point.
#### 
[​](https://docs.claude.com/en/api/openai-sdk#system-%2F-developer-message-hoisting)
System / Developer message hoisting
Most of the inputs to the OpenAI SDK clearly map directly to Anthropic’s API parameters, but one distinct difference is the handling of system / developer prompts. These two prompts can be put throughout a chat conversation via OpenAI. Since Anthropic only supports an initial system message, we take all system/developer messages and concatenate them together with a single newline (`\n`) in between them. This full string is then supplied as a single system message at the start of the messages.
#### 
[​](https://docs.claude.com/en/api/openai-sdk#extended-thinking-support)
Extended thinking support
You can enable [extended thinking](https://docs.claude.com/en/docs/build-with-claude/extended-thinking) capabilities by adding the `thinking` parameter. While this will improve Claude’s reasoning for complex tasks, the OpenAI SDK won’t return Claude’s detailed thought process. For full extended thinking features, including access to Claude’s step-by-step reasoning output, use the native Claude API.
Python
TypeScript
Copy
```
response = client.chat.completions.create(
    model="claude-sonnet-4-5",
    messages=...,
    extra_body={
        "thinking": { "type": "enabled", "budget_tokens": 2000 }
    }
)

```

## 
[​](https://docs.claude.com/en/api/openai-sdk#rate-limits)
Rate limits
Rate limits follow Anthropic’s [standard limits](https://docs.claude.com/en/api/rate-limits) for the `/v1/messages` endpoint.
## 
[​](https://docs.claude.com/en/api/openai-sdk#detailed-openai-compatible-api-support)
Detailed OpenAI Compatible API Support
### 
[​](https://docs.claude.com/en/api/openai-sdk#request-fields)
Request fields
#### 
[​](https://docs.claude.com/en/api/openai-sdk#simple-fields)
Simple fields
Field | Support status  
---|---  
`model` | Use Claude model names  
`max_tokens` | Fully supported  
`max_completion_tokens` | Fully supported  
`stream` | Fully supported  
`stream_options` | Fully supported  
`top_p` | Fully supported  
`parallel_tool_calls` | Fully supported  
`stop` | All non-whitespace stop sequences work  
`temperature` | Between 0 and 1 (inclusive). Values greater than 1 are capped at 1.  
`n` | Must be exactly 1  
`logprobs` | Ignored  
`metadata` | Ignored  
`response_format` | Ignored  
`prediction` | Ignored  
`presence_penalty` | Ignored  
`frequency_penalty` | Ignored  
`seed` | Ignored  
`service_tier` | Ignored  
`audio` | Ignored  
`logit_bias` | Ignored  
`store` | Ignored  
`user` | Ignored  
`modalities` | Ignored  
`top_logprobs` | Ignored  
`reasoning_effort` | Ignored  
#### 
[​](https://docs.claude.com/en/api/openai-sdk#tools-%2F-functions-fields)
`tools` / `functions` fields
Show fields
  * Tools
  * Functions


`tools[n].function` fields Field | Support status  
---|---  
`name` | Fully supported  
`description` | Fully supported  
`parameters` | Fully supported  
`strict` | Ignored  
#### 
[​](https://docs.claude.com/en/api/openai-sdk#messages-array-fields)
`messages` array fields
Show fields
  * Developer role
  * System role
  * User role
  * Assistant role
  * Tool role
  * Function role


Fields for `messages[n].role == "developer"`
Developer messages are hoisted to beginning of conversation as part of the initial system message
Field | Support status  
---|---  
`content` | Fully supported, but hoisted  
`name` | Ignored  
### 
[​](https://docs.claude.com/en/api/openai-sdk#response-fields)
Response fields
Field | Support status  
---|---  
`id` | Fully supported  
`choices[]` | Will always have a length of 1  
`choices[].finish_reason` | Fully supported  
`choices[].index` | Fully supported  
`choices[].message.role` | Fully supported  
`choices[].message.content` | Fully supported  
`choices[].message.tool_calls` | Fully supported  
`object` | Fully supported  
`created` | Fully supported  
`model` | Fully supported  
`finish_reason` | Fully supported  
`content` | Fully supported  
`usage.completion_tokens` | Fully supported  
`usage.prompt_tokens` | Fully supported  
`usage.total_tokens` | Fully supported  
`usage.completion_tokens_details` | Always empty  
`usage.prompt_tokens_details` | Always empty  
`choices[].message.refusal` | Always empty  
`choices[].message.audio` | Always empty  
`logprobs` | Always empty  
`service_tier` | Always empty  
`system_fingerprint` | Always empty  
### 
[​](https://docs.claude.com/en/api/openai-sdk#error-message-compatibility)
Error message compatibility
The compatibility layer maintains consistent error formats with the OpenAI API. However, the detailed error messages will not be equivalent. We recommend only using the error messages for logging and debugging.
### 
[​](https://docs.claude.com/en/api/openai-sdk#header-compatibility)
Header compatibility
While the OpenAI SDK automatically manages headers, here is the complete list of headers supported by the Claude API for developers who need to work with them directly. Header | Support Status  
---|---  
`x-ratelimit-limit-requests` | Fully supported  
`x-ratelimit-limit-tokens` | Fully supported  
`x-ratelimit-remaining-requests` | Fully supported  
`x-ratelimit-remaining-tokens` | Fully supported  
`x-ratelimit-reset-requests` | Fully supported  
`x-ratelimit-reset-tokens` | Fully supported  
`retry-after` | Fully supported  
`request-id` | Fully supported  
`openai-version` | Always `2020-10-01`  
`authorization` | Fully supported  
`openai-processing-ms` | Always empty  
Was this page helpful?
YesNo
[Supported regions](https://docs.claude.com/en/api/supported-regions)
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
