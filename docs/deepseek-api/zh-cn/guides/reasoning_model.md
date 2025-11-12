# 推理模型 (deepseek-reasoner) | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/guides/reasoning_model[跳到主要内容](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model)
  * [English](https://api-docs.deepseek.com/guides/reasoning_model)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model)


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
  * 推理模型 (deepseek-reasoner)


本页总览
# 推理模型 (`deepseek-reasoner`)
`deepseek-reasoner` 是支持推理模式的 DeepSeek 模型。在输出最终回答之前，模型会先输出一段思维链内容，以提升最终答案的准确性。我们的 API 向用户开放 `deepseek-reasoner` 思维链的内容，以供用户查看、展示、蒸馏使用。
在使用 `deepseek-reasoner` 时，请先升级 OpenAI SDK 以支持新参数。
```
pip3 install -U openai  

```

## API 参数[​](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model#api-%E5%8F%82%E6%95%B0 "API 参数的直接链接")
  * **输入参数** ：
    * `max_tokens`：模型单次回答的最大长度（含思维链输出），默认为 32K，最大为 64K。
  * **输出字段** ：
    * `reasoning_content`：思维链内容，与 `content` 同级，访问方法见[访问样例](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model#%E8%AE%BF%E9%97%AE%E6%A0%B7%E4%BE%8B)。
    * `content`：最终回答内容。
  * **支持的功能** ：[Json Output](https://api-docs.deepseek.com/zh-cn/guides/json_mode)、[对话补全](https://api-docs.deepseek.com/zh-cn/api/create-chat-completion)，[对话前缀续写 (Beta)](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion)
  * **不支持的功能** ：Function Calling、FIM 补全 (Beta)
  * **不支持的参数** ：`temperature`、`top_p`、`presence_penalty`、`frequency_penalty`、`logprobs`、`top_logprobs`。请注意，为了兼容已有软件，设置 `temperature`、`top_p`、`presence_penalty`、`frequency_penalty` 参数不会报错，但也不会生效。设置 `logprobs`、`top_logprobs` 会报错。


## 上下文拼接[​](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model#%E4%B8%8A%E4%B8%8B%E6%96%87%E6%8B%BC%E6%8E%A5 "上下文拼接的直接链接")
在每一轮对话过程中，模型会输出思维链内容（`reasoning_content`）和最终回答（`content`）。在下一轮对话中，之前轮输出的思维链内容不会被拼接到上下文中，如下图所示：
![](https://cdn.deepseek.com/api-docs/deepseek_r1_multiround_example_cn.png)
请注意，如果您在输入的 messages 序列中，传入了`reasoning_content`，API 会返回 `400` 错误。因此，请删除 API 响应中的 `reasoning_content` 字段，再发起 API 请求，方法如[访问样例](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model#%E8%AE%BF%E9%97%AE%E6%A0%B7%E4%BE%8B)所示。
## 访问样例[​](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model#%E8%AE%BF%E9%97%AE%E6%A0%B7%E4%BE%8B "访问样例的直接链接")
下面的代码以 Python 语言为例，展示了如何访问思维链和最终回答，以及如何在多轮对话中进行上下文拼接。
  * 非流式
  * 流式


```
from openai import OpenAI  
client = OpenAI(api_key="<DeepSeek API Key>", base_url="https://api.deepseek.com")  
  
# Round 1  
messages =[{"role":"user","content":"9.11 and 9.8, which is greater?"}]  
response = client.chat.completions.create(  
    model="deepseek-reasoner",  
    messages=messages  
)  
  
reasoning_content = response.choices[0].message.reasoning_content  
content = response.choices[0].message.content  
  
# Round 2  
messages.append({'role':'assistant','content': content})  
messages.append({'role':'user','content':"How many Rs are there in the word 'strawberry'?"})  
response = client.chat.completions.create(  
    model="deepseek-reasoner",  
    messages=messages  
)  
# ...  

```

```
from openai import OpenAI  
client = OpenAI(api_key="<DeepSeek API Key>", base_url="https://api.deepseek.com")  
  
# Round 1  
messages =[{"role":"user","content":"9.11 and 9.8, which is greater?"}]  
response = client.chat.completions.create(  
    model="deepseek-reasoner",  
    messages=messages,  
    stream=True  
)  
  
reasoning_content =""  
content =""  
  
for chunk in response:  
if chunk.choices[0].delta.reasoning_content:  
        reasoning_content += chunk.choices[0].delta.reasoning_content  
else:  
        content += chunk.choices[0].delta.content  
  
# Round 2  
messages.append({"role":"assistant","content": content})  
messages.append({'role':'user','content':"How many Rs are there in the word 'strawberry'?"})  
response = client.chat.completions.create(  
    model="deepseek-reasoner",  
    messages=messages,  
    stream=True  
)  
# ...  

```

[上一页 查询余额](https://api-docs.deepseek.com/zh-cn/api/get-user-balance)[下一页 多轮对话](https://api-docs.deepseek.com/zh-cn/guides/multi_round_chat)
  * [API 参数](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model#api-%E5%8F%82%E6%95%B0)
  * [上下文拼接](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model#%E4%B8%8A%E4%B8%8B%E6%96%87%E6%8B%BC%E6%8E%A5)
  * [访问样例](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model#%E8%AE%BF%E9%97%AE%E6%A0%B7%E4%BE%8B)


微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
