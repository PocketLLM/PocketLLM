# FIM 补全（Beta） | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/api/create-completion[跳到主要内容](https://api-docs.deepseek.com/zh-cn/api/create-completion#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/api/create-completion)
  * [English](https://api-docs.deepseek.com/api/create-completion)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/api/create-completion)


[DeepSeek Platform](https://platform.deepseek.com/)
  * [快速开始](https://api-docs.deepseek.com/zh-cn/)
    * [首次调用 API](https://api-docs.deepseek.com/zh-cn/)
    * [模型 & 价格](https://api-docs.deepseek.com/zh-cn/quick_start/pricing)
    * [Temperature 设置](https://api-docs.deepseek.com/zh-cn/quick_start/parameter_settings)
    * [Token 用量计算](https://api-docs.deepseek.com/zh-cn/quick_start/token_usage)
    * [限速](https://api-docs.deepseek.com/zh-cn/quick_start/rate_limit)
    * [错误码](https://api-docs.deepseek.com/zh-cn/quick_start/error_codes)
  * [新闻](https://api-docs.deepseek.com/zh-cn/news/news250929)
    * [DeepSeek-V3.2-Exp 发布 2025/09/29](https://api-docs.deepseek.com/zh-cn/news/news250929)
    * [DeepSeek V3.1 更新 2025/09/22](https://api-docs.deepseek.com/zh-cn/news/news250922)
    * [DeepSeek V3.1 发布 2025/08/21](https://api-docs.deepseek.com/zh-cn/news/news250821)
    * [DeepSeek-R1-0528 发布 2025/05/28](https://api-docs.deepseek.com/zh-cn/news/news250528)
    * [DeepSeek-V3-0324 发布 2025/03/25](https://api-docs.deepseek.com/zh-cn/news/news250325)
    * [DeepSeek-R1 发布 2025/01/20](https://api-docs.deepseek.com/zh-cn/news/news250120)
    * [DeepSeek APP 发布 2025/01/15](https://api-docs.deepseek.com/zh-cn/news/news250115)
    * [DeepSeek-V3 发布 2024/12/26](https://api-docs.deepseek.com/zh-cn/news/news1226)
    * [DeepSeek-V2.5-1210 发布 2024/12/10](https://api-docs.deepseek.com/zh-cn/news/news1210)
    * [DeepSeek-R1-Lite 发布 2024/11/20](https://api-docs.deepseek.com/zh-cn/news/news1120)
    * [DeepSeek-V2.5 发布 2024/09/05](https://api-docs.deepseek.com/zh-cn/news/news0905)
    * [API 上线硬盘缓存 2024/08/02](https://api-docs.deepseek.com/zh-cn/news/news0802)
    * [API 升级新功能 2024/07/25](https://api-docs.deepseek.com/zh-cn/news/news0725)
  * [API 文档](https://api-docs.deepseek.com/zh-cn/api/deepseek-api)
    * [基本信息](https://api-docs.deepseek.com/zh-cn/api/deepseek-api)
    * [对话（Chat）](https://api-docs.deepseek.com/zh-cn/api/create-chat-completion)
    * [补全（Completions）](https://api-docs.deepseek.com/zh-cn/api/create-completion)
      * [FIM 补全（Beta）](https://api-docs.deepseek.com/zh-cn/api/create-completion)
    * [模型（Model）](https://api-docs.deepseek.com/zh-cn/api/list-models)
    * [其它](https://api-docs.deepseek.com/zh-cn/api/get-user-balance)
  * [API 指南](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model)
    * [推理模型 (deepseek-reasoner)](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model)
    * [多轮对话](https://api-docs.deepseek.com/zh-cn/guides/multi_round_chat)
    * [对话前缀续写（Beta）](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion)
    * [FIM 补全（Beta）](https://api-docs.deepseek.com/zh-cn/guides/fim_completion)
    * [JSON Output](https://api-docs.deepseek.com/zh-cn/guides/json_mode)
    * [Function Calling](https://api-docs.deepseek.com/zh-cn/guides/function_calling)
    * [上下文硬盘缓存](https://api-docs.deepseek.com/zh-cn/guides/kv_cache)
    * [Anthropic API](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api)
  * [其它资源](https://github.com/deepseek-ai/awesome-deepseek-integration/tree/main)
    * [实用集成](https://github.com/deepseek-ai/awesome-deepseek-integration/tree/main)
    * [API 服务状态](https://status.deepseek.com/)
  * [常见问题](https://api-docs.deepseek.com/zh-cn/faq)
  * [更新日志](https://api-docs.deepseek.com/zh-cn/updates)


  * [](https://api-docs.deepseek.com/zh-cn/)
  * API 文档
  * 补全（Completions）
  * FIM 补全（Beta）


# FIM 补全（Beta）
```
POST 
## /completions

```

FIM（Fill-In-the-Middle）补全 API。
用户需要设置 `base_url="https://api.deepseek.com/beta"` 来使用此功能。
## Request[​](https://api-docs.deepseek.com/zh-cn/api/create-completion#request "Request的直接链接")
  * application/json


Body
**
required
**
**model** stringrequired
**Possible values:** [`deepseek-chat`]
模型的 ID
**prompt** stringrequired
**Default value:** `Once upon a time, `
用于生成完成内容的提示
**echo** booleannullable
在输出中，把 prompt 的内容也输出出来
**frequency_penalty** numbernullable
**Possible values:** `>= -2` and `<= 2`
**Default value:** `0`
介于 -2.0 和 2.0 之间的数字。如果该值为正，那么新 token 会根据其在已有文本中的出现频率受到相应的惩罚，降低模型重复相同内容的可能性。
**logprobs** integernullable
**Possible values:** `<= 20`
制定输出中包含 logprobs 最可能输出 token 的对数概率，包含采样的 token。例如，如果 logprobs 是 20，API 将返回一个包含 20 个最可能的 token 的列表。API 将始终返回采样 token 的对数概率，因此响应中可能会有最多 logprobs+1 个元素。
logprobs 的最大值是 20。
**max_tokens** integernullable
最大生成 token 数量。
**presence_penalty** numbernullable
**Possible values:** `>= -2` and `<= 2`
**Default value:** `0`
介于 -2.0 和 2.0 之间的数字。如果该值为正，那么新 token 会根据其是否已在已有文本中出现受到相应的惩罚，从而增加模型谈论新主题的可能性。
**
stop
**
object
**
nullable
**
一个 string 或最多包含 16 个 string 的 list，在遇到这些词时，API 将停止生成更多的 token。
oneOf
    * MOD1
    * MOD2
string
  * Array [
string
  * ]
**stream** booleannullable
如果设置为 True，将会以 SSE（server-sent events）的形式以流式发送消息增量。消息流以 `data: [DONE]` 结尾。
**
stream_options
**
object
nullable
流式输出相关选项。只有在 `stream` 参数为 `true` 时，才可设置此参数。
**include_usage** boolean
如果设置为 true，在流式消息最后的 `data: [DONE]` 之前将会传输一个额外的块。此块上的 usage 字段显示整个请求的 token 使用统计信息，而 choices 字段将始终是一个空数组。所有其他块也将包含一个 usage 字段，但其值为 null。
**suffix** stringnullable
制定被补全内容的后缀。
**temperature** numbernullable
**Possible values:** `<= 2`
**Default value:** `1`
采样温度，介于 0 和 2 之间。更高的值，如 0.8，会使输出更随机，而更低的值，如 0.2，会使其更加集中和确定。 我们通常建议可以更改这个值或者更改 `top_p`，但不建议同时对两者进行修改。
**top_p** numbernullable
**Possible values:** `<= 1`
**Default value:** `1`
作为调节采样温度的替代方案，模型会考虑前 `top_p` 概率的 token 的结果。所以 0.1 就意味着只有包括在最高 10% 概率中的 token 会被考虑。 我们通常建议修改这个值或者更改 `temperature`，但不建议同时对两者进行修改。


## Responses[​](https://api-docs.deepseek.com/zh-cn/api/create-completion#responses "Responses的直接链接")
  * 200


OK
  * application/json


  * Schema
  * Example (from schema)


**
Schema
**
**id** stringrequired
补全响应的 ID。
**
choices
**
object[]
required
模型生成的补全内容的选择列表。
  * Array [
**finish_reason** stringrequired
**Possible values:** [`stop`, `length`, `content_filter`, `insufficient_system_resource`]
模型停止生成 token 的原因。
`stop`：模型自然停止生成，或遇到 `stop` 序列中列出的字符串。
`length` ：输出长度达到了模型上下文长度限制，或达到了 `max_tokens` 的限制。
`content_filter`：输出内容因触发过滤策略而被过滤。
`insufficient_system_resource`: 由于后端推理资源受限，请求被打断。
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
标志补全请求开始时间的 Unix 时间戳（以秒为单位）。
**model** stringrequired
补全请求所用的模型。
**system_fingerprint** string
模型运行时的后端配置的指纹。
**object** stringrequired
**Possible values:** [`text_completion`]
object 的类型，一定为"text_completion"
**
usage
**
object
该对话补全请求的用量信息。
**completion_tokens** integerrequired
模型 completion 产生的 token 数。
**prompt_tokens** integerrequired
用户 prompt 所包含的 token 数。该值等于 `prompt_cache_hit_tokens + prompt_cache_miss_tokens`
**prompt_cache_hit_tokens** integerrequired
用户 prompt 中，命中上下文缓存的 token 数。
**prompt_cache_miss_tokens** integerrequired
用户 prompt 中，未命中上下文缓存的 token 数。
**total_tokens** integerrequired
该请求中，所有 token 的数量（prompt + completion）。
**
completion_tokens_details
**
object
completion tokens 的详细信息。
**reasoning_tokens** integer
推理模型所产生的思维链 token 数量


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
[上一页 对话补全](https://api-docs.deepseek.com/zh-cn/api/create-chat-completion)[下一页 列出模型](https://api-docs.deepseek.com/zh-cn/api/list-models)
微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
