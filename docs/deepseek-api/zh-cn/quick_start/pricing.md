# 模型 & 价格 | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/quick_start/pricing[跳到主要内容](https://api-docs.deepseek.com/zh-cn/quick_start/pricing#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/quick_start/pricing)
  * [English](https://api-docs.deepseek.com/quick_start/pricing)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/quick_start/pricing)


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
  * 模型 & 价格


本页总览
# 模型 & 价格
下表所列模型价格以“百万 tokens”为单位。Token 是模型用来表示自然语言文本的的最小单位，可以是一个词、一个数字或一个标点符号等。我们将根据模型输入和输出的总 token 数进行计量计费。
* * *
## 模型细节[​](https://api-docs.deepseek.com/zh-cn/quick_start/pricing#%E6%A8%A1%E5%9E%8B%E7%BB%86%E8%8A%82 "模型细节的直接链接")
** 模型 | deepseek-chat | deepseek-reasoner  
---|---|---  
模型版本 | DeepSeek-V3.2-Exp  
（非思考模式） | DeepSeek-V3.2-Exp  
（思考模式）  
上下文长度 | 128K  
输出长度 | 默认 4K，最大 8K | 默认 32K，最大 64K  
功能 | [Json Output](https://api-docs.deepseek.com/zh-cn/guides/json_mode) | 支持 | 支持  
[Function Calling](https://api-docs.deepseek.com/zh-cn/guides/function_calling) | 支持 | 不支持(1)  
[对话前缀续写（Beta）](https://api-docs.deepseek.com/zh-cn/guides/chat_prefix_completion) | 支持 | 支持  
[FIM 补全（Beta）](https://api-docs.deepseek.com/zh-cn/guides/fim_completion) | 支持 | 不支持  
价格 | 百万tokens输入（缓存命中） | 0.2元  
百万tokens输入（缓存未命中） | 2元  
百万tokens输出 | 3元  
**
  * (1) 如果给 `deepseek-reasoner` 模型的请求中有 `tools` 参数，请求实际上将使用 `deepseek-chat` 模型。


* * *
## 扣费规则[​](https://api-docs.deepseek.com/zh-cn/quick_start/pricing#%E6%89%A3%E8%B4%B9%E8%A7%84%E5%88%99 "扣费规则的直接链接")
扣减费用 = token 消耗量 × 模型单价，对应的费用将直接从充值余额或赠送余额中进行扣减。 当充值余额与赠送余额同时存在时，优先扣减赠送余额。
产品价格可能发生变动，DeepSeek 保留修改价格的权利。请您依据实际用量按需充值，定期查看此页面以获知最新价格信息。
[上一页 首次调用 API](https://api-docs.deepseek.com/zh-cn/)[下一页 Temperature 设置](https://api-docs.deepseek.com/zh-cn/quick_start/parameter_settings)
  * [模型细节](https://api-docs.deepseek.com/zh-cn/quick_start/pricing#%E6%A8%A1%E5%9E%8B%E7%BB%86%E8%8A%82)
  * [扣费规则](https://api-docs.deepseek.com/zh-cn/quick_start/pricing#%E6%89%A3%E8%B4%B9%E8%A7%84%E5%88%99)


微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
