# V3.1-Terminus Comparison Testing | DeepSeek API Docs> Source: https://api-docs.deepseek.com/guides/comparison_testing[Skip to main content](https://api-docs.deepseek.com/guides/comparison_testing#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API Docs Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API Docs**](https://api-docs.deepseek.com/)
[](https://api-docs.deepseek.com/guides/comparison_testing)
  * [English](https://api-docs.deepseek.com/guides/comparison_testing)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing)


[DeepSeek Platform](https://platform.deepseek.com/)
On this page
# V3.1-Terminus Comparison Testing
As an experimental version, although DeepSeek-V3.2-Exp has been validated for effectiveness on public evaluation sets, it still requires broader and larger-scale testing in real user scenarios to identify potential issues in certain long-tail use cases. To facilitate comparative testing by users, we have temporarily retained additional API access interfaces for V3.1-Terminus.
Users can simply modify the `base_url` to `"https://api.deepseek.com/v3.1_terminus_expires_on_20251015"` to access V3.1-Terminus, with pricing consistent with V3.2-Exp. This endpoint will remain available until October 15, 2025, 15:59 UTC.
We sincerely encourage users to provide valuable feedback during comparative testing via the following link:  
[https://feedback.deepseek.com/dsa](https://trtgsjkv6r.feishu.cn/share/base/form/shrcnRyOUMl0z2Jo8aK3RqccLIB)
* * *
## How to Conduct Comparison Testing[​](https://api-docs.deepseek.com/guides/comparison_testing#how-to-conduct-comparison-testing "Direct link to How to Conduct Comparison Testing")
You can control which model version to access by modifying the `base_url`:
  * When using the **original method** to access the API, you will reach the **DeepSeek-V3.2-Exp** model
  * When you **set`base_url="https://api.deepseek.com/v3.1_terminus_expires_on_20251015"`** , you are accessing the **`DeepSeek-V3.1-Terminus`**model.


The correspondence between `base_url` settings and specific model versions is shown in the table below:
API Type | base_url Setting | Model Version  
---|---|---  
OpenAI | `https://api.deepseek.com` | DeepSeek-V3.2-Exp  
Anthropic | `https://api.deepseek.com/anthropic` | DeepSeek-V3.2-Exp  
OpenAI | `https://api.deepseek.com/v3.1_terminus_expires_on_20251015` | DeepSeek-V3.1-Terminus  
Anthropic | `https://api.deepseek.com/v3.1_terminus_expires_on_20251015/anthropic` | DeepSeek-V3.1-Terminus  
* * *
## Usage Examples[​](https://api-docs.deepseek.com/guides/comparison_testing#usage-examples "Direct link to Usage Examples")
### Accessing V3.1-Terminus via OpenAI-Compatible API[​](https://api-docs.deepseek.com/guides/comparison_testing#accessing-v31-terminus-via-openai-compatible-api "Direct link to Accessing V3.1-Terminus via OpenAI-Compatible API")
  * curl
  * python
  * nodejs


#### Invoke The API[​](https://api-docs.deepseek.com/guides/comparison_testing#invoke-the-api "Direct link to Invoke The API")
```
curl https://api.deepseek.com/v3.1_terminus_expires_on_20251015/chat/completions \  
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

#### Sample Output[​](https://api-docs.deepseek.com/guides/comparison_testing#sample-output "Direct link to Sample Output")
```
{  
    ... ...  
    "model": "deepseek-v3.1-terminus",  
    "choices": [  
        {  
            "index": 0,  
            "message": {  
                "role": "assistant",  
                "content": "Hello! How can I help you today?"  
            },  
            "logprobs": null,  
            "finish_reason": "stop"  
        }  
    ],  
    ... ...  
}  

```

#### Invoke The API[​](https://api-docs.deepseek.com/guides/comparison_testing#invoke-the-api "Direct link to Invoke The API")
```
# Please install OpenAI SDK first: `pip3 install openai`  
import os  
from openai import OpenAI  
  
client = OpenAI(  
    api_key=os.environ.get('DEEPSEEK_API_KEY'),  
    base_url="https://api.deepseek.com/v3.1_terminus_expires_on_20251015")  
  
response = client.chat.completions.create(  
    model="deepseek-chat",  
    messages=[  
{"role":"system","content":"You are a helpful assistant"},  
{"role":"user","content":"Hello"},  
],  
    stream=False  
)  
  
print(f"Model is: {response.model}")  
print(f"Output is: {response.choices[0].message.content}")  

```

#### Sample Output[​](https://api-docs.deepseek.com/guides/comparison_testing#sample-output "Direct link to Sample Output")
```
Model is: deepseek-v3.1-terminus  
Output is: Hello! How can I help you today?  

```

#### Invoke The API[​](https://api-docs.deepseek.com/guides/comparison_testing#invoke-the-api "Direct link to Invoke The API")
```
// Please install OpenAI SDK first: `npm install openai`  
  
importOpenAIfrom"openai";  
  
const openai =newOpenAI({  
baseURL:'https://api.deepseek.com/v3.1_terminus_expires_on_20251015',  
apiKey: process.env.DEEPSEEK_API_KEY,  
});  
  
asyncfunctionmain(){  
const completion =await openai.chat.completions.create({  
messages:[  
{role:"system",content:"You are a helpful assistant."},  
{role:"user",content:"Hello!."}  
],  
model:"deepseek-chat",  
});  
  
console.log("Model is:", completion.model)  
console.log("Output is:", completion.choices[0].message.content);  
}  
  
main();  

```

#### Sample Output[​](https://api-docs.deepseek.com/guides/comparison_testing#sample-output "Direct link to Sample Output")
```
Model is: deepseek-v3.1-terminus  
Output is: Hello! How can I help you today?  

```

As shown in the sample output, **you can verify whether the called model is V3.1-Terminus by checking the`model` field in the API response.**
* * *
### Accessing V3.1-Terminus via Claude Code[​](https://api-docs.deepseek.com/guides/comparison_testing#accessing-v31-terminus-via-claude-code "Direct link to Accessing V3.1-Terminus via Claude Code")
When setting up Claude Code environment variables, you need to modify the `ANTHROPIC_BASE_URL` environment variable to access the DeepSeek-V3.1-Terminus model:
```
export ANTHROPIC_BASE_URL=https://api.deepseek.com/v3.1_terminus_expires_on_20251015/anthropic  

```

For complete configuration instructions, please refer to the [Anthropic API Guide](https://api-docs.deepseek.com/guides/anthropic_api).
  * [How to Conduct Comparison Testing](https://api-docs.deepseek.com/guides/comparison_testing#how-to-conduct-comparison-testing)
  * [Usage Examples](https://api-docs.deepseek.com/guides/comparison_testing#usage-examples)
    * [Accessing V3.1-Terminus via OpenAI-Compatible API](https://api-docs.deepseek.com/guides/comparison_testing#accessing-v31-terminus-via-openai-compatible-api)
    * [Accessing V3.1-Terminus via Claude Code](https://api-docs.deepseek.com/guides/comparison_testing#accessing-v31-terminus-via-claude-code)


WeChat Official Account
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


Community
  * Email
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


More
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
