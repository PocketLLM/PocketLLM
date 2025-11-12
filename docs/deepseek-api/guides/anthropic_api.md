# Anthropic API | DeepSeek API Docs> Source: https://api-docs.deepseek.com/guides/anthropic_api[Skip to main content](https://api-docs.deepseek.com/guides/anthropic_api#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/guides/anthropic_api)
  * [English](https://api-docs.deepseek.com/guides/anthropic_api)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api)


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
  * Anthropic API


On this page
# Anthropic API
To meet the demand for using the Anthropic API ecosystem, our API has added support for the Anthropic API format. With simple configuration, you can integrate the capabilities of DeepSeek into the Anthropic API ecosystem.
## Use DeepSeek in Claude Code[​](https://api-docs.deepseek.com/guides/anthropic_api#use-deepseek-in-claude-code "Direct link to Use DeepSeek in Claude Code")
  1. Install Claude Code


```
npm install -g @anthropic-ai/claude-code  

```

  1. Config Environment Variables


```
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic  
export ANTHROPIC_AUTH_TOKEN=${YOUR_API_KEY}  
export API_TIMEOUT_MS=600000  
export ANTHROPIC_MODEL=deepseek-chat  
export ANTHROPIC_SMALL_FAST_MODEL=deepseek-chat  
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1  

```

Note: The `API_TIMEOUT_MS` parameter is configured to prevent excessively long outputs that could cause the Claude Code client to time out. Here, we set the timeout duration to 10 minutes.
  1. Enter the Project Directory, and Execute Claude Code


```
cd my-project  
claude  

```

![](https://cdn.deepseek.com/api-docs/cc_example.png)
## Invoke DeepSeek Model via Anthropic API[​](https://api-docs.deepseek.com/guides/anthropic_api#invoke-deepseek-model-via-anthropic-api "Direct link to Invoke DeepSeek Model via Anthropic API")
  1. Install Anthropic SDK


```
pip install anthropic  

```

  1. Config Environment Variables


```
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic  
export ANTHROPIC_API_KEY=${DEEPSEEK_API_KEY}  

```

  1. Invoke the API


```
import anthropic  
  
client = anthropic.Anthropic()  
  
message = client.messages.create(  
    model="deepseek-chat",  
    max_tokens=1000,  
    system="You are a helpful assistant.",  
    messages=[  
        {  
            "role": "user",  
            "content": [  
                {  
                    "type": "text",  
                    "text": "Hi, how are you?"  
                }  
            ]  
        }  
    ]  
)  
print(message.content)  

```

**Note:** When you pass an unsupported model name to DeepSeek's Anthropic API, the API backend will automatically map it to the `deepseek-chat` model.
## Anthropic API Compatibility Details[​](https://api-docs.deepseek.com/guides/anthropic_api#anthropic-api-compatibility-details "Direct link to Anthropic API Compatibility Details")
### HTTP Header[​](https://api-docs.deepseek.com/guides/anthropic_api#http-header "Direct link to HTTP Header")
Field | Support Status  
---|---  
anthropic-beta | Ignored  
anthropic-version | Ignored  
x-api-key | Fully Supported  
### Simple Fields[​](https://api-docs.deepseek.com/guides/anthropic_api#simple-fields "Direct link to Simple Fields")
Field | Support Status  
---|---  
model | Use DeepSeek Model Instead  
max_tokens | Fully Supported  
container | Ignored  
mcp_servers | Ignored  
metadata | Ignored  
service_tier | Ignored  
stop_sequences | Fully Supported  
stream | Fully Supported  
system | Fully Supported  
temperature | Fully Supported (range [0.0 ~ 2.0])  
thinking | Ignored  
top_k | Ignored  
top_p | Fully Supported  
### Tool Fields[​](https://api-docs.deepseek.com/guides/anthropic_api#tool-fields "Direct link to Tool Fields")
#### tools[​](https://api-docs.deepseek.com/guides/anthropic_api#tools "Direct link to tools")
Field | Support Status  
---|---  
name | Fully Supported  
input_schema | Fully Supported  
description | Fully Supported  
cache_control | Ignored  
#### tool_choice[​](https://api-docs.deepseek.com/guides/anthropic_api#tool_choice "Direct link to tool_choice")
Value | Support Status  
---|---  
none | Fully Supported  
auto | Supported (`disable_parallel_tool_use` is ignored)  
any | Supported (`disable_parallel_tool_use` is ignored)  
tool | Supported (`disable_parallel_tool_use` is ignored)  
### Message Fields[​](https://api-docs.deepseek.com/guides/anthropic_api#message-fields "Direct link to Message Fields")
Field | Variant | Sub-Field | Support Status  
---|---|---|---  
content  |  string  |  | Fully Supported  
array, type="text" |  text  |  Fully Supported   
cache_control  |  Ignored   
citations  |  Ignored   
array, type="image"  |  |  Not Supported   
array, type = "document"  |  |  Not Supported   
array, type = "search_result"  |  |  Not Supported   
array, type = "thinking"  |  |  Ignored   
array, type="redacted_thinking"  |  |  Not Supported   
array, type = "tool_use"  |  id  |  Fully Supported   
input  |  Fully Supported   
name  |  Fully Supported   
cache_control  |  Ignored   
array, type = "tool_result"  |  tool_use_id  |  Fully Supported   
content  |  Fully Supported   
cache_control  |  Ignored   
is_error  |  Ignored   
array, type = "server_tool_use"  |  |  Not Supported   
array, type = "web_search_tool_result"  |  |  Not Supported   
array, type = "code_execution_tool_result"  |  |  Not Supported   
array, type = "mcp_tool_use"  |  |  Not Supported   
array, type = "mcp_tool_result"  |  |  Not Supported   
array, type = "container_upload"  |  |  Not Supported   
[Previous Context Caching](https://api-docs.deepseek.com/guides/kv_cache)[Next FAQ](https://api-docs.deepseek.com/faq)
  * [Use DeepSeek in Claude Code](https://api-docs.deepseek.com/guides/anthropic_api#use-deepseek-in-claude-code)
  * [Invoke DeepSeek Model via Anthropic API](https://api-docs.deepseek.com/guides/anthropic_api#invoke-deepseek-model-via-anthropic-api)
  * [Anthropic API Compatibility Details](https://api-docs.deepseek.com/guides/anthropic_api#anthropic-api-compatibility-details)
    * [HTTP Header](https://api-docs.deepseek.com/guides/anthropic_api#http-header)
    * [Simple Fields](https://api-docs.deepseek.com/guides/anthropic_api#simple-fields)
    * [Tool Fields](https://api-docs.deepseek.com/guides/anthropic_api#tool-fields)
    * [Message Fields](https://api-docs.deepseek.com/guides/anthropic_api#message-fields)


WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
