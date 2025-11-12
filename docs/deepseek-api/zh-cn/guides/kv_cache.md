# 上下文硬盘缓存 | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/guides/kv_cache[跳到主要内容](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/guides/kv_cache)
  * [English](https://api-docs.deepseek.com/guides/kv_cache)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/kv_cache)


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
  * API 指南
  * 上下文硬盘缓存


本页总览
# 上下文硬盘缓存
DeepSeek API [上下文硬盘缓存技术](https://api-docs.deepseek.com/zh-cn/news/news0802)对所有用户默认开启，用户无需修改代码即可享用。
用户的每一个请求都会触发硬盘缓存的构建。若后续请求与之前的请求在前缀上存在重复，则重复部分只需要从缓存中拉取，计入“缓存命中”。
注意：两个请求间，只有重复的**前缀** 部分才能触发“缓存命中”，详间下面的例子。
* * *
### 例一：长文本问答[​](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E4%BE%8B%E4%B8%80%E9%95%BF%E6%96%87%E6%9C%AC%E9%97%AE%E7%AD%94 "例一：长文本问答的直接链接")
**第一次请求**
```
messages: [  
    {"role": "system", "content": "你是一位资深的财报分析师..."}  
    {"role": "user", "content": "<财报内容>\n\n请总结一下这份财报的关键信息。"}  
]  

```

**第二次请求**
```
messages: [  
    {"role": "system", "content": "你是一位资深的财报分析师..."}  
    {"role": "user", "content": "<财报内容>\n\n请分析一下这份财报的盈利情况。"}  
]  

```

在上例中，两次请求都有相同的**前缀** ，即 `system` 消息 + `user` 消息中的 `<财报内容>`。在第二次请求时，这部分前缀会计入“缓存命中”。
* * *
### 例二：多轮对话[​](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E4%BE%8B%E4%BA%8C%E5%A4%9A%E8%BD%AE%E5%AF%B9%E8%AF%9D "例二：多轮对话的直接链接")
**第一次请求**
```
messages: [  
    {"role": "system", "content": "你是一位乐于助人的助手"},  
    {"role": "user", "content": "中国的首都是哪里？"}  
]  

```

**第二次请求**
```
messages: [  
    {"role": "system", "content": "你是一位乐于助人的助手"},  
    {"role": "user", "content": "中国的首都是哪里？"},  
    {"role": "assistant", "content": "中国的首都是北京。"},  
    {"role": "user", "content": "美国的首都是哪里？"}  
]  

```

在上例中，第二次请求可以复用第一次请求**开头** 的 `system` 消息和 `user` 消息，这部分会计入“缓存命中”。
* * *
### 例三：使用 Few-shot 学习[​](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E4%BE%8B%E4%B8%89%E4%BD%BF%E7%94%A8-few-shot-%E5%AD%A6%E4%B9%A0 "例三：使用 Few-shot 学习的直接链接")
在实际应用中，用户可以通过 Few-shot 学习的方式，来提升模型的输出效果。所谓 Few-shot 学习，是指在请求中提供一些示例，让模型学习到特定的模式。由于 Few-shot 一般提供相同的上下文前缀，在硬盘缓存的加持下，Few-shot 的费用显著降低。
**第一次请求**
```
messages: [      
        {"role": "system", "content": "你是一位历史学专家，用户将提供一系列问题，你的回答应当简明扼要，并以`Answer:`开头"},  
        {"role": "user", "content": "请问秦始皇统一六国是在哪一年？"},  
        {"role": "assistant", "content": "Answer:公元前221年"},  
        {"role": "user", "content": "请问汉朝的建立者是谁？"},  
        {"role": "assistant", "content": "Answer:刘邦"},  
        {"role": "user", "content": "请问唐朝最后一任皇帝是谁"},  
        {"role": "assistant", "content": "Answer:李柷"},  
        {"role": "user", "content": "请问明朝的开国皇帝是谁？"},  
        {"role": "assistant", "content": "Answer:朱元璋"},  
        {"role": "user", "content": "请问清朝的开国皇帝是谁？"}  
]  

```

**第二次请求**
```
messages: [      
        {"role": "system", "content": "你是一位历史学专家，用户将提供一系列问题，你的回答应当简明扼要，并以`Answer:`开头"},  
        {"role": "user", "content": "请问秦始皇统一六国是在哪一年？"},  
        {"role": "assistant", "content": "Answer:公元前221年"},  
        {"role": "user", "content": "请问汉朝的建立者是谁？"},  
        {"role": "assistant", "content": "Answer:刘邦"},  
        {"role": "user", "content": "请问唐朝最后一任皇帝是谁"},  
        {"role": "assistant", "content": "Answer:李柷"},  
        {"role": "user", "content": "请问明朝的开国皇帝是谁？"},  
        {"role": "assistant", "content": "Answer:朱元璋"},  
        {"role": "user", "content": "请问商朝是什么时候灭亡的"},          
]  

```

在上例中，使用了 4-shots。两次请求只有最后一个问题不一样，第二次请求可以复用第一次请求中前 4 轮对话的内容，这部分会计入“缓存命中”。
* * *
## 查看缓存命中情况[​](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E6%9F%A5%E7%9C%8B%E7%BC%93%E5%AD%98%E5%91%BD%E4%B8%AD%E6%83%85%E5%86%B5 "查看缓存命中情况的直接链接")
在 DeepSeek API 的返回中，我们在 `usage` 字段中增加了两个字段，来反映请求的缓存命中情况：
  1. `prompt_cache_hit_tokens`：本次请求的输入中，缓存命中的 tokens 数（0.1 元 / 百万 tokens）
  2. `prompt_cache_miss_tokens`：本次请求的输入中，缓存未命中的 tokens 数（1 元 / 百万 tokens）


## 硬盘缓存与输出随机性[​](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E7%A1%AC%E7%9B%98%E7%BC%93%E5%AD%98%E4%B8%8E%E8%BE%93%E5%87%BA%E9%9A%8F%E6%9C%BA%E6%80%A7 "硬盘缓存与输出随机性的直接链接")
硬盘缓存只匹配到用户输入的前缀部分，输出仍然是通过计算推理得到的，仍然受到 temperature 等参数的影响，从而引入随机性。其输出效果与不使用硬盘缓存相同。
## 其它说明[​](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E5%85%B6%E5%AE%83%E8%AF%B4%E6%98%8E "其它说明的直接链接")
  1. 缓存系统以 64 tokens 为一个存储单元，不足 64 tokens 的内容不会被缓存
  2. 缓存系统是“尽力而为”，不保证 100% 缓存命中
  3. 缓存构建耗时为秒级。缓存不再使用后会自动被清空，时间一般为几个小时到几天


[上一页 Function Calling](https://api-docs.deepseek.com/zh-cn/guides/function_calling)[下一页 Anthropic API](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api)
  * [例一：长文本问答](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E4%BE%8B%E4%B8%80%E9%95%BF%E6%96%87%E6%9C%AC%E9%97%AE%E7%AD%94)
  * [例二：多轮对话](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E4%BE%8B%E4%BA%8C%E5%A4%9A%E8%BD%AE%E5%AF%B9%E8%AF%9D)
  * [例三：使用 Few-shot 学习](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E4%BE%8B%E4%B8%89%E4%BD%BF%E7%94%A8-few-shot-%E5%AD%A6%E4%B9%A0)
  * [查看缓存命中情况](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E6%9F%A5%E7%9C%8B%E7%BC%93%E5%AD%98%E5%91%BD%E4%B8%AD%E6%83%85%E5%86%B5)
  * [硬盘缓存与输出随机性](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E7%A1%AC%E7%9B%98%E7%BC%93%E5%AD%98%E4%B8%8E%E8%BE%93%E5%87%BA%E9%9A%8F%E6%9C%BA%E6%80%A7)
  * [其它说明](https://api-docs.deepseek.com/zh-cn/guides/kv_cache#%E5%85%B6%E5%AE%83%E8%AF%B4%E6%98%8E)


微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
