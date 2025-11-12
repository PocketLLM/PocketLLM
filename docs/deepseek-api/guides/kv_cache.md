# Context Caching | DeepSeek API Docs> Source: https://api-docs.deepseek.com/guides/kv_cache[Skip to main content](https://api-docs.deepseek.com/guides/kv_cache#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/guides/kv_cache)
  * [English](https://api-docs.deepseek.com/guides/kv_cache)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/kv_cache)


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
  * API Guides
  * Context Caching


On this page
# Context Caching
The DeepSeek API [Context Caching on Disk Technology](https://api-docs.deepseek.com/news/news0802) is enabled by default for all users, allowing them to benefit without needing to modify their code.
Each user request will trigger the construction of a hard disk cache. If subsequent requests have overlapping prefixes with previous requests, the overlapping part will only be fetched from the cache, which counts as a "cache hit."
Note: Between two requests, only the repeated **prefix** part can trigger a "cache hit." Please refer to the example below for more details.
* * *
## Example 1: Long Text Q&A[​](https://api-docs.deepseek.com/guides/kv_cache#example-1-long-text-qa "Direct link to Example 1: Long Text Q&A")
**First Request**
```
messages: [  
    {"role": "system", "content": "You are an experienced financial report analyst..."}  
    {"role": "user", "content": "<financial report content>\n\nPlease summarize the key information of this financial report."}  
]  

```

**Second Request**
```
messages: [  
    {"role": "system", "content": "You are an experienced financial report analyst..."}  
    {"role": "user", "content": "<financial report content>\n\nPlease analyze the profitability of this financial report."}  
]  

```

In the above example, both requests have the same **prefix** , which is the `system` message + `<financial report content>` in the `user` message. During the second request, this prefix part will count as a "cache hit."
* * *
## Example 2: Multi-round Conversation[​](https://api-docs.deepseek.com/guides/kv_cache#example-2-multi-round-conversation "Direct link to Example 2: Multi-round Conversation")
**First Request**
```
messages: [  
    {"role": "system", "content": "You are a helpful assistant"},  
    {"role": "user", "content": "What is the capital of China?"}  
]  

```

**Second Request**
```
messages: [  
    {"role": "system", "content": "You are a helpful assistant"},  
    {"role": "user", "content": "What is the capital of China?"},  
    {"role": "assistant", "content": "The capital of China is Beijing."},  
    {"role": "user", "content": "What is the capital of the United States?"}  
]  

```

In this example, the second request can reuse the **initial** `system` message and `user` message from the first request, which will count as a "cache hit."
* * *
## Example 3: Using Few-shot Learning[​](https://api-docs.deepseek.com/guides/kv_cache#example-3-using-few-shot-learning "Direct link to Example 3: Using Few-shot Learning")
In practical applications, users can enhance the model's output performance through few-shot learning. Few-shot learning involves providing a few examples in the request to allow the model to learn a specific pattern. Since few-shot generally provides the same context prefix, the cost of few-shot is significantly reduced with the support of context caching.
**First Request**
```
messages: [      
    {"role": "system", "content": "You are a history expert. The user will provide a series of questions, and your answers should be concise and start with `Answer:`"},  
    {"role": "user", "content": "In what year did Qin Shi Huang unify the six states?"},  
    {"role": "assistant", "content": "Answer: 221 BC"},  
    {"role": "user", "content": "Who was the founder of the Han Dynasty?"},  
    {"role": "assistant", "content": "Answer: Liu Bang"},  
    {"role": "user", "content": "Who was the last emperor of the Tang Dynasty?"},  
    {"role": "assistant", "content": "Answer: Li Zhu"},  
    {"role": "user", "content": "Who was the founding emperor of the Ming Dynasty?"},  
    {"role": "assistant", "content": "Answer: Zhu Yuanzhang"},  
    {"role": "user", "content": "Who was the founding emperor of the Qing Dynasty?"}  
]  

```

**Second Request**
```
messages: [      
    {"role": "system", "content": "You are a history expert. The user will provide a series of questions, and your answers should be concise and start with `Answer:`"},  
    {"role": "user", "content": "In what year did Qin Shi Huang unify the six states?"},  
    {"role": "assistant", "content": "Answer: 221 BC"},  
    {"role": "user", "content": "Who was the founder of the Han Dynasty?"},  
    {"role": "assistant", "content": "Answer: Liu Bang"},  
    {"role": "user", "content": "Who was the last emperor of the Tang Dynasty?"},  
    {"role": "assistant", "content": "Answer: Li Zhu"},  
    {"role": "user", "content": "Who was the founding emperor of the Ming Dynasty?"},  
    {"role": "assistant", "content": "Answer: Zhu Yuanzhang"},  
    {"role": "user", "content": "When did the Shang Dynasty fall?"},          
]  

```

In this example, 4-shots are used. The only difference between the two requests is the last question. The second request can reuse the content of the first 4 rounds of dialogue from the first request, which will count as a "cache hit."
* * *
## Checking Cache Hit Status[​](https://api-docs.deepseek.com/guides/kv_cache#checking-cache-hit-status "Direct link to Checking Cache Hit Status")
In the response from the DeepSeek API, we have added two fields in the `usage` section to reflect the cache hit status of the request:
  1. prompt_cache_hit_tokens: The number of tokens in the input of this request that resulted in a cache hit (0.1 yuan per million tokens).
  2. prompt_cache_miss_tokens: The number of tokens in the input of this request that did not result in a cache hit (1 yuan per million tokens).


## Hard Disk Cache and Output Randomness[​](https://api-docs.deepseek.com/guides/kv_cache#hard-disk-cache-and-output-randomness "Direct link to Hard Disk Cache and Output Randomness")
The hard disk cache only matches the prefix part of the user's input. The output is still generated through computation and inference, and it is influenced by parameters such as temperature, introducing randomness.
## Additional Notes[​](https://api-docs.deepseek.com/guides/kv_cache#additional-notes "Direct link to Additional Notes")
  1. The cache system uses 64 tokens as a storage unit; content less than 64 tokens will not be cached.
  2. The cache system works on a "best-effort" basis and does not guarantee a 100% cache hit rate.
  3. Cache construction takes seconds. Once the cache is no longer in use, it will be automatically cleared, usually within a few hours to a few days.


[Previous Function Calling](https://api-docs.deepseek.com/guides/function_calling)[Next Anthropic API](https://api-docs.deepseek.com/guides/anthropic_api)
  * [Example 1: Long Text Q&A](https://api-docs.deepseek.com/guides/kv_cache#example-1-long-text-qa)
  * [Example 2: Multi-round Conversation](https://api-docs.deepseek.com/guides/kv_cache#example-2-multi-round-conversation)
  * [Example 3: Using Few-shot Learning](https://api-docs.deepseek.com/guides/kv_cache#example-3-using-few-shot-learning)
  * [Checking Cache Hit Status](https://api-docs.deepseek.com/guides/kv_cache#checking-cache-hit-status)
  * [Hard Disk Cache and Output Randomness](https://api-docs.deepseek.com/guides/kv_cache#hard-disk-cache-and-output-randomness)
  * [Additional Notes](https://api-docs.deepseek.com/guides/kv_cache#additional-notes)


WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
