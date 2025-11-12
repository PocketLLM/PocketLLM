# Features overview - Claude Docs> Source: https://docs.claude.com/en/api/overviewAgent Skills are now available! [Learn more about extending Claude's capabilities with Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview).
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
Using the API
Features overview
[Home](https://docs.claude.com/en/home)[Developer Guide](https://docs.claude.com/en/docs/intro)[API Reference](https://docs.claude.com/en/api/overview)[Model Context Protocol (MCP)](https://docs.claude.com/en/docs/mcp)[Resources](https://docs.claude.com/en/resources/overview)[Release Notes](https://docs.claude.com/en/release-notes/overview)
##### Using the API
  * [Features overview](https://docs.claude.com/en/api/overview)
  * [Client SDKs](https://docs.claude.com/en/api/client-sdks)
  * [Beta headers](https://docs.claude.com/en/api/beta-headers)
  * [Errors](https://docs.claude.com/en/api/errors)


##### Messages
  * [POSTMessages](https://docs.claude.com/en/api/messages)
  * [POSTCount Message tokens](https://docs.claude.com/en/api/messages-count-tokens)


##### Models
  * [GETList Models](https://docs.claude.com/en/api/models-list)
  * [GETGet a Model](https://docs.claude.com/en/api/models)


##### Message Batches
  * [POSTCreate a Message Batch](https://docs.claude.com/en/api/creating-message-batches)
  * [GETRetrieve a Message Batch](https://docs.claude.com/en/api/retrieving-message-batches)
  * [GETRetrieve Message Batch Results](https://docs.claude.com/en/api/retrieving-message-batch-results)
  * [GETList Message Batches](https://docs.claude.com/en/api/listing-message-batches)
  * [POSTCancel a Message Batch](https://docs.claude.com/en/api/canceling-message-batches)
  * [DELDelete a Message Batch](https://docs.claude.com/en/api/deleting-message-batches)


##### Files
  * [POSTCreate a File](https://docs.claude.com/en/api/files-create)
  * [GETList Files](https://docs.claude.com/en/api/files-list)
  * [GETGet File Metadata](https://docs.claude.com/en/api/files-metadata)
  * [GETDownload a File](https://docs.claude.com/en/api/files-content)
  * [DELDelete a File](https://docs.claude.com/en/api/files-delete)


##### Skills
  * Skill Management
  * Skill Versions


##### Admin API
  * Organization Info
  * Organization Member Management
  * Organization Invites
  * Workspace Management
  * Workspace Member Management
  * API Keys
  * Usage and Cost


##### Experimental APIs
  * Prompt tools


##### Text Completions (Legacy)
  * [Migrating from Text Completions](https://docs.claude.com/en/api/migrating-from-text-completions-to-messages)


##### Support & configuration
  * [Rate limits](https://docs.claude.com/en/api/rate-limits)
  * [Service tiers](https://docs.claude.com/en/api/service-tiers)
  * [Versions](https://docs.claude.com/en/api/versioning)
  * [IP addresses](https://docs.claude.com/en/api/ip-addresses)
  * [Supported regions](https://docs.claude.com/en/api/supported-regions)
  * [OpenAI SDK compatibility](https://docs.claude.com/en/api/openai-sdk)


Using the API
# Features overview
Copy page
Explore Claude’s advanced features and capabilities.
Copy page
## 
[​](https://docs.claude.com/en/api/overview#core-capabilities)
Core capabilities
These features enhance Claude’s fundamental abilities for processing, analyzing, and generating content across various formats and use cases. Feature | Description | Availability  
---|---|---  
[1M token context window](https://docs.claude.com/en/docs/build-with-claude/context-windows#1m-token-context-window) | An extended context window that allows you to process much larger documents, maintain longer conversations, and work with more extensive codebases. |  Claude API (Beta)  
  
Amazon Bedrock (Beta)  
  
Google Cloud's Vertex AI (Beta)  
[Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview) | Extend Claude’s capabilities with Skills. Use pre-built Skills (PowerPoint, Excel, Word, PDF) or create custom Skills with instructions and scripts. Skills use progressive disclosure to efficiently manage context. | Claude API (Beta)  
[Batch processing](https://docs.claude.com/en/docs/build-with-claude/batch-processing) | Process large volumes of requests asynchronously for cost savings. Send batches with a large number of queries per batch. Batch API calls costs 50% less than standard API calls. |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
[Citations](https://docs.claude.com/en/docs/build-with-claude/citations) | Ground Claude’s responses in source documents. With Citations, Claude can provide detailed references to the exact sentences and passages it uses to generate responses, leading to more verifiable, trustworthy outputs. |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
[Context editing](https://docs.claude.com/en/docs/build-with-claude/context-editing) | Automatically manage conversation context with configurable strategies. Supports clearing tool results when approaching token limits and managing thinking blocks in extended thinking conversations. |  Claude API (Beta)  
  
Amazon Bedrock (Beta)  
  
Google Cloud's Vertex AI (Beta)  
[Extended thinking](https://docs.claude.com/en/docs/build-with-claude/extended-thinking) | Enhanced reasoning capabilities for complex tasks, providing transparency into Claude’s step-by-step thought process before delivering its final answer. |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
[Files API](https://docs.claude.com/en/docs/build-with-claude/files) | Upload and manage files to use with Claude without re-uploading content with each request. Supports PDFs, images, and text files. | Claude API (Beta)  
[PDF support](https://docs.claude.com/en/docs/build-with-claude/pdf-support) | Process and analyze text and visual content from PDF documents. |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
[Prompt caching (5m)](https://docs.claude.com/en/docs/build-with-claude/prompt-caching) | Provide Claude with more background knowledge and example outputs to reduce costs and latency. |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
[Prompt caching (1hr)](https://docs.claude.com/en/docs/build-with-claude/prompt-caching#1-hour-cache-duration) | Extended 1-hour cache duration for less frequently accessed but important context, complementing the standard 5-minute cache. | Claude API  
[Search results](https://docs.claude.com/en/docs/build-with-claude/search-results) | Enable natural citations for RAG applications by providing search results with proper source attribution. Achieve web search-quality citations for custom knowledge bases and tools. |  Claude API  
  
Google Cloud's Vertex AI  
[Token counting](https://docs.claude.com/en/api/messages-count-tokens) | Token counting enables you to determine the number of tokens in a message before sending it to Claude, helping you make informed decisions about your prompts and usage. |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
[Tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/overview) | Enable Claude to interact with external tools and APIs to perform a wider variety of tasks. For a list of supported tools, see [the Tools table](https://docs.claude.com/en/api/overview#tools). |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
## 
[​](https://docs.claude.com/en/api/overview#tools)
Tools
These features enable Claude to interact with external systems, execute code, and perform automated tasks through various tool interfaces. Feature | Description | Availability  
---|---|---  
[Bash](https://docs.claude.com/en/docs/agents-and-tools/tool-use/bash-tool) | Execute bash commands and scripts to interact with the system shell and perform command-line operations. |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
[Code execution](https://docs.claude.com/en/docs/agents-and-tools/tool-use/code-execution-tool) | Run Python code in a sandboxed environment for advanced data analysis. | Claude API (Beta)  
[Computer use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/computer-use-tool) | Control computer interfaces by taking screenshots and issuing mouse and keyboard commands. |  Claude API (Beta)  
  
Amazon Bedrock (Beta)  
  
Google Cloud's Vertex AI (Beta)  
[Fine-grained tool streaming](https://docs.claude.com/en/docs/agents-and-tools/tool-use/fine-grained-tool-streaming) | Stream tool use parameters without buffering/JSON validation, reducing latency for receiving large parameters. |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
[MCP connector](https://docs.claude.com/en/docs/agents-and-tools/mcp-connector) | Connect to remote [MCP](https://docs.claude.com/en/docs/mcp) servers directly from the Messages API without a separate MCP client. | Claude API (Beta)  
[Memory](https://docs.claude.com/en/docs/agents-and-tools/tool-use/memory-tool) | Enable Claude to store and retrieve information across conversations. Build knowledge bases over time, maintain project context, and learn from past interactions. |  Claude API (Beta)  
  
Amazon Bedrock (Beta)  
  
Google Cloud's Vertex AI (Beta)  
[Text editor](https://docs.claude.com/en/docs/agents-and-tools/tool-use/text-editor-tool) | Create and edit text files with a built-in text editor interface for file manipulation tasks. |  Claude API  
  
Amazon Bedrock  
  
Google Cloud's Vertex AI  
[Web fetch](https://docs.claude.com/en/docs/agents-and-tools/tool-use/web-fetch-tool) | Retrieve full content from specified web pages and PDF documents for in-depth analysis. | Claude API (Beta)  
[Web search](https://docs.claude.com/en/docs/agents-and-tools/tool-use/web-search-tool) | Augment Claude’s comprehensive knowledge with current, real-world data from across the web. |  Claude API  
  
Google Cloud's Vertex AI  
Was this page helpful?
YesNo
[Client SDKs](https://docs.claude.com/en/api/client-sdks)
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
