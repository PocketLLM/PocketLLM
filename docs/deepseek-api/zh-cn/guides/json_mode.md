# JSON Output | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/guides/json_mode[跳到主要内容](https://api-docs.deepseek.com/zh-cn/guides/json_mode#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/guides/json_mode)
  * [English](https://api-docs.deepseek.com/guides/json_mode)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/json_mode)


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
  * JSON Output


本页总览
# JSON Output
在很多场景下，用户需要让模型严格按照 JSON 格式来输出，以实现输出的结构化，便于后续逻辑进行解析。
DeepSeek 提供了 JSON Output 功能，来确保模型输出合法的 JSON 字符串。
## 注意事项[​](https://api-docs.deepseek.com/zh-cn/guides/json_mode#%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9 "注意事项的直接链接")
  1. 设置 `response_format` 参数为 `{'type': 'json_object'}`。
  2. 用户传入的 system 或 user prompt 中必须含有 `json` 字样，并给出希望模型输出的 JSON 格式的样例，以指导模型来输出合法 JSON。
  3. 需要合理设置 `max_tokens` 参数，防止 JSON 字符串被中途截断。
  4. **在使用 JSON Output 功能时，API 有概率会返回空的 content。我们正在积极优化该问题，您可以尝试修改 prompt 以缓解此类问题。**


## 样例代码[​](https://api-docs.deepseek.com/zh-cn/guides/json_mode#%E6%A0%B7%E4%BE%8B%E4%BB%A3%E7%A0%81 "样例代码的直接链接")
这里展示了使用 JSON Output 功能的完整 Python 代码：
```
import json  
from openai import OpenAI  
  
client = OpenAI(  
    api_key="<your api key>",  
    base_url="https://api.deepseek.com",  
)  
  
system_prompt ="""  
The user will provide some exam text. Please parse the "question" and "answer" and output them in JSON format.   
  
EXAMPLE INPUT:   
Which is the highest mountain in the world? Mount Everest.  
  
EXAMPLE JSON OUTPUT:  
{  
    "question": "Which is the highest mountain in the world?",  
    "answer": "Mount Everest"  
}  
"""  
  
user_prompt ="Which is the longest river in the world? The Nile River."  
  
messages =[{"role":"system","content": system_prompt},  
{"role":"user","content": user_prompt}]  
  
response = client.chat.completions.create(  
    model="deepseek-chat",  
    messages=messages,  
    response_format={  
'type':'json_object'  
}  
)  
  
print(json.loads(response.choices[0].message.content))  

```

模型将会输出：
```
{  
    "question": "Which is the longest river in the world?",  
    "answer": "The Nile River"  
}  

```

[上一页 FIM 补全（Beta）](https://api-docs.deepseek.com/zh-cn/guides/fim_completion)[下一页 Function Calling](https://api-docs.deepseek.com/zh-cn/guides/function_calling)
  * [注意事项](https://api-docs.deepseek.com/zh-cn/guides/json_mode#%E6%B3%A8%E6%84%8F%E4%BA%8B%E9%A1%B9)
  * [样例代码](https://api-docs.deepseek.com/zh-cn/guides/json_mode#%E6%A0%B7%E4%BE%8B%E4%BB%A3%E7%A0%81)


微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
