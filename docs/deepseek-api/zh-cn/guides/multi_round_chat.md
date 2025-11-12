# 多轮对话 | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/guides/multi_round_chat[跳到主要内容](https://api-docs.deepseek.com/zh-cn/guides/multi_round_chat#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/guides/multi_round_chat)
  * [English](https://api-docs.deepseek.com/guides/multi_round_chat)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/multi_round_chat)


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
  * 多轮对话


# 多轮对话
本指南将介绍如何使用 DeepSeek `/chat/completions` API 进行多轮对话。
DeepSeek `/chat/completions` API 是一个“无状态” API，即服务端不记录用户请求的上下文，用户在每次请求时，**需将之前所有对话历史拼接好后** ，传递给对话 API。
下面的代码以 Python 语言，展示了如何进行上下文拼接，以实现多轮对话。
```
from openai import OpenAI  
client = OpenAI(api_key="<DeepSeek API Key>", base_url="https://api.deepseek.com")  
  
# Round 1  
messages =[{"role":"user","content":"What's the highest mountain in the world?"}]  
response = client.chat.completions.create(  
    model="deepseek-chat",  
    messages=messages  
)  
  
messages.append(response.choices[0].message)  
print(f"Messages Round 1: {messages}")  
  
# Round 2  
messages.append({"role":"user","content":"What is the second?"})  
response = client.chat.completions.create(  
    model="deepseek-chat",  
    messages=messages  
)  
  
messages.append(response.choices[0].message)  
print(f"Messages Round 2: {messages}")  

```

* * *
在**第一轮** 请求时，传递给 API 的 `messages` 为：
```
[  
    {"role": "user", "content": "What's the highest mountain in the world?"}  
]  

```

在**第二轮** 请求时：
  1. 要将第一轮中模型的输出添加到 `messages` 末尾
  2. 将新的提问添加到 `messages` 末尾


最终传递给 API 的 `messages` 为：
```
[  
    {"role": "user", "content": "What's the highest mountain in the world?"},  
    {"role": "assistant", "content": "The highest mountain in the world is Mount Everest."},  
    {"role": "user", "content": "What is the second?"}  
]  

```

[上一页 推理模型 (deepseek-reasoner)](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model)[下一页 对话前缀续写（Beta）](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion)
微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
