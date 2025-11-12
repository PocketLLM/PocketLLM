# 首次调用 API | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/[跳到主要内容](https://api-docs.deepseek.com/zh-cn/#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/)
  * [English](https://api-docs.deepseek.com/)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/)


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
  * 快速开始
  * 首次调用 API


本页总览
# 首次调用 API
DeepSeek API 使用与 OpenAI 兼容的 API 格式，通过修改配置，您可以使用 OpenAI SDK 来访问 DeepSeek API，或使用与 OpenAI API 兼容的软件。
PARAM | VALUE  
---|---  
base_url * | `https://api.deepseek.com`  
api_key | apply for an [API key](https://platform.deepseek.com/api_keys)  
* 出于与 OpenAI 兼容考虑，您也可以将 `base_url` 设置为 `https://api.deepseek.com/v1` 来使用，但注意，此处 `v1` 与模型版本无关。
* **`deepseek-chat`和`deepseek-reasoner` 都已经升级为 DeepSeek-V3.2-Exp。**`deepseek-chat` 对应 DeepSeek-V3.2-Exp 的**非思考模式** ，`deepseek-reasoner` 对应 DeepSeek-V3.2-Exp 的**思考模式** 。
## 调用对话 API[​](https://api-docs.deepseek.com/zh-cn/#%E8%B0%83%E7%94%A8%E5%AF%B9%E8%AF%9D-api "调用对话 API的直接链接")
在创建 API key 之后，你可以使用以下样例脚本的来访问 DeepSeek API。样例为非流式输出，您可以将 stream 设置为 true 来使用流式输出。
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
  
client = OpenAI(  
    api_key=os.environ.get('DEEPSEEK_API_KEY'),  
    base_url="https://api.deepseek.com")  
  
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

[下一页 模型 & 价格](https://api-docs.deepseek.com/zh-cn/quick_start/pricing)
  * [调用对话 API](https://api-docs.deepseek.com/zh-cn/#%E8%B0%83%E7%94%A8%E5%AF%B9%E8%AF%9D-api)


微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
