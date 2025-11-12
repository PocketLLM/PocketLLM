# Function Calling | DeepSeek API Docs> Source: https://api-docs.deepseek.com/guides/function_calling[Skip to main content](https://api-docs.deepseek.com/guides/function_calling#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/guides/function_calling)
  * [English](https://api-docs.deepseek.com/guides/function_calling)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/function_calling)


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
  * Function Calling


On this page
# Function Calling
Function Calling allows the model to call external tools to enhance its capabilities.
* * *
## Sample Code[​](https://api-docs.deepseek.com/guides/function_calling#sample-code "Direct link to Sample Code")
Here is an example of using Function Calling to get the current weather information of the user's location, demonstrated with complete Python code.
For the specific API format of Function Calling, please refer to the [Chat Completion](https://api-docs.deepseek.com/api/create-chat-completion/) documentation.
```
from openai import OpenAI  
  
defsend_messages(messages):  
    response = client.chat.completions.create(  
        model="deepseek-chat",  
        messages=messages,  
        tools=tools  
)  
return response.choices[0].message  
  
client = OpenAI(  
    api_key="<your api key>",  
    base_url="https://api.deepseek.com",  
)  
  
tools =[  
{  
"type":"function",  
"function":{  
"name":"get_weather",  
"description":"Get weather of a location, the user should supply a location first.",  
"parameters":{  
"type":"object",  
"properties":{  
"location":{  
"type":"string",  
"description":"The city and state, e.g. San Francisco, CA",  
}  
},  
"required":["location"]  
},  
}  
},  
]  
  
messages =[{"role":"user","content":"How's the weather in Hangzhou, Zhejiang?"}]  
message = send_messages(messages)  
print(f"User>\t {messages[0]['content']}")  
  
tool = message.tool_calls[0]  
messages.append(message)  
  
messages.append({"role":"tool","tool_call_id": tool.id,"content":"24℃"})  
message = send_messages(messages)  
print(f"Model>\t {message.content}")  

```

The execution flow of this example is as follows:
  1. User: Asks about the current weather in Hangzhou
  2. Model: Returns the function `get_weather({location: 'Hangzhou'})`
  3. User: Calls the function `get_weather({location: 'Hangzhou'})` and provides the result to the model
  4. Model: Returns in natural language, "The current temperature in Hangzhou is 24°C."


Note: In the above code, the functionality of the `get_weather` function needs to be provided by the user. The model itself does not execute specific functions.
* * *
##  `strict` Mode (Beta)[​](https://api-docs.deepseek.com/guides/function_calling#strict-mode-beta "Direct link to strict-mode-beta")
In `strict` mode, the model strictly adheres to the format requirements of the Function's JSON schema when outputting a Function call, ensuring that the model's output complies with the user's definition.
To use `strict` mode, you need to:：
  1. Use `base_url="https://api.deepseek.com/beta"` to enable Beta features
  2. In the `tools` parameter，all `function` need to set the `strict` property to `true`
  3. The server will validate the JSON Schema of the Function provided by the user. If the schema does not conform to the specifications or contains JSON schema types that are not supported by the server, an error message will be returned


The following is an example of a tool definition in the `strict` mode:
```
{  
    "type": "function",  
    "function": {  
        "name": "get_weather",  
        "strict": true,  
        "description": "Get weather of a location, the user should supply a location first.",  
        "parameters": {  
            "type": "object",  
            "properties": {  
                "location": {  
                    "type": "string",  
                    "description": "The city and state, e.g. San Francisco, CA",  
                }  
            },  
            "required": ["location"],  
            "additionalProperties": false  
        }  
    }  
}  

```

* * *
### Support Json Schema Types In `strict` Mode[​](https://api-docs.deepseek.com/guides/function_calling#support-json-schema-types-in-strict-mode "Direct link to support-json-schema-types-in-strict-mode")
  * object
  * string
  * number
  * integer
  * boolean
  * array
  * enum
  * anyOf


* * *
#### object[​](https://api-docs.deepseek.com/guides/function_calling#object "Direct link to object")
The `object` defines a nested structure containing key-value pairs, where `properties` specifies the schema for each key (or property) within the object. **All properties of every`object` must be set as `required`, and the `additionalProperties` attribute of the `object` must be set to `false`.**
Example：
```
{  
    "type": "object",  
    "properties": {  
        "name": { "type": "string" },  
        "age": { "type": "integer" }  
    },  
    "required": ["name", "age"],  
    "additionalProperties": false  
}  

```

* * *
#### string[​](https://api-docs.deepseek.com/guides/function_calling#string "Direct link to string")
  * Supported parameters:
    * `pattern`: Uses regular expressions to constrain the format of the string
    * `format`: Validates the string against predefined common formats. Currently supported formats:
      * `email`: Email address
      * `hostname`: Hostname
      * `ipv4`: IPv4 address
      * `ipv6`: IPv6 address
      * `uuid`: UUID
  * Unsupported parameters:
    * `minLength`
    * `maxLength`


Example:
```
{  
    "type": "object",  
    "properties": {  
        "user_email": {  
            "type": "string",  
            "description": "The user's email address",  
            "format": "email"   
        },  
        "zip_code": {  
            "type": "string",  
            "description": "Six digit postal code",  
            "pattern": "^\\d{6}$"  
        }  
    }  
}  

```

* * *
#### number/integer[​](https://api-docs.deepseek.com/guides/function_calling#numberinteger "Direct link to number/integer")
  * Supported parameters:
    * `const`: Specifies a constant numeric value
    * `default`: Defines the default value of the number
    * `minimum`: Specifies the minimum value
    * `maximum`: Specifies the maximum value
    * `exclusiveMinimum`: Defines a value that the number must be greater than
    * `exclusiveMaximum`: Defines a value that the number must be less than
    * `multipleOf`: Ensures that the number is a multiple of the specified value


Example:
```
{  
    "type": "object",  
    "properties": {  
        "score": {  
            "type": "integer",  
            "description": "A number from 1-5, which represents your rating, the higher, the better",  
            "minimum": 1,  
            "maximum": 5  
        }  
    },  
    "required": ["score"],  
    "additionalProperties": false  
}  

```

* * *
#### array[​](https://api-docs.deepseek.com/guides/function_calling#array "Direct link to array")
  * Unsupported parameters:
    * minItems
    * maxItems


Example：
```
{  
    "type": "object",  
    "properties": {  
        "keywords": {  
            "type": "array",  
            "description": "Five keywords of the article, sorted by importance",  
            "items": {  
                "type": "string",  
                "description": "A concise and accurate keyword or phrase."  
            }  
        }  
    },  
    "required": ["keywords"],  
    "additionalProperties": false  
}  

```

* * *
#### enum[​](https://api-docs.deepseek.com/guides/function_calling#enum "Direct link to enum")
The `enum` ensures that the output is one of the predefined options. For example, in the case of order status, it can only be one of a limited set of specified states.
Example：
```
{  
    "type": "object",  
    "properties": {  
        "order_status": {  
            "type": "string",  
            "description": "Ordering status",  
            "enum": ["pending", "processing", "shipped", "cancelled"]  
        }  
    }  
}  

```

* * *
#### anyOf[​](https://api-docs.deepseek.com/guides/function_calling#anyof "Direct link to anyOf")
Matches any one of the provided schemas, allowing fields to accommodate multiple valid formats. For example, a user's account could be either an email address or a phone number:
```
{  
    "type": "object",  
    "properties": {  
    "account": {  
        "anyOf": [  
            { "type": "string", "format": "email", "description": "可以是电子邮件地址" },  
            { "type": "string", "pattern": "^\\d{11}$", "description": "或11位手机号码" }  
        ]  
    }  
  }  
}  

```

* * *
#### $ref and $def[​](https://api-docs.deepseek.com/guides/function_calling#ref-and-def "Direct link to $ref and $def")
You can use `$def` to define reusable modules and then use `$ref` to reference them, reducing schema repetition and enabling modularization. Additionally, `$ref` can be used independently to define recursive structures.
```
{  
    "type": "object",  
    "properties": {  
        "report_date": {  
            "type": "string",  
            "description": "The date when the report was published"  
        },  
        "authors": {  
            "type": "array",  
            "description": "The authors of the report",  
            "items": {  
                "$ref": "#/$def/author"  
            }  
        }  
    },  
    "required": ["report_date", "authors"],  
    "additionalProperties": false,  
    "$def": {  
        "authors": {  
            "type": "object",  
            "properties": {  
                "name": {  
                    "type": "string",  
                    "description": "author's name"  
                },  
                "institution": {  
                    "type": "string",  
                    "description": "author's institution"  
                },  
                "email": {  
                    "type": "string",  
                    "format": "email",  
                    "description": "author's email"  
                }  
            },  
            "additionalProperties": false,  
            "required": ["name", "institution", "email"]  
        }  
    }  
}  

```

[Previous JSON Output](https://api-docs.deepseek.com/guides/json_mode)[Next Context Caching](https://api-docs.deepseek.com/guides/kv_cache)
  * [Sample Code](https://api-docs.deepseek.com/guides/function_calling#sample-code)
  * [`strict` Mode (Beta)](https://api-docs.deepseek.com/guides/function_calling#strict-mode-beta)
    * [Support Json Schema Types In `strict` Mode](https://api-docs.deepseek.com/guides/function_calling#support-json-schema-types-in-strict-mode)


WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
