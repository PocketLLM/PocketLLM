# 对话前缀续写（Beta） | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion[跳到主要内容](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion)
  * [English](https://api-docs.deepseek.com/guides/chat_prefix_completion)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion)


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
  * 对话前缀续写（Beta）


本页总览
# 对话前缀续写（Beta）
对话前缀续写沿用 [Chat Completion API](https://api-docs.deepseek.com/zh-cn/api/create-chat-completion)，用户提供 assistant 开头的消息，来让模型补全其余的消息。
## 注意事项[​](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion#%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9 "注意事项的直接链接")
  1. 使用对话前缀续写时，用户需确保 `messages` 列表里最后一条消息的 `role` 为 `assistant`，并设置最后一条消息的 `prefix` 参数为 `True`。
  2. 用户需要设置 `base_url="https://api.deepseek.com/beta"` 来开启 Beta 功能。


## 样例代码[​](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion#%E6%A0%B7%E4%BE%8B%E4%BB%A3%E7%A0%81 "样例代码的直接链接")
下面给出了对话前缀续写的完整 Python 代码样例。在这个例子中，我们设置 `assistant` 开头的消息为 `"```python\n"` 来强制模型输出 python 代码，并设置 `stop` 参数为 `['```']` 来避免模型的额外解释。
```
from openai import OpenAI  
  
client = OpenAI(  
    api_key="<your api key>",  
    base_url="https://api.deepseek.com/beta",  
)  
  
messages =[  
{"role":"user","content":"Please write quick sort code"},  
{"role":"assistant","content":"```python\n","prefix":True}  
]  
response = client.chat.completions.create(  
    model="deepseek-chat",  
    messages=messages,  
    stop=["```"],  
)  
print(response.choices[0].message.content)  

```

[上一页 多轮对话](https://api-docs.deepseek.com/zh-cn/guides/multi_round_chat)[下一页 FIM 补全（Beta）](https://api-docs.deepseek.com/zh-cn/guides/fim_completion)
  * [注意事项](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion#%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9)
  * [样例代码](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion#%E6%A0%B7%E4%BE%8B%E4%BB%A3%E7%A0%81)


微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
