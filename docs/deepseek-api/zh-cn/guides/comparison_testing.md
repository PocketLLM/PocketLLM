# V3.1-Terminus 对比测试 | DeepSeek API Docs> Source: https://api-docs.deepseek.com/zh-cn/guides/comparison_testing[跳到主要内容](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#__docusaurus_skipToContent_fallback)
[ ![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png)![DeepSeek API 文档 Logo](https://cdn.deepseek.com/platform/favicon.png) **DeepSeek API 文档**](https://api-docs.deepseek.com/zh-cn/)
[](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing)
  * [English](https://api-docs.deepseek.com/guides/comparison_testing)
  * [中文（中国）](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing)


[DeepSeek Platform](https://platform.deepseek.com/)
本页总览
# V3.1-Terminus 对比测试
作为一个实验性的版本，DeepSeek-V3.2-Exp 虽然已经在公开评测集上得到了有效性验证，但仍然需要在用户的真实使用场景中进行范围更广、规模更大的测试，以排查在某些长尾场景中可能存在的问题。为方便用户进行对比测试，我们为 V3.1-Terminus 临时保留了额外的 API 访问接口。
用户只需修改 `base_url="https://api.deepseek.com/v3.1_terminus_expires_on_20251015"` 即可访问 V3.1-Terminus，调用价格与 V3.2-Exp 相同。该接口将保留到北京时间 2025 年 10 月 15 日 23:59。
诚挚希望广大用户在对比测试中为我们提供宝贵的反馈意见，反馈链接：[https://feedback.deepseek.com/dsa](https://trtgsjkv6r.feishu.cn/share/base/form/shrcnRyOUMl0z2Jo8aK3RqccLIB)
* * *
## 如何进行对比测试[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E5%A6%82%E4%BD%95%E8%BF%9B%E8%A1%8C%E5%AF%B9%E6%AF%94%E6%B5%8B%E8%AF%95 "如何进行对比测试的直接链接")
通过修改 `base_url`，您可以控制访问的模型版本：
  * 当您使用**原来的方式** 访问 API 时，访问到的是 **DeepSeek-V3.2-Exp** 模型
  * 当您**设置`base_url="https://api.deepseek.com/v3.1_terminus_expires_on_20251015"`** 时，访问到的是 **`DeepSeek-V3.1-Terminus`**模型


`base_url` 设置与具体模型的对应关系见下表：
API 类型 | base_url 设置 | 模型版本  
---|---|---  
OpenAI | `https://api.deepseek.com` | DeepSeek-V3.2-Exp  
Anthropic | `https://api.deepseek.com/anthropic` | DeepSeek-V3.2-Exp  
OpenAI | `https://api.deepseek.com/v3.1_terminus_expires_on_20251015` | DeepSeek-V3.1-Terminus  
Anthropic | `https://api.deepseek.com/v3.1_terminus_expires_on_20251015/anthropic` | DeepSeek-V3.1-Terminus  
* * *
## 使用示例[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E4%BD%BF%E7%94%A8%E7%A4%BA%E4%BE%8B "使用示例的直接链接")
### 使用 OpenAI 兼容 API 访问 V3.1-Terminus[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E4%BD%BF%E7%94%A8-openai-%E5%85%BC%E5%AE%B9-api-%E8%AE%BF%E9%97%AE-v31-terminus "使用 OpenAI 兼容 API 访问 V3.1-Terminus的直接链接")
  * curl
  * python
  * nodejs


#### 调用方法[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E8%B0%83%E7%94%A8%E6%96%B9%E6%B3%95 "调用方法的直接链接")
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

#### 输出样例[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E8%BE%93%E5%87%BA%E6%A0%B7%E4%BE%8B "输出样例的直接链接")
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

#### 调用方法[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E8%B0%83%E7%94%A8%E6%96%B9%E6%B3%95 "调用方法的直接链接")
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

#### 样例输出[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E6%A0%B7%E4%BE%8B%E8%BE%93%E5%87%BA "样例输出的直接链接")
```
Model is: deepseek-v3.1-terminus  
Output is: Hello! How can I help you today?  

```

#### 调用方法[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E8%B0%83%E7%94%A8%E6%96%B9%E6%B3%95 "调用方法的直接链接")
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

#### 输出样例[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E8%BE%93%E5%87%BA%E6%A0%B7%E4%BE%8B "输出样例的直接链接")
```
Model is: deepseek-v3.1-terminus  
Output is: Hello! How can I help you today?  

```

如样例输出所示，**您可以通过 API 返回中的`model` 字段，验证所调用的模型是否为 V3.1-Terminus。**
* * *
### 使用 Claude Code 访问 V3.1-Terminus[​](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E4%BD%BF%E7%94%A8-claude-code-%E8%AE%BF%E9%97%AE-v31-terminus "使用 Claude Code 访问 V3.1-Terminus的直接链接")
在设置 Claude Code 环境变量时，您需要修改 `ANTHROPIC_BASE_URL` 环境变量来访问 DeepSeek-V3.1-Terminus 模型：
```
export ANTHROPIC_BASE_URL=https://api.deepseek.com/v3.1_terminus_expires_on_20251015/anthropic  

```

完整配置方法，请参考 [Anthropic API 指南](https://api-docs.deepseek.com/zh-cn/guides/anthropic_api)
  * [如何进行对比测试](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E5%A6%82%E4%BD%95%E8%BF%9B%E8%A1%8C%E5%AF%B9%E6%AF%94%E6%B5%8B%E8%AF%95)
  * [使用示例](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E4%BD%BF%E7%94%A8%E7%A4%BA%E4%BE%8B)
    * [使用 OpenAI 兼容 API 访问 V3.1-Terminus](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E4%BD%BF%E7%94%A8-openai-%E5%85%BC%E5%AE%B9-api-%E8%AE%BF%E9%97%AE-v31-terminus)
    * [使用 Claude Code 访问 V3.1-Terminus](https://api-docs.deepseek.com/zh-cn/guides/comparison_testing#%E4%BD%BF%E7%94%A8-claude-code-%E8%AE%BF%E9%97%AE-v31-terminus)


微信公众号
  * ![WeChat QRcode](https://cdn.deepseek.com/official_account.jpg)


社区
  * 邮箱
  * [Discord](https://discord.gg/Tc7c45Zzu5)
  * [Twitter](https://twitter.com/deepseek_ai)


更多
  * [GitHub](https://github.com/deepseek-ai)


Copyright © 2025 DeepSeek, Inc.
