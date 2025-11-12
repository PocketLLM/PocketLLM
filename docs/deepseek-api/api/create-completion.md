# Create FIM Completion (Beta) | DeepSeek API Docs> Source: https://api-docs.deepseek.com/api/create-completion[Skip to main content](https://api-docs.deepseek.com/api/create-completion#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/api/create-completion)
  * [English](https://api-docs.deepseek.com/api/create-completion)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/api/create-completion)


[DeepSeek Platform](https://platform.deepseek.com/)
  * [Quick Start](https://api-docs.deepseek.com/)
    * [Your First API Call](https://api-docs.deepseek.com/)
    * [Models & Pricing](https://api-docs.deepseek.com/quick_start/pricing)
    * [The Temperature Parameter](https://api-docs.deepseek.com/quick_start/parameter_settings)
    * [Token & Token Usage](https://api-docs.deepseek.com/quick_start/token_usage)
    * [Rate Limit](https://api-docs.deepseek.com/quick_start/rate_limit)
    * [Error Codes](https://api-docs.deepseek.com/quick_start/error_codes)
  * [News](https://api-docs.deepseek.com/news/news250929)
    * [DeepSeek-V3.2-Exp Release 2025/09/29](https://api-docs.deepseek.com/news/news250929)
    * [DeepSeek V3.1 Update 2025/09/22](https://api-docs.deepseek.com/news/news250922)
    * [DeepSeek V3.1 Release 2025/08/21](https://api-docs.deepseek.com/news/news250821)
    * [DeepSeek-R1-0528 Release 2025/05/28](https://api-docs.deepseek.com/news/news250528)
    * [DeepSeek-V3-0324 Release 2025/03/25](https://api-docs.deepseek.com/news/news250325)
    * [DeepSeek-R1 Release 2025/01/20](https://api-docs.deepseek.com/news/news250120)
    * [DeepSeek APP 2025/01/15](https://api-docs.deepseek.com/news/news250115)
    * [Introducing DeepSeek-V3 2024/12/26](https://api-docs.deepseek.com/news/news1226)
    * [DeepSeek-V2.5-1210 Release 2024/12/10](https://api-docs.deepseek.com/news/news1210)
    * [DeepSeek-R1-Lite Release 2024/11/20](https://api-docs.deepseek.com/news/news1120)
    * [DeepSeek-V2.5 Release 2024/09/05](https://api-docs.deepseek.com/news/news0905)
    * [Context Caching is Available 2024/08/02](https://api-docs.deepseek.com/news/news0802)
    * [New API Features 2024/07/25](https://api-docs.deepseek.com/news/news0725)
  * [API Reference](https://api-docs.deepseek.com/api/deepseek-api)
    * [Introduction](https://api-docs.deepseek.com/api/deepseek-api)
    * [Chat](https://api-docs.deepseek.com/api/create-chat-completion)
    * [Completions](https://api-docs.deepseek.com/api/create-completion)
      * [Create FIM Completion (Beta)](https://api-docs.deepseek.com/api/create-completion)
    * [Models](https://api-docs.deepseek.com/api/list-models)
    * [Others](https://api-docs.deepseek.com/api/get-user-balance)
  * [API Guides](https://api-docs.deepseek.com/guides/reasoning_model)
    * [Reasoning Model (deepseek-reasoner)](https://api-docs.deepseek.com/guides/reasoning_model)
    * [Multi-round Conversation](https://api-docs.deepseek.com/guides/multi_round_chat)
    * [Chat Prefix Completion (Beta)](https://api-docs.deepseek.com/guides/chat_prefix_completion)
    * [FIM Completion (Beta)](https://api-docs.deepseek.com/guides/fim_completion)
    * [JSON Output](https://api-docs.deepseek.com/guides/json_mode)
    * [Function Calling](https://api-docs.deepseek.com/guides/function_calling)
    * [Context Caching](https://api-docs.deepseek.com/guides/kv_cache)
    * [Anthropic API](https://api-docs.deepseek.com/guides/anthropic_api)
  * [Other Resources](https://github.com/deepseek-ai/awesome-deepseek-integration/tree/main)
    * [Integrations](https://github.com/deepseek-ai/awesome-deepseek-integration/tree/main)
    * [API Status Page](https://status.deepseek.com/)
  * [FAQ](https://api-docs.deepseek.com/faq)
  * [Change Log](https://api-docs.deepseek.com/updates)


  * [](https://api-docs.deepseek.com/)
  * API Reference
  * Completions
  * Create FIM Completion (Beta)


# Create FIM Completion (Beta)
```
POST 
## /completions

```

The FIM (Fill-In-the-Middle) Completion API. User must set `base_url="https://api.deepseek.com/beta"` to use this feature.
## Request[​](https://api-docs.deepseek.com/api/create-completion#request "Direct link to Request")
  * application/json


Body
**
required
**
**model** stringrequired
**Possible values:** [`deepseek-chat`]
ID of the model to use.
**prompt** stringrequired
**Default value:** `Once upon a time, `
The prompt to generate completions for.
**echo** booleannullable
Echo back the prompt in addition to the completion
**frequency_penalty** numbernullable
**Possible values:** `>= -2` and `<= 2`
**Default value:** `0`
Number between -2.0 and 2.0. Positive values penalize new tokens based on their existing frequency in the text so far, decreasing the model's likelihood to repeat the same line verbatim.
**logprobs** integernullable
**Possible values:** `<= 20`
Include the log probabilities on the `logprobs` most likely output tokens, as well the chosen tokens. For example, if `logprobs` is 20, the API will return a list of the 20 most likely tokens. The API will always return the `logprob` of the sampled token, so there may be up to `logprobs+1` elements in the response.
The maximum value for `logprobs` is 20.
**max_tokens** integernullable
The maximum number of tokens that can be generated in the completion.
**presence_penalty** numbernullable
**Possible values:** `>= -2` and `<= 2`
**Default value:** `0`
Number between -2.0 and 2.0. Positive values penalize new tokens based on whether they appear in the text so far, increasing the model's likelihood to talk about new topics.
**
stop
**
object
**
nullable
**
Up to 16 sequences where the API will stop generating further tokens. The returned text will not contain the stop sequence.
oneOf
    * MOD1
    * MOD2
string
  * Array [
string
  * ]
**stream** booleannullable
Whether to stream back partial progress. If set, tokens will be sent as data-only [server-sent events](https://developer.mozilla.org/en-US/docs/Web/API/Server-sent_events/Using_server-sent_events#Event_stream_format) as they become available, with the stream terminated by a `data: [DONE]` message. [Example Python code](https://cookbook.openai.com/examples/how_to_stream_completions).
**
stream_options
**
object
nullable
Options for streaming response. Only set this when you set `stream: true`.
**include_usage** boolean
If set, an additional chunk will be streamed before the `data: [DONE]` message. The `usage` field on this chunk shows the token usage statistics for the entire request, and the `choices` field will always be an empty array. All other chunks will also include a `usage` field, but with a null value.
**suffix** stringnullable
The suffix that comes after a completion of inserted text.
**temperature** numbernullable
**Possible values:** `<= 2`
**Default value:** `1`
What sampling temperature to use, between 0 and 2. Higher values like 0.8 will make the output more random, while lower values like 0.2 will make it more focused and deterministic.
We generally recommend altering this or `top_p` but not both.
**top_p** numbernullable
**Possible values:** `<= 1`
**Default value:** `1`
An alternative to sampling with temperature, called nucleus sampling, where the model considers the results of the tokens with top_p probability mass. So 0.1 means only the tokens comprising the top 10% probability mass are considered.
We generally recommend altering this or `temperature` but not both.


## Responses[​](https://api-docs.deepseek.com/api/create-completion#responses "Direct link to Responses")
  * 200


OK
  * application/json


  * Schema
  * Example (from schema)


**
Schema
**
**id** stringrequired
A unique identifier for the completion.
**
choices
**
object[]
required
The list of completion choices the model generated for the input prompt.
  * Array [
**finish_reason** stringrequired
**Possible values:** [`stop`, `length`, `content_filter`, `insufficient_system_resource`]
The reason the model stopped generating tokens. This will be `stop` if the model hit a natural stop point or a provided stop sequence, `length` if the maximum number of tokens specified in the request was reached,  
`content_filter` if content was omitted due to a flag from our content filters, or `insufficient_system_resource` if the request is interrupted due to insufficient resource of the inference system.
**index** integerrequired
**
logprobs
**
object
nullable
required
**text_offset** integer[]
**token_logprobs** number[]
**tokens** string[]
**top_logprobs** object[]
**text** stringrequired
  * ]
**created** integerrequired
The Unix timestamp (in seconds) of when the completion was created.
**model** stringrequired
The model used for completion.
**system_fingerprint** string
This fingerprint represents the backend configuration that the model runs with.
**object** stringrequired
**Possible values:** [`text_completion`]
The object type, which is always "text_completion"
**
usage
**
object
Usage statistics for the completion request.
**completion_tokens** integerrequired
Number of tokens in the generated completion.
**prompt_tokens** integerrequired
Number of tokens in the prompt. It equals prompt_cache_hit_tokens + prompt_cache_miss_tokens.
**prompt_cache_hit_tokens** integerrequired
Number of tokens in the prompt that hits the context cache.
**prompt_cache_miss_tokens** integerrequired
Number of tokens in the prompt that misses the context cache.
**total_tokens** integerrequired
Total number of tokens used in the request (prompt + completion).
**
completion_tokens_details
**
object
Breakdown of tokens used in a completion.
**reasoning_tokens** integer
Tokens generated by the model for reasoning.


```
{  
  "id": "string",  
  "choices": [  
    {  
      "finish_reason": "stop",  
      "index": 0,  
      "logprobs": {  
        "text_offset": [  
          0  
        ],  
        "token_logprobs": [  
          0  
        ],  
        "tokens": [  
          "string"  
        ],  
        "top_logprobs": [  
          {}  
        ]  
      },  
      "text": "string"  
    }  
  ],  
  "created": 0,  
  "model": "string",  
  "system_fingerprint": "string",  
  "object": "text_completion",  
  "usage": {  
    "completion_tokens": 0,  
    "prompt_tokens": 0,  
    "prompt_cache_hit_tokens": 0,  
    "prompt_cache_miss_tokens": 0,  
    "total_tokens": 0,  
    "completion_tokens_details": {  
      "reasoning_tokens": 0  
    }  
  }  
}  

```

Loading...
[Previous Create Chat Completion](https://api-docs.deepseek.com/api/create-chat-completion)[Next Lists Models](https://api-docs.deepseek.com/api/list-models)
WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
