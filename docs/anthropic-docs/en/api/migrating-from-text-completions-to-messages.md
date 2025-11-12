# Migrating from Text Completions - Claude Docs> Source: https://docs.claude.com/en/api/migrating-from-text-completions-to-messagesAgent Skills are now available! [Learn more about extending Claude's capabilities with Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview).
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
Text Completions (Legacy)
Migrating from Text Completions
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
  * [Inputs and outputs](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#inputs-and-outputs)
  * [Putting words in Claude’s mouth](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#putting-words-in-claude%E2%80%99s-mouth)
  * [System prompt](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#system-prompt)
  * [Model names](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#model-names)
  * [Stop reason](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#stop-reason)
  * [Specifying max tokens](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#specifying-max-tokens)
  * [Streaming format](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#streaming-format)


Text Completions (Legacy)
# Migrating from Text Completions
Copy page
Migrating from Text Completions to Messages
Copy page
The Text Completions API has been deprecated in favor of the Messages API.
When migrating from Text Completions to [Messages](https://docs.claude.com/en/api/messages), consider the following changes.
### 
[​](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#inputs-and-outputs)
Inputs and outputs
The largest change between Text Completions and the Messages is the way in which you specify model inputs and receive outputs from the model. With Text Completions, inputs are raw strings:
Python
Copy
```
prompt = "\n\nHuman: Hello there\n\nAssistant: Hi, I'm Claude. How can I help?\n\nHuman: Can you explain Glycolysis to me?\n\nAssistant:"

```

With Messages, you specify a list of input messages instead of a raw prompt:
Shorthand
Expanded
Copy
```
messages = [
  {"role": "user", "content": "Hello there."},
  {"role": "assistant", "content": "Hi, I'm Claude. How can I help?"},
  {"role": "user", "content": "Can you explain Glycolysis to me?"},
]

```

Each input message has a `role` and `content`.
**Role names** The Text Completions API expects alternating `\n\nHuman:` and `\n\nAssistant:` turns, but the Messages API expects `user` and `assistant` roles. You may see documentation referring to either “human” or “user” turns. These refer to the same role, and will be “user” going forward.
With Text Completions, the model’s generated text is returned in the `completion` values of the response:
Python
Copy
```
>>> response = anthropic.completions.create(...)
>>> response.completion
" Hi, I'm Claude"

```

With Messages, the response is the `content` value, which is a list of content blocks:
Python
Copy
```
>>> response = anthropic.messages.create(...)
>>> response.content
[{"type": "text", "text": "Hi, I'm Claude"}]

```

### 
[​](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#putting-words-in-claude%E2%80%99s-mouth)
Putting words in Claude’s mouth
With Text Completions, you can pre-fill part of Claude’s response:
Python
Copy
```
prompt = "\n\nHuman: Hello\n\nAssistant: Hello, my name is"

```

With Messages, you can achieve the same result by making the last input message have the `assistant` role:
Python
Copy
```
messages = [
  {"role": "human", "content": "Hello"},
  {"role": "assistant", "content": "Hello, my name is"},
]

```

When doing so, response `content` will continue from the last input message `content`:
JSON
Copy
```
{
  "role": "assistant",
  "content": [{"type": "text", "text": " Claude. How can I assist you today?" }],
  ...
}

```

### 
[​](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#system-prompt)
System prompt
With Text Completions, the [system prompt](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/system-prompts) is specified by adding text before the first `\n\nHuman:` turn:
Python
Copy
```
prompt = "Today is January 1, 2024.\n\nHuman: Hello, Claude\n\nAssistant:"

```

With Messages, you specify the system prompt with the `system` parameter:
Python
Copy
```
anthropic.Anthropic().messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    system="Today is January 1, 2024.", # <-- system prompt
    messages=[
        {"role": "user", "content": "Hello, Claude"}
    ]
)

```

### 
[​](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#model-names)
Model names
The Messages API requires that you specify the full model version (e.g. `claude-sonnet-4-5-20250929`). We previously supported specifying only the major version number (e.g. `claude-2`), which resulted in automatic upgrades to minor versions. However, we no longer recommend this integration pattern, and Messages do not support it.
### 
[​](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#stop-reason)
Stop reason
Text Completions always have a `stop_reason` of either:
  * `"stop_sequence"`: The model either ended its turn naturally, or one of your custom stop sequences was generated.
  * `"max_tokens"`: Either the model generated your specified `max_tokens` of content, or it reached its [absolute maximum](https://docs.claude.com/en/docs/about-claude/models/overview#model-comparison-table).

Messages have a `stop_reason` of one of the following values:
  * `"end_turn"`: The conversational turn ended naturally.
  * `"stop_sequence"`: One of your specified custom stop sequences was generated.
  * `"max_tokens"`: (unchanged)


### 
[​](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#specifying-max-tokens)
Specifying max tokens
  * Text Completions: `max_tokens_to_sample` parameter. No validation, but capped values per-model.
  * Messages: `max_tokens` parameter. If passing a value higher than the model supports, returns a validation error.


### 
[​](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages#streaming-format)
Streaming format
When using `"stream": true` in with Text Completions, the response included any of `completion`, `ping`, and `error` server-sent-events. Messages can contain multiple content blocks of varying types, and so its streaming format is somewhat more complex. See [Messages streaming](https://docs.claude.com/en/docs/build-with-claude/streaming) for details.
Was this page helpful?
YesNo
[Templatize a prompt](https://docs.claude.com/en/api/prompt-tools-templatize)[Rate limits](https://docs.claude.com/en/api/rate-limits)
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
