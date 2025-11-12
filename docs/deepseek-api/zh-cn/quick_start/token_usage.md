# Token 用量计算 | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/quick_start/token_usage[跳到主要内容](https://api-docs.deepseek.com/zh-cn/quick_start/token_usage#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/quick_start/token_usage)
  * [English](https://api-docs.deepseek.com/quick_start/token_usage)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/quick_start/token_usage)


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
  * Token 用量计算


本页总览
# Token 用量计算
token 是模型用来表示自然语言文本的基本单位，也是我们的计费单元，可以直观的理解为“字”或“词”；通常 1 个中文词语、1 个英文单词、1 个数字或 1 个符号计为 1 个 token。
一般情况下模型中 token 和字数的换算比例大致如下：
  * 1 个英文字符 ≈ 0.3 个 token。
  * 1 个中文字符 ≈ 0.6 个 token。


但因为不同模型的分词不同，所以换算比例也存在差异，每一次实际处理 token 数量以模型返回为准，您可以从返回结果的 `usage` 中查看。
## 离线计算 Tokens 用量[​](https://api-docs.deepseek.com/zh-cn/quick_start/token_usage#%E7%A6%BB%E7%BA%BF%E8%AE%A1%E7%AE%97-tokens-%E7%94%A8%E9%87%8F "离线计算 Tokens 用量的直接链接")
您可以通过如下压缩包中的代码来运行 tokenizer，以离线计算一段文本的 Token 用量。
[deepseek_tokenizer.zip](https://cdn.deepseek.com/api-docs/deepseek_v3_tokenizer.zip)
[上一页 Temperature 设置](https://api-docs.deepseek.com/zh-cn/quick_start/parameter_settings)[下一页 限速](https://api-docs.deepseek.com/zh-cn/quick_start/rate_limit)
  * [离线计算 Tokens 用量](https://api-docs.deepseek.com/zh-cn/quick_start/token_usage#%E7%A6%BB%E7%BA%BF%E8%AE%A1%E7%AE%97-tokens-%E7%94%A8%E9%87%8F)


微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
