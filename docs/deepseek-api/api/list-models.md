# Lists Models | DeepSeek API Docs> Source: https://api-docs.deepseek.com/api/list-models[Skip to main content](https://api-docs.deepseek.com/api/list-models#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/api/list-models)
  * [English](https://api-docs.deepseek.com/api/list-models)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/api/list-models)


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
    * [Models](https://api-docs.deepseek.com/api/list-models)
      * [Lists Models](https://api-docs.deepseek.com/api/list-models)
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
  * Models
  * Lists Models


# Lists Models
```
GET 
## /models

```

Lists the currently available models, and provides basic information about each one such as the owner and availability. Check [Models & Pricing](https://api-docs.deepseek.com/quick_start/pricing) for our currently supported models.
## Responses[​](https://api-docs.deepseek.com/api/list-models#responses "Direct link to Responses")
  * 200


OK, returns A list of models
  * application/json


  * Schema
  * Example (from schema)
  * Example


**
Schema
**
**object** stringrequired
**Possible values:** [`list`]
**
data
**
Model[]
required
  * Array [
**id** stringrequired
The model identifier, which can be referenced in the API endpoints.
**object** stringrequired
**Possible values:** [`model`]
The object type, which is always "model".
**owned_by** stringrequired
The organization that owns the model.
  * ]


```
{  
  "object": "list",  
  "data": [  
    {  
      "id": "string",  
      "object": "model",  
      "owned_by": "string"  
    }  
  ]  
}  

```

```
{  
  "object": "list",  
  "data": [  
    {  
      "id": "deepseek-chat",  
      "object": "model",  
      "owned_by": "deepseek"  
    },  
    {  
      "id": "deepseek-reasoner",  
      "object": "model",  
      "owned_by": "deepseek"  
    }  
  ]  
}  

```

Loading...
[Previous Create FIM Completion (Beta)](https://api-docs.deepseek.com/api/create-completion)[Next Get User Balance](https://api-docs.deepseek.com/api/get-user-balance)
WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
Lists Models
GET
https://api.deepseek.com/models
Lists the currently available models, and provides basic information about each one such as the owner and availability. Check Models & Pricing for our currently supported models.

Responses
200
OK, returns A list of models

application/json
Schema
Example (from schema)
Example
Schema

object
string
required
Possible values: [list]

data

Model[]

required

curl
python
go
nodejs
ruby
csharp
php
java
powershell
OpenAI SDK
from openai import OpenAI

# for backward compatibility, you can still use `https://api.deepseek.com/v1` as `base_url`.
client = OpenAI(api_key="<your API key>", base_url="https://api.deepseek.com")
print(client.models.list())


REQUESTS
HTTP.CLIENT
import requests

url = "https://api.deepseek.com/models"

payload={}
headers = {
  'Accept': 'application/json',
  'Authorization': 'Bearer <TOKEN>'
}

response = requests.request("GET", url, headers=headers, data=payload)

print(response.text)


Request
Collapse all
Base URL
https://api.deepseek.com
Auth
Bearer Token
Bearer Token
Send API Request
Response
Clear
Click the Send API Request button above and see the response here!