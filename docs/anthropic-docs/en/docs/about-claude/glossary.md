# Glossary - Claude Docs> Source: https://docs.claude.com/en/docs/about-claude/glossaryAgent Skills are now available! [Learn more about extending Claude's capabilities with Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview).
[Claude Docs home page![light logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/light.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=c877c45432515ee69194cb19e9f983a2)![dark logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/dark.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=f5bb877be0cb3cba86cf6d7c88185216)](https://docs.claude.com/)
![US](https://d3gk2c5xim1je2.cloudfront.net/flags/US.svg)
English
Search...
Ctrl K
  * [Console](https://console.anthropic.com/login)
  * [Support](https://support.claude.com/)
  * [Discord](https://www.anthropic.com/discord)
  * [Sign up](https://console.anthropic.com/login)
  * [Sign up](https://console.anthropic.com/login)


Search...
Navigation
Resources
Glossary
[Home](https://docs.claude.com/en/home)[Developer Guide](https://docs.claude.com/en/docs/intro)[API Reference](https://docs.claude.com/en/api/overview)[Model Context Protocol (MCP)](https://docs.claude.com/en/docs/mcp)[Resources](https://docs.claude.com/en/resources/overview)[Release Notes](https://docs.claude.com/en/release-notes/overview)
##### Resources
  * [Glossary](https://docs.claude.com/en/docs/about-claude/glossary)
  * [System Prompts](https://docs.claude.com/en/release-notes/system-prompts)
  * Use cases
  * Prompt Library


On this page
  * [Context window](https://docs.claude.com/en/docs/about-claude/glossary#context-window)
  * [Fine-tuning](https://docs.claude.com/en/docs/about-claude/glossary#fine-tuning)
  * [HHH](https://docs.claude.com/en/docs/about-claude/glossary#hhh)
  * [Latency](https://docs.claude.com/en/docs/about-claude/glossary#latency)
  * [LLM](https://docs.claude.com/en/docs/about-claude/glossary#llm)
  * [MCP (Model Context Protocol)](https://docs.claude.com/en/docs/about-claude/glossary#mcp-model-context-protocol)
  * [MCP connector](https://docs.claude.com/en/docs/about-claude/glossary#mcp-connector)
  * [Pretraining](https://docs.claude.com/en/docs/about-claude/glossary#pretraining)
  * [RAG (Retrieval augmented generation)](https://docs.claude.com/en/docs/about-claude/glossary#rag-retrieval-augmented-generation)
  * [RLHF](https://docs.claude.com/en/docs/about-claude/glossary#rlhf)
  * [Temperature](https://docs.claude.com/en/docs/about-claude/glossary#temperature)
  * [TTFT (Time to first token)](https://docs.claude.com/en/docs/about-claude/glossary#ttft-time-to-first-token)
  * [Tokens](https://docs.claude.com/en/docs/about-claude/glossary#tokens)


Resources
# Glossary
Copy page
These concepts are not unique to Anthropic’s language models, but we present a brief summary of key terms below.
Copy page
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#context-window)
Context window
The “context window” refers to the amount of text a language model can look back on and reference when generating new text. This is different from the large corpus of data the language model was trained on, and instead represents a “working memory” for the model. A larger context window allows the model to understand and respond to more complex and lengthy prompts, while a smaller context window may limit the model’s ability to handle longer prompts or maintain coherence over extended conversations. See our [guide to understanding context windows](https://docs.claude.com/en/docs/build-with-claude/context-windows) to learn more.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#fine-tuning)
Fine-tuning
Fine-tuning is the process of further training a pretrained language model using additional data. This causes the model to start representing and mimicking the patterns and characteristics of the fine-tuning dataset. Claude is not a bare language model; it has already been fine-tuned to be a helpful assistant. Our API does not currently offer fine-tuning, but please ask your Anthropic contact if you are interested in exploring this option. Fine-tuning can be useful for adapting a language model to a specific domain, task, or writing style, but it requires careful consideration of the fine-tuning data and the potential impact on the model’s performance and biases.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#hhh)
HHH
These three H’s represent Anthropic’s goals in ensuring that Claude is beneficial to society:
  * A **helpful** AI will attempt to perform the task or answer the question posed to the best of its abilities, providing relevant and useful information.
  * An **honest** AI will give accurate information, and not hallucinate or confabulate. It will acknowledge its limitations and uncertainties when appropriate.
  * A **harmless** AI will not be offensive or discriminatory, and when asked to aid in a dangerous or unethical act, the AI should politely refuse and explain why it cannot comply.


## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#latency)
Latency
Latency, in the context of generative AI and large language models, refers to the time it takes for the model to respond to a given prompt. It is the delay between submitting a prompt and receiving the generated output. Lower latency indicates faster response times, which is crucial for real-time applications, chatbots, and interactive experiences. Factors that can affect latency include model size, hardware capabilities, network conditions, and the complexity of the prompt and the generated response.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#llm)
LLM
Large language models (LLMs) are AI language models with many parameters that are capable of performing a variety of surprisingly useful tasks. These models are trained on vast amounts of text data and can generate human-like text, answer questions, summarize information, and more. Claude is a conversational assistant based on a large language model that has been fine-tuned and trained using RLHF to be more helpful, honest, and harmless.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#mcp-model-context-protocol)
MCP (Model Context Protocol)
Model Context Protocol (MCP) is an open protocol that standardizes how applications provide context to LLMs. Like a USB-C port for AI applications, MCP provides a unified way to connect AI models to different data sources and tools. MCP enables AI systems to maintain consistent context across interactions and access external resources in a standardized manner. See our [MCP documentation](https://docs.claude.com/en/docs/mcp) to learn more.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#mcp-connector)
MCP connector
The MCP connector is a feature that allows API users to connect to MCP servers directly from the Messages API without building an MCP client. This enables seamless integration with MCP-compatible tools and services through the Claude API. The MCP connector supports features like tool calling and is available in public beta. See our [MCP connector documentation](https://docs.claude.com/en/docs/agents-and-tools/mcp-connector) to learn more.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#pretraining)
Pretraining
Pretraining is the initial process of training language models on a large unlabeled corpus of text. In Claude’s case, autoregressive language models (like Claude’s underlying model) are pretrained to predict the next word, given the previous context of text in the document. These pretrained models are not inherently good at answering questions or following instructions, and often require deep skill in prompt engineering to elicit desired behaviors. Fine-tuning and RLHF are used to refine these pretrained models, making them more useful for a wide range of tasks.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#rag-retrieval-augmented-generation)
RAG (Retrieval augmented generation)
Retrieval augmented generation (RAG) is a technique that combines information retrieval with language model generation to improve the accuracy and relevance of the generated text, and to better ground the model’s response in evidence. In RAG, a language model is augmented with an external knowledge base or a set of documents that is passed into the context window. The data is retrieved at run time when a query is sent to the model, although the model itself does not necessarily retrieve the data (but can with [tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/overview) and a retrieval function). When generating text, relevant information first must be retrieved from the knowledge base based on the input prompt, and then passed to the model along with the original query. The model uses this information to guide the output it generates. This allows the model to access and utilize information beyond its training data, reducing the reliance on memorization and improving the factual accuracy of the generated text. RAG can be particularly useful for tasks that require up-to-date information, domain-specific knowledge, or explicit citation of sources. However, the effectiveness of RAG depends on the quality and relevance of the external knowledge base and the knowledge that is retrieved at runtime.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#rlhf)
RLHF
Reinforcement Learning from Human Feedback (RLHF) is a technique used to train a pretrained language model to behave in ways that are consistent with human preferences. This can include helping the model follow instructions more effectively or act more like a chatbot. Human feedback consists of ranking a set of two or more example texts, and the reinforcement learning process encourages the model to prefer outputs that are similar to the higher-ranked ones. Claude has been trained using RLHF to be a more helpful assistant. For more details, you can read [Anthropic’s paper on the subject](https://arxiv.org/abs/2204.05862).
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#temperature)
Temperature
Temperature is a parameter that controls the randomness of a model’s predictions during text generation. Higher temperatures lead to more creative and diverse outputs, allowing for multiple variations in phrasing and, in the case of fiction, variation in answers as well. Lower temperatures result in more conservative and deterministic outputs that stick to the most probable phrasing and answers. Adjusting the temperature enables users to encourage a language model to explore rare, uncommon, or surprising word choices and sequences, rather than only selecting the most likely predictions.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#ttft-time-to-first-token)
TTFT (Time to first token)
Time to First Token (TTFT) is a performance metric that measures the time it takes for a language model to generate the first token of its output after receiving a prompt. It is an important indicator of the model’s responsiveness and is particularly relevant for interactive applications, chatbots, and real-time systems where users expect quick initial feedback. A lower TTFT indicates that the model can start generating a response faster, providing a more seamless and engaging user experience. Factors that can influence TTFT include model size, hardware capabilities, network conditions, and the complexity of the prompt.
## 
[​](https://docs.claude.com/en/docs/about-claude/glossary#tokens)
Tokens
Tokens are the smallest individual units of a language model, and can correspond to words, subwords, characters, or even bytes (in the case of Unicode). For Claude, a token approximately represents 3.5 English characters, though the exact number can vary depending on the language used. Tokens are typically hidden when interacting with language models at the “text” level but become relevant when examining the exact inputs and outputs of a language model. When Claude is provided with text to evaluate, the text (consisting of a series of characters) is encoded into a series of tokens for the model to process. Larger tokens enable data efficiency during inference and pretraining (and are utilized when possible), while smaller tokens allow a model to handle uncommon or never-before-seen words. The choice of tokenization method can impact the model’s performance, vocabulary size, and ability to handle out-of-vocabulary words.
Was this page helpful?
YesNo
[Overview](https://docs.claude.com/en/resources/overview)[System Prompts](https://docs.claude.com/en/release-notes/system-prompts)
Assistant
Responses are generated using AI and may contain mistakes.
[Claude Docs home page![light logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/light.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=c877c45432515ee69194cb19e9f983a2)![dark logo](https://mintcdn.com/anthropic-claude-docs/DcI2Ybid7ZEnFaf0/logo/dark.svg?fit=max&auto=format&n=DcI2Ybid7ZEnFaf0&q=85&s=f5bb877be0cb3cba86cf6d7c88185216)](https://docs.claude.com/)
[x](https://x.com/AnthropicAI)[linkedin](https://www.linkedin.com/company/anthropicresearch)
Company
[Anthropic](https://www.anthropic.com/company)[Careers](https://www.anthropic.com/careers)[Economic Futures](https://www.anthropic.com/economic-futures)[Research](https://www.anthropic.com/research)[News](https://www.anthropic.com/news)[Trust center](https://trust.anthropic.com/)[Transparency](https://www.anthropic.com/transparency)
Help and security
[Availability](https://www.anthropic.com/supported-countries)[Status](https://status.anthropic.com/)[Support center](https://support.claude.com/)
Learn
[Courses](https://www.anthropic.com/learn)[MCP connectors](https://claude.com/partners/mcp)[Customer stories](https://www.claude.com/customers)[Engineering blog](https://www.anthropic.com/engineering)[Events](https://www.anthropic.com/events)[Powered by Claude](https://claude.com/partners/powered-by-claude)[Service partners](https://claude.com/partners/services)[Startups program](https://claude.com/programs/startups)
Terms and policies
[Privacy policy](https://www.anthropic.com/legal/privacy)[Disclosure policy](https://www.anthropic.com/responsible-disclosure-policy)[Usage policy](https://www.anthropic.com/legal/aup)[Commercial terms](https://www.anthropic.com/legal/commercial-terms)[Consumer terms](https://www.anthropic.com/legal/consumer-terms)
