# Models & Pricing | DeepSeek API Docs> Source: https://api-docs.deepseek.com/quick_start/pricing/[Skip to main content](https://api-docs.deepseek.com/quick_start/pricing/#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/quick_start/pricing/)
  * [English](https://api-docs.deepseek.com/quick_start/pricing)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/quick_start/pricing)


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
  * Models & Pricing


On this page
# Models & Pricing
The prices listed below are in unites of per 1M tokens. A token, the smallest unit of text that the model recognizes, can be a word, a number, or even a punctuation mark. We will bill based on the total number of input and output tokens by the model.
## Model Details[​](https://api-docs.deepseek.com/quick_start/pricing/#model-details "Direct link to Model Details")
** MODEL | deepseek-chat | deepseek-reasoner  
---|---|---  
MODEL VERSION | DeepSeek-V3.2-Exp  
(Non-thinking Mode) | DeepSeek-V3.2-Exp  
(Thinking Mode)  
CONTEXT LENGTH | 128K  
MAX OUTPUT | DEFAULT: 4K  
MAXIMUM: 8K | DEFAULT: 32K  
MAXIMUM: 64K  
FEATURES | [Json Output](https://api-docs.deepseek.com/guides/json_mode) | ✓ | ✓  
[Function Calling](https://api-docs.deepseek.com/guides/function_calling) | ✓ | ✗(1)  
[Chat Prefix Completion（Beta）](https://api-docs.deepseek.com/guides/chat_prefix_completion) | ✓ | ✓  
[FIM Completion（Beta）](https://api-docs.deepseek.com/guides/fim_completion) | ✓ | ✗  
PRICING | 1M INPUT TOKENS (CACHE HIT) | $0.028  
1M INPUT TOKENS (CACHE MISS) | $0.28  
1M OUTPUT TOKENS | $0.42  
**
  * (1) If the request to the `deepseek-reasoner` model includes the `tools` parameter, the request will actually be processed using the `deepseek-chat` model.


* * *
## Deduction Rules[​](https://api-docs.deepseek.com/quick_start/pricing/#deduction-rules "Direct link to Deduction Rules")
The expense = number of tokens × price. The corresponding fees will be directly deducted from your topped-up balance or granted balance, with a preference for using the granted balance first when both balances are available.
Product prices may vary and DeepSeek reserves the right to adjust them. We recommend topping up based on your actual usage and regularly checking this page for the most recent pricing information.
[Previous Your First API Call](https://api-docs.deepseek.com/)[Next The Temperature Parameter](https://api-docs.deepseek.com/quick_start/parameter_settings)
  * [Model Details](https://api-docs.deepseek.com/quick_start/pricing/#model-details)
  * [Deduction Rules](https://api-docs.deepseek.com/quick_start/pricing/#deduction-rules)


WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
