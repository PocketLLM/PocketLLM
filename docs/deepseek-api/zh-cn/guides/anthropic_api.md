# Anthropic API | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/guides/anthropic_api[跳到主要内容](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api)
  * [English](https://api-docs.deepseek.com/guides/anthropic_api)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api)


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
  * Anthropic API


本页总览
# Anthropic API
为了满足大家对 Anthropic API 生态的使用需求，我们的 API 新增了对 Anthropic API 格式的支持。通过简单的配置，即可将 DeepSeek 的能力，接入到 Anthropic API 生态中。
* * *
## 将 DeepSeek 模型接入 Claude Code[​](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#%E5%B0%86-deepseek-%E6%A8%A1%E5%9E%8B%E6%8E%A5%E5%85%A5-claude-code "将 DeepSeek 模型接入 Claude Code的直接链接")
  1. 安装 Claude Code


```
npm install -g @anthropic-ai/claude-code  

```

  1. 配置环境变量


```
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic  
export ANTHROPIC_AUTH_TOKEN=${DEEPSEEK_API_KEY}  
export API_TIMEOUT_MS=600000  
export ANTHROPIC_MODEL=deepseek-chat  
export ANTHROPIC_SMALL_FAST_MODEL=deepseek-chat  
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1  

```

注：设置`API_TIMEOUT_MS`是为了防止输出过长，触发 Claude Code 客户端超时，这里设置的超时时间为 10 分钟。
  1. 进入项目目录，执行 `claude` 命令，即可开始使用了。


```
cd my-project  
claude  

```

![](https://cdn.deepseek.com/api-docs/cc_example.png)
* * *
## 通过 Anthropic API 调用 DeepSeek 模型[​](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#%E9%80%9A%E8%BF%87-anthropic-api-%E8%B0%83%E7%94%A8-deepseek-%E6%A8%A1%E5%9E%8B "通过 Anthropic API 调用 DeepSeek 模型的直接链接")
  1. 安装 Anthropic SDK


```
pip install anthropic  

```

  1. 配置环境变量


```
export ANTHROPIC_BASE_URL=https://api.deepseek.com/anthropic  
export ANTHROPIC_API_KEY=${YOUR_API_KEY}  

```

  1. 调用 API


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

**注意** ：当您给 DeepSeek 的 Anthropic API 传入不支持的模型名时，API 后端会自动将其映射到 `deepseek-chat` 模型。
* * *
## Anthropic API 兼容性细节[​](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#anthropic-api-%E5%85%BC%E5%AE%B9%E6%80%A7%E7%BB%86%E8%8A%82 "Anthropic API 兼��容性细节的直接链接")
### HTTP Header[​](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#http-header "HTTP Header的直接链接")
Field | Support Status  
---|---  
anthropic-beta | Ignored  
anthropic-version | Ignored  
x-api-key | Fully Supported  
### Simple Fields[​](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#simple-fields "Simple Fields的直接链接")
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
### Tool Fields[​](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#tool-fields "Tool Fields的直接链接")
#### tools[​](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#tools "tools的直接链接")
Field | Support Status  
---|---  
name | Fully Supported  
input_schema | Fully Supported  
description | Fully Supported  
cache_control | Ignored  
#### tool_choice[​](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#tool_choice "tool_choice的直接链接")
Value | Support Status  
---|---  
none | Fully Supported  
auto | Supported (`disable_parallel_tool_use` is ignored)  
any | Supported (`disable_parallel_tool_use` is ignored)  
tool | Supported (`disable_parallel_tool_use` is ignored)  
### Message Fields[​](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#message-fields "Message Fields的直接链接")
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
[上一页 上下文硬盘缓存](https://api-docs.deepseek.com/zh-cn/guides/kv_cache)[下一页 常见问题](https://api-docs.deepseek.com/zh-cn/faq)
  * [将 DeepSeek 模型接入 Claude Code](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#%E5%B0%86-deepseek-%E6%A8%A1%E5%9E%8B%E6%8E%A5%E5%85%A5-claude-code)
  * [通过 Anthropic API 调用 DeepSeek 模型](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#%E9%80%9A%E8%BF%87-anthropic-api-%E8%B0%83%E7%94%A8-deepseek-%E6%A8%A1%E5%9E%8B)
  * [Anthropic API 兼容性细节](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#anthropic-api-%E5%85%BC%E5%AE%B9%E6%80%A7%E7%BB%86%E8%8A%82)
    * [HTTP Header](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#http-header)
    * [Simple Fields](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#simple-fields)
    * [Tool Fields](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#tool-fields)
    * [Message Fields](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api#message-fields)


微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
