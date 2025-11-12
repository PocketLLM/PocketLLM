# FIM Completion (Beta) | DeepSeek API Docs> Source: https://api-docs.deepseek.com/guides/fim_completion[Skip to main content](https://api-docs.deepseek.com/guides/fim_completion#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/guides/fim_completion)
  * [English](https://api-docs.deepseek.com/guides/fim_completion)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/fim_completion)


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
  * FIM Completion (Beta)


On this page
# FIM Completion (Beta)
In [FIM (Fill In the Middle) completion](https://api-docs.deepseek.com/api/create-completion), users can provide a prefix and a suffix (optional), and the model will complete the content in between. FIM is commonly used for content completion、code completion.
## Notice[​](https://api-docs.deepseek.com/guides/fim_completion#notice "Direct link to Notice")
  1. The max tokens of FIM completion is 4K.
  2. The user needs to set `base_url=https://api.deepseek.com/beta` to enable the Beta feature.


## Sample Code[​](https://api-docs.deepseek.com/guides/fim_completion#sample-code "Direct link to Sample Code")
Below is a complete Python code example for FIM completion. In this example, we provide the beginning and the end of a function to calculate the Fibonacci sequence, allowing the model to complete the content in the middle.
```
from openai import OpenAI  
  
client = OpenAI(  
    api_key="<your api key>",  
    base_url="https://api.deepseek.com/beta",  
)  
  
response = client.completions.create(  
    model="deepseek-chat",  
    prompt="def fib(a):",  
    suffix="    return fib(a-1) + fib(a-2)",  
    max_tokens=128  
)  
print(response.choices[0].text)  

```

## Integration With Continue[​](https://api-docs.deepseek.com/guides/fim_completion#integration-with-continue "Direct link to Integration With Continue")
[Continue](https://continue.dev) is a VSCode plugin that supports code completion. You can refer to [this document](https://github.com/deepseek-ai/awesome-deepseek-integration/blob/main/docs/continue/README_cn.md) to configure Continue for using the code completion feature.
[Previous Chat Prefix Completion (Beta)](https://api-docs.deepseek.com/guides/chat_prefix_completion)[Next JSON Output](https://api-docs.deepseek.com/guides/json_mode)
  * [Notice](https://api-docs.deepseek.com/guides/fim_completion#notice)
  * [Sample Code](https://api-docs.deepseek.com/guides/fim_completion#sample-code)
  * [Integration With Continue](https://api-docs.deepseek.com/guides/fim_completion#integration-with-continue)


WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
