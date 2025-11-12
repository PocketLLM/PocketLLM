# JSON Output | DeepSeek API Docs> Source: https://api-docs.deepseek.com/guides/json_mode[Skip to main content](https://api-docs.deepseek.com/guides/json_mode#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/guides/json_mode)
  * [English](https://api-docs.deepseek.com/guides/json_mode)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/json_mode)


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
  * JSON Output


On this page
# JSON Output
In many scenarios, users need the model to output in strict JSON format to achieve structured output, facilitating subsequent parsing.
DeepSeek provides JSON Output to ensure the model outputs valid JSON strings.
## Notice[​](https://api-docs.deepseek.com/guides/json_mode#notice "Direct link to Notice")
To enable JSON Output, users should:
  1. Set the `response_format` parameter to `{'type': 'json_object'}`.
  2. Include the word "json" in the system or user prompt, and provide an example of the desired JSON format to guide the model in outputting valid JSON.
  3. Set the `max_tokens` parameter reasonably to prevent the JSON string from being truncated midway.
  4. **When using the JSON Output feature, the API may occasionally return empty content. We are actively working on optimizing this issue. You can try modifying the prompt to mitigate such problems.**


## Sample Code[​](https://api-docs.deepseek.com/guides/json_mode#sample-code "Direct link to Sample Code")
Here is the complete Python code demonstrating the use of JSON Output:
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

The model will output:
```
{  
    "question": "Which is the longest river in the world?",  
    "answer": "The Nile River"  
}  

```

[Previous FIM Completion (Beta)](https://api-docs.deepseek.com/guides/fim_completion)[Next Function Calling](https://api-docs.deepseek.com/guides/function_calling)
  * [Notice](https://api-docs.deepseek.com/guides/json_mode#notice)
  * [Sample Code](https://api-docs.deepseek.com/guides/json_mode#sample-code)


WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
