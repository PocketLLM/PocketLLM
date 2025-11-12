# 查询余额 | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/api/get-user-balance[跳到主要内容](https://api-docs.deepseek.com/zh-cn/api/get-user-balance#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/api/get-user-balance)
  * [English](https://api-docs.deepseek.com/api/get-user-balance)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/api/get-user-balance)


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
    * [基本信息](https://api-docs.deepseek.com/zh-cn/api/deepseek-api)
    * [对话（Chat）](https://api-docs.deepseek.com/zh-cn/api/create-chat-completion)
    * [补全（Completions）](https://api-docs.deepseek.com/zh-cn/api/create-completion)
    * [模型（Model）](https://api-docs.deepseek.com/zh-cn/api/list-models)
    * [其它](https://api-docs.deepseek.com/zh-cn/api/get-user-balance)
      * [查询余额](https://api-docs.deepseek.com/zh-cn/api/get-user-balance)
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
  * API 文档
  * 其它
  * 查询余额


# 查询余额
```
GET 
## /user/balance

```

查询账号余额
## Responses[​](https://api-docs.deepseek.com/zh-cn/api/get-user-balance#responses "Responses的直接链接")
  * 200


OK, 返回用户余额详情
  * application/json


  * Schema
  * Example (from schema)
  * Example


**
Schema
**
**is_available** boolean
当前账户是否有余额可供 API 调用
**
balance_infos
**
object[]
  * Array [
**currency** string
**Possible values:** [`CNY`, `USD`]
货币，人民币或美元
**total_balance** string
总的可用余额，包括赠金和充值余额
**granted_balance** string
未过期的赠金余额
**topped_up_balance** string
充值余额
  * ]


```
{  
  "is_available": true,  
  "balance_infos": [  
    {  
      "currency": "CNY",  
      "total_balance": "110.00",  
      "granted_balance": "10.00",  
      "topped_up_balance": "100.00"  
    }  
  ]  
}  

```

```
{  
  "is_available": true,  
  "balance_infos": [  
    {  
      "currency": "CNY",  
      "total_balance": "110.00",  
      "granted_balance": "10.00",  
      "topped_up_balance": "100.00"  
    }  
  ]  
}  

```

Loading...
[上一页 列出模型](https://api-docs.deepseek.com/zh-cn/api/list-models)[下一页 推理模型 (deepseek-reasoner)](https://api-docs.deepseek.com/zh-cn/guides/reasoning_model)
微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
