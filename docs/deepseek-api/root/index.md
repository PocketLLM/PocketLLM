# Your First API Call | DeepSeek API Docs> Source: https://api-docs.deepseek.com[Skip to main content](https://api-docs.deepseek.com/#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/)
  * [English](https://api-docs.deepseek.com/)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/)


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
  * Quick Start
  * Your First API Call


On this page
# Your First API Call
The DeepSeek API uses an API format compatible with OpenAI. By modifying the configuration, you can use the OpenAI SDK or softwares compatible with the OpenAI API to access the DeepSeek API.
PARAM | VALUE  
---|---  
base_url * | `https://api.deepseek.com`  
api_key | apply for an [API key](https://platform.deepseek.com/api_keys)  
* To be compatible with OpenAI, you can also use `https://api.deepseek.com/v1` as the `base_url`. But note that the `v1` here has NO relationship with the model's version.
* **`deepseek-chat`and`deepseek-reasoner` are upgraded to DeepSeek-V3.2-Exp now.** `deepseek-chat` is the **non-thinking mode** of DeepSeek-V3.2-Exp and `deepseek-reasoner` is the **thinking mode** of DeepSeek-V3.2-Exp.
## Invoke The Chat API[​](https://api-docs.deepseek.com/#invoke-the-chat-api "Direct link to Invoke The Chat API")
Once you have obtained an API key, you can access the DeepSeek API using the following example scripts. This is a non-stream example, you can set the `stream` parameter to `true` to get stream response.
  * curl
  * python
  * nodejs


```
curl https://api.deepseek.com/chat/completions \  
  -H "Content-Type: application/json" \  
  -H "Authorization: Bearer ${DEEPSEEK_API_KEY}" \  
  -d '{  
        "model": "deepseek-chat",  
        "messages": [  
          {"role": "system", "content": "You are a helpful assistant."},  
          {"role": "user", "content": "Hello!"}  
        ],  
        "stream": false  
      }'  

```

```
# Please install OpenAI SDK first: `pip3 install openai`  
import os  
from openai import OpenAI  
  
client = OpenAI(api_key=os.environ.get('DEEPSEEK_API_KEY'), base_url="https://api.deepseek.com")  
  
response = client.chat.completions.create(  
    model="deepseek-chat",  
    messages=[  
{"role":"system","content":"You are a helpful assistant"},  
{"role":"user","content":"Hello"},  
],  
    stream=False  
)  
  
print(response.choices[0].message.content)  

```

```
// Please install OpenAI SDK first: `npm install openai`  
  
importOpenAIfrom"openai";  
  
const openai =newOpenAI({  
baseURL:'https://api.deepseek.com',  
apiKey: process.env.DEEPSEEK_API_KEY,  
});  
  
asyncfunctionmain(){  
const completion =await openai.chat.completions.create({  
messages:[{role:"system",content:"You are a helpful assistant."}],  
model:"deepseek-chat",  
});  
  
console.log(completion.choices[0].message.content);  
}  
  
main();  

```

[Next Models & Pricing](https://api-docs.deepseek.com/quick_start/pricing)
  * [Invoke The Chat API](https://api-docs.deepseek.com/#invoke-the-chat-api)


WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
