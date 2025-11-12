# How to implement tool use - Claude Docs> Source: https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-useAgent Skills are now available! [Learn more about extending Claude's capabilities with Agent Skills](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview).
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
Tools
How to implement tool use
[Home](https://docs.claude.com/en/home)[Developer Guide](https://docs.claude.com/en/docs/intro)[API Reference](https://docs.claude.com/en/api/overview)[Model Context Protocol (MCP)](https://docs.claude.com/en/docs/mcp)[Resources](https://docs.claude.com/en/resources/overview)[Release Notes](https://docs.claude.com/en/release-notes/overview)
##### First steps
  * [Intro to Claude](https://docs.claude.com/en/docs/intro)
  * [Quickstart](https://docs.claude.com/en/docs/get-started)


##### Models & pricing
  * [Models overview](https://docs.claude.com/en/docs/about-claude/models/overview)
  * [Choosing a model](https://docs.claude.com/en/docs/about-claude/models/choosing-a-model)
  * [What's new in Claude 4.5](https://docs.claude.com/en/docs/about-claude/models/whats-new-claude-4-5)
  * [Migrating to Claude 4.5](https://docs.claude.com/en/docs/about-claude/models/migrating-to-claude-4)
  * [Model deprecations](https://docs.claude.com/en/docs/about-claude/model-deprecations)
  * [Pricing](https://docs.claude.com/en/docs/about-claude/pricing)


##### Build with Claude
  * [Features overview](https://docs.claude.com/en/docs/build-with-claude/overview)
  * [Using the Messages API](https://docs.claude.com/en/docs/build-with-claude/working-with-messages)
  * [Context windows](https://docs.claude.com/en/docs/build-with-claude/context-windows)
  * [Prompting best practices](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/claude-4-best-practices)


##### Capabilities
  * [Prompt caching](https://docs.claude.com/en/docs/build-with-claude/prompt-caching)
  * [Context editing](https://docs.claude.com/en/docs/build-with-claude/context-editing)
  * [Extended thinking](https://docs.claude.com/en/docs/build-with-claude/extended-thinking)
  * [Streaming Messages](https://docs.claude.com/en/docs/build-with-claude/streaming)
  * [Batch processing](https://docs.claude.com/en/docs/build-with-claude/batch-processing)
  * [Citations](https://docs.claude.com/en/docs/build-with-claude/citations)
  * [Multilingual support](https://docs.claude.com/en/docs/build-with-claude/multilingual-support)
  * [Token counting](https://docs.claude.com/en/docs/build-with-claude/token-counting)
  * [Embeddings](https://docs.claude.com/en/docs/build-with-claude/embeddings)
  * [Vision](https://docs.claude.com/en/docs/build-with-claude/vision)
  * [PDF support](https://docs.claude.com/en/docs/build-with-claude/pdf-support)
  * [Files API](https://docs.claude.com/en/docs/build-with-claude/files)
  * [Search results](https://docs.claude.com/en/docs/build-with-claude/search-results)
  * [Google Sheets add-on](https://docs.claude.com/en/docs/agents-and-tools/claude-for-sheets)


##### Tools
  * [Overview](https://docs.claude.com/en/docs/agents-and-tools/tool-use/overview)
  * [How to implement tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use)
  * [Token-efficient tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/token-efficient-tool-use)
  * [Fine-grained tool streaming](https://docs.claude.com/en/docs/agents-and-tools/tool-use/fine-grained-tool-streaming)
  * [Bash tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/bash-tool)
  * [Code execution tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/code-execution-tool)
  * [Computer use tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/computer-use-tool)
  * [Text editor tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/text-editor-tool)
  * [Web fetch tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/web-fetch-tool)
  * [Web search tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/web-search-tool)
  * [Memory tool](https://docs.claude.com/en/docs/agents-and-tools/tool-use/memory-tool)


##### Agent Skills
  * [Overview](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/overview)
  * [Quickstart](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/quickstart)
  * [Best practices](https://docs.claude.com/en/docs/agents-and-tools/agent-skills/best-practices)
  * [Using Skills with the API](https://docs.claude.com/en/docs/build-with-claude/skills-guide)


##### Agent SDK
  * [Overview](https://docs.claude.com/en/docs/agent-sdk/overview)
  * [TypeScript SDK](https://docs.claude.com/en/docs/agent-sdk/typescript)
  * [Python SDK](https://docs.claude.com/en/docs/agent-sdk/python)
  * Guides


##### MCP in the API
  * [MCP connector](https://docs.claude.com/en/docs/agents-and-tools/mcp-connector)
  * [Remote MCP servers](https://docs.claude.com/en/docs/agents-and-tools/remote-mcp-servers)


##### Claude on 3rd-party platforms
  * [Amazon Bedrock](https://docs.claude.com/en/docs/build-with-claude/claude-on-amazon-bedrock)
  * [Vertex AI](https://docs.claude.com/en/docs/build-with-claude/claude-on-vertex-ai)


##### Prompt engineering
  * [Overview](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/overview)
  * [Prompt generator](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/prompt-generator)
  * [Use prompt templates](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/prompt-templates-and-variables)
  * [Prompt improver](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/prompt-improver)
  * [Be clear and direct](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/be-clear-and-direct)
  * [Use examples (multishot prompting)](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/multishot-prompting)
  * [Let Claude think (CoT)](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/chain-of-thought)
  * [Use XML tags](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/use-xml-tags)
  * [Give Claude a role (system prompts)](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/system-prompts)
  * [Prefill Claude's response](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/prefill-claudes-response)
  * [Chain complex prompts](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/chain-prompts)
  * [Long context tips](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/long-context-tips)
  * [Extended thinking tips](https://docs.claude.com/en/docs/build-with-claude/prompt-engineering/extended-thinking-tips)


##### Test & evaluate
  * [Define success criteria](https://docs.claude.com/en/docs/test-and-evaluate/define-success)
  * [Develop test cases](https://docs.claude.com/en/docs/test-and-evaluate/develop-tests)
  * [Using the Evaluation Tool](https://docs.claude.com/en/docs/test-and-evaluate/eval-tool)
  * [Reducing latency](https://docs.claude.com/en/docs/test-and-evaluate/strengthen-guardrails/reduce-latency)


##### Strengthen guardrails
  * [Reduce hallucinations](https://docs.claude.com/en/docs/test-and-evaluate/strengthen-guardrails/reduce-hallucinations)
  * [Increase output consistency](https://docs.claude.com/en/docs/test-and-evaluate/strengthen-guardrails/increase-consistency)
  * [Mitigate jailbreaks](https://docs.claude.com/en/docs/test-and-evaluate/strengthen-guardrails/mitigate-jailbreaks)
  * [Streaming refusals](https://docs.claude.com/en/docs/test-and-evaluate/strengthen-guardrails/handle-streaming-refusals)
  * [Reduce prompt leak](https://docs.claude.com/en/docs/test-and-evaluate/strengthen-guardrails/reduce-prompt-leak)
  * [Keep Claude in character](https://docs.claude.com/en/docs/test-and-evaluate/strengthen-guardrails/keep-claude-in-character)


##### Administration and monitoring
  * [Admin API overview](https://docs.claude.com/en/docs/build-with-claude/administration-api)
  * [Usage and Cost API](https://docs.claude.com/en/docs/build-with-claude/usage-cost-api)
  * [Claude Code Analytics API](https://docs.claude.com/en/docs/build-with-claude/claude-code-analytics-api)


On this page
  * [Choosing a model](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#choosing-a-model)
  * [Specifying client tools](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#specifying-client-tools)
  * [Tool use system prompt](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#tool-use-system-prompt)
  * [Best practices for tool definitions](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#best-practices-for-tool-definitions)
  * [Tool runner (beta)](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#tool-runner-beta)
  * [Basic usage](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#basic-usage)
  * [Iterating over the tool runner](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#iterating-over-the-tool-runner)
  * [Advanced usage](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#advanced-usage)
  * [Streaming](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#streaming)
  * [Controlling Claude’s output](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#controlling-claude%E2%80%99s-output)
  * [Forcing tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#forcing-tool-use)
  * [JSON output](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#json-output)
  * [Model responses with tools](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#model-responses-with-tools)
  * [Parallel tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#parallel-tool-use)
  * [Maximizing parallel tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#maximizing-parallel-tool-use)
  * [Handling tool use and tool result content blocks](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-tool-use-and-tool-result-content-blocks)
  * [Handling results from client tools](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-results-from-client-tools)
  * [Handling results from server tools](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-results-from-server-tools)
  * [Handling the max_tokens stop reason](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-the-max-tokens-stop-reason)
  * [Handling the pause_turn stop reason](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-the-pause-turn-stop-reason)
  * [Troubleshooting errors](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#troubleshooting-errors)


Tools
# How to implement tool use
Copy page
Copy page
## 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#choosing-a-model)
Choosing a model
We recommend using the latest Claude Sonnet (4.5) or Claude Opus (4.1) model for complex tools and ambiguous queries; they handle multiple tools better and seek clarification when needed. Use Claude Haiku models for straightforward tools, but note they may infer missing parameters.
If using Claude with tool use and extended thinking, refer to our guide [here](https://docs.claude.com/en/docs/build-with-claude/extended-thinking) for more information.
## 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#specifying-client-tools)
Specifying client tools
Client tools (both Anthropic-defined and user-defined) are specified in the `tools` top-level parameter of the API request. Each tool definition includes: Parameter | Description  
---|---  
`name` | The name of the tool. Must match the regex `^[a-zA-Z0-9_-]{1,64}$`.  
`description` | A detailed plaintext description of what the tool does, when it should be used, and how it behaves.  
`input_schema` | A [JSON Schema](https://json-schema.org/) object defining the expected parameters for the tool.  
Example simple tool definition
JSON
Copy
```
{
  "name": "get_weather",
  "description": "Get the current weather in a given location",
  "input_schema": {
    "type": "object",
    "properties": {
      "location": {
        "type": "string",
        "description": "The city and state, e.g. San Francisco, CA"
      },
      "unit": {
        "type": "string",
        "enum": ["celsius", "fahrenheit"],
        "description": "The unit of temperature, either 'celsius' or 'fahrenheit'"
      }
    },
    "required": ["location"]
  }
}

```

This tool, named `get_weather`, expects an input object with a required `location` string and an optional `unit` string that must be either “celsius” or “fahrenheit”.
### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#tool-use-system-prompt)
Tool use system prompt
When you call the Claude API with the `tools` parameter, we construct a special system prompt from the tool definitions, tool configuration, and any user-specified system prompt. The constructed prompt is designed to instruct the model to use the specified tool(s) and provide the necessary context for the tool to operate properly:
Copy
```
In this environment you have access to a set of tools you can use to answer the user's question.
{{ FORMATTING INSTRUCTIONS }}
String and scalar parameters should be specified as is, while lists and objects should use JSON format. Note that spaces for string values are not stripped. The output is not expected to be valid XML and is parsed with regular expressions.
Here are the functions available in JSONSchema format:
{{ TOOL DEFINITIONS IN JSON SCHEMA }}
{{ USER SYSTEM PROMPT }}
{{ TOOL CONFIGURATION }}

```

### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#best-practices-for-tool-definitions)
Best practices for tool definitions
To get the best performance out of Claude when using tools, follow these guidelines:
  * **Provide extremely detailed descriptions.** This is by far the most important factor in tool performance. Your descriptions should explain every detail about the tool, including: 
    * What the tool does
    * When it should be used (and when it shouldn’t)
    * What each parameter means and how it affects the tool’s behavior
    * Any important caveats or limitations, such as what information the tool does not return if the tool name is unclear. The more context you can give Claude about your tools, the better it will be at deciding when and how to use them. Aim for at least 3-4 sentences per tool description, more if the tool is complex.
  * **Prioritize descriptions over examples.** While you can include examples of how to use a tool in its description or in the accompanying prompt, this is less important than having a clear and comprehensive explanation of the tool’s purpose and parameters. Only add examples after you’ve fully fleshed out the description.


Example of a good tool description
JSON
Copy
```
{
  "name": "get_stock_price",
  "description": "Retrieves the current stock price for a given ticker symbol. The ticker symbol must be a valid symbol for a publicly traded company on a major US stock exchange like NYSE or NASDAQ. The tool will return the latest trade price in USD. It should be used when the user asks about the current or most recent price of a specific stock. It will not provide any other information about the stock or company.",
  "input_schema": {
    "type": "object",
    "properties": {
      "ticker": {
        "type": "string",
        "description": "The stock ticker symbol, e.g. AAPL for Apple Inc."
      }
    },
    "required": ["ticker"]
  }
}

```

Example poor tool description
JSON
Copy
```
{
  "name": "get_stock_price",
  "description": "Gets the stock price for a ticker.",
  "input_schema": {
    "type": "object",
    "properties": {
      "ticker": {
        "type": "string"
      }
    },
    "required": ["ticker"]
  }
}

```

The good description clearly explains what the tool does, when to use it, what data it returns, and what the `ticker` parameter means. The poor description is too brief and leaves Claude with many open questions about the tool’s behavior and usage.
## 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#tool-runner-beta)
Tool runner (beta)
The tool runner provides an out-of-the-box solution for executing tools with Claude. Instead of manually handling tool calls, tool results, and conversation management, the tool runner automatically:
  * Executes tools when Claude calls them
  * Handles the request/response cycle
  * Manages conversation state
  * Provides type safety and validation

We recommend that you use the tool runner for most tool use implementations.
The tool runner is currently in beta and only available in the [Python](https://github.com/anthropics/anthropic-sdk-python/blob/main/tools.md) and [TypeScript](https://github.com/anthropics/anthropic-sdk-typescript/blob/main/helpers.md#tool-helpers) SDKs.
  * Python
  * TypeScript (Zod)
  * TypeScript (JSON Schema)


### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#basic-usage)
Basic usage
Use the `@beta_tool` decorator to define tools and `client.beta.messages.tool_runner()` to execute them.
If you’re using the async client, replace `@beta_tool` with `@beta_async_tool` and define the function with `async def`.
Copy
```
import anthropic
import json
from anthropic import beta_tool
# Initialize client
client = anthropic.Anthropic()
# Define tools using the decorator
@beta_tool
def get_weather(location: str, unit: str = "fahrenheit") -> str:
    """Get the current weather in a given location.
    Args:
        location: The city and state, e.g. San Francisco, CA
        unit: Temperature unit, either 'celsius' or 'fahrenheit'
    """
    # In a full implementation, you'd call a weather API here
    return json.dumps({"temperature": "20°C", "condition": "Sunny"})
@beta_tool
def calculate_sum(a: int, b: int) -> str:
    """Add two numbers together.
    Args:
        a: First number
        b: Second number
    """
    return str(a + b)
# Use the tool runner
runner = client.beta.messages.tool_runner(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    tools=[get_weather, calculate_sum],
    messages=[
        {"role": "user", "content": "What's the weather like in Paris? Also, what's 15 + 27?"}
    ]
)
for message in runner:
    print(message.content[0].text)

```

The decorated function must return a content block or content block array, including text, images, or document blocks. This allows tools to return rich, multimodal responses. Returned strings will be converted to a text content block. If you want to return a structured JSON object to Claude, encode it to a JSON string before returning it. Numbers, booleans or other non-string primitives also must be converted to strings.The `@beta_tool` decorator will inspect the function arguments and the docstring to extract a json schema representation of the given function, in the example above `calculate_sum` will be turned into:
Copy
```
{
  "name": "calculate_sum",
  "description": "Adds two integers together.",
  "input_schema": {
    "additionalProperties": false,
    "properties": {
      "left": {
        "description": "The first integer to add.",
        "title": "Left",
        "type": "integer"
      },
      "right": {
        "description": "The second integer to add.",
        "title": "Right",
        "type": "integer"
      }
    },
    "required": ["left", "right"],
    "type": "object"
  }
}

```

### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#iterating-over-the-tool-runner)
Iterating over the tool runner
The tool runner returned by `tool_runner()` is an iterable, which you can iterate over with a `for` loop. This is often referred to as a “tool call loop”. Each loop iteration yields a message that was returned by Claude.After your code has a chance to process the current message inside the loop, the tool runner will check the message to see if Claude requested a tool use. If so, it will call the tool and send the tool result back to Claude automatically, then yield the next message from Claude to start the next iteration of your loop.You may end the loop at any iteration with a simple `break` statement. The tool runner will loop until Claude returns a message without a tool use.If you don’t care about intermediate messages, instead of using a loop, you can call the `until_done()` method, which will return the final message from Claude:
Copy
```
runner = client.beta.messages.tool_runner(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    tools=[get_weather, calculate_sum],
    messages=[
        {"role": "user", "content": "What's the weather like in Paris? Also, what's 15 + 27?"}
    ]
)
final_message = runner.until_done()
print(final_message.content[0].text)

```

### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#advanced-usage)
Advanced usage
Within the loop, you have the ability to fully customize the tool runner’s next request to the Messages API. The method `runner.generate_tool_call_response()` will call the tool (if Claude triggered a tool use) and give you access to the tool result that will be sent back to the Messages API. The methods `runner.set_messages_params()` and `runner.append_messages()` allow you to modify the parameters for the next Messages API request.
Copy
```
runner = client.beta.messages.tool_runner(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    tools=[get_weather],
    messages=[{"role": "user", "content": "What's the weather in San Francisco?"}]
)
for message in runner:
    # Get the tool response that will be sent
    tool_response = runner.generate_tool_call_response()
    # Customize the next request
    runner.set_messages_params(lambda params: {
        **params,
        "max_tokens": 2048  # Increase tokens for next request
    })
    # Or add additional messages
    runner.append_messages(
        {"role": "user", "content": "Please be concise in your response."}
    )

```

### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#streaming)
Streaming
When enabling streaming with `stream=True`, each value emitted by the tool runner is a `BetaMessageStream` as returned from `anthropic.messages.stream()`. The `BetaMessageStream` is itself an iterable that yields streaming events from the Messages API.You can use `message_stream.get_final_message()` to let the SDK do the accumulation of streaming events into the final message for you.
Copy
```
runner = client.beta.messages.tool_runner(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    tools=[calculate_sum],
    messages=[{"role": "user", "content": "What is 15 + 27?"}],
    stream=True
)
# When streaming, the runner returns BetaMessageStream
for message_stream in runner:
    for event in message_stream:
        print('event:', event)
    print('message:', message_stream.get_final_message())
print(runner.until_done())

```

The SDK tool runner is in beta. The rest of this document covers manual tool implementation.
## 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#controlling-claude%E2%80%99s-output)
Controlling Claude’s output
### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#forcing-tool-use)
Forcing tool use
In some cases, you may want Claude to use a specific tool to answer the user’s question, even if Claude thinks it can provide an answer without using a tool. You can do this by specifying the tool in the `tool_choice` field like so:
Copy
```
tool_choice = {"type": "tool", "name": "get_weather"}

```

When working with the tool_choice parameter, we have four possible options:
  * `auto` allows Claude to decide whether to call any provided tools or not. This is the default value when `tools` are provided.
  * `any` tells Claude that it must use one of the provided tools, but doesn’t force a particular tool.
  * `tool` allows us to force Claude to always use a particular tool.
  * `none` prevents Claude from using any tools. This is the default value when no `tools` are provided.


When using [prompt caching](https://docs.claude.com/en/docs/build-with-claude/prompt-caching#what-invalidates-the-cache), changes to the `tool_choice` parameter will invalidate cached message blocks. Tool definitions and system prompts remain cached, but message content must be reprocessed.
This diagram illustrates how each option works:
![](https://mintcdn.com/anthropic-claude-docs/LF5WV0SNF6oudpT5/images/tool_choice.png?fit=max&auto=format&n=LF5WV0SNF6oudpT5&q=85&s=fb88b9fa0da23fc231e4fece253f4406)
Note that when you have `tool_choice` as `any` or `tool`, we will prefill the assistant message to force a tool to be used. This means that the models will not emit a natural language response or explanation before `tool_use` content blocks, even if explicitly asked to do so.
When using [extended thinking](https://docs.claude.com/en/docs/build-with-claude/extended-thinking) with tool use, `tool_choice: {"type": "any"}` and `tool_choice: {"type": "tool", "name": "..."}` are not supported and will result in an error. Only `tool_choice: {"type": "auto"}` (the default) and `tool_choice: {"type": "none"}` are compatible with extended thinking.
Our testing has shown that this should not reduce performance. If you would like the model to provide natural language context or explanations while still requesting that the model use a specific tool, you can use `{"type": "auto"}` for `tool_choice` (the default) and add explicit instructions in a `user` message. For example: `What's the weather like in London? Use the get_weather tool in your response.`
### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#json-output)
JSON output
Tools do not necessarily need to be client functions — you can use tools anytime you want the model to return JSON output that follows a provided schema. For example, you might use a `record_summary` tool with a particular schema. See [Tool use with Claude](https://docs.claude.com/en/docs/agents-and-tools/tool-use/overview) for a full working example.
### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#model-responses-with-tools)
Model responses with tools
When using tools, Claude will often comment on what it’s doing or respond naturally to the user before invoking tools. For example, given the prompt “What’s the weather like in San Francisco right now, and what time is it there?”, Claude might respond with:
JSON
Copy
```
{
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "I'll help you check the current weather and time in San Francisco."
    },
    {
      "type": "tool_use",
      "id": "toolu_01A09q90qw90lq917835lq9",
      "name": "get_weather",
      "input": {"location": "San Francisco, CA"}
    }
  ]
}

```

This natural response style helps users understand what Claude is doing and creates a more conversational interaction. You can guide the style and content of these responses through your system prompts and by providing `<examples>` in your prompts. It’s important to note that Claude may use various phrasings and approaches when explaining its actions. Your code should treat these responses like any other assistant-generated text, and not rely on specific formatting conventions.
### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#parallel-tool-use)
Parallel tool use
By default, Claude may use multiple tools to answer a user query. You can disable this behavior by:
  * Setting `disable_parallel_tool_use=true` when tool_choice type is `auto`, which ensures that Claude uses **at most one** tool
  * Setting `disable_parallel_tool_use=true` when tool_choice type is `any` or `tool`, which ensures that Claude uses **exactly one** tool


Complete parallel tool use example
**Simpler with Tool runner** : The example below shows manual parallel tool handling. For most use cases, [tool runner](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#tool-runner-beta) automatically handle parallel tool execution with much less code.
Here’s a complete example showing how to properly format parallel tool calls in the message history:
Python
TypeScript
Copy
```
import anthropic
client = anthropic.Anthropic()
# Define tools
tools = [
    {
        "name": "get_weather",
        "description": "Get the current weather in a given location",
        "input_schema": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA"
                }
            },
            "required": ["location"]
        }
    },
    {
        "name": "get_time",
        "description": "Get the current time in a given timezone",
        "input_schema": {
            "type": "object",
            "properties": {
                "timezone": {
                    "type": "string",
                    "description": "The timezone, e.g. America/New_York"
                }
            },
            "required": ["timezone"]
        }
    }
]
# Initial request
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    tools=tools,
    messages=[
        {
            "role": "user",
            "content": "What's the weather in SF and NYC, and what time is it there?"
        }
    ]
)
# Claude's response with parallel tool calls
print("Claude wants to use tools:", response.stop_reason == "tool_use")
print("Number of tool calls:", len([c for c in response.content if c.type == "tool_use"]))
# Build the conversation with tool results
messages = [
    {
        "role": "user",
        "content": "What's the weather in SF and NYC, and what time is it there?"
    },
    {
        "role": "assistant",
        "content": response.content  # Contains multiple tool_use blocks
    },
    {
        "role": "user",
        "content": [
            {
                "type": "tool_result",
                "tool_use_id": "toolu_01",  # Must match the ID from tool_use
                "content": "San Francisco: 68°F, partly cloudy"
            },
            {
                "type": "tool_result",
                "tool_use_id": "toolu_02",
                "content": "New York: 45°F, clear skies"
            },
            {
                "type": "tool_result",
                "tool_use_id": "toolu_03",
                "content": "San Francisco time: 2:30 PM PST"
            },
            {
                "type": "tool_result",
                "tool_use_id": "toolu_04",
                "content": "New York time: 5:30 PM EST"
            }
        ]
    }
]
# Get final response
final_response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    tools=tools,
    messages=messages
)
print(final_response.content[0].text)

```

The assistant message with parallel tool calls would look like this:
Copy
```
{
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "I'll check the weather and time for both San Francisco and New York City."
    },
    {
      "type": "tool_use",
      "id": "toolu_01",
      "name": "get_weather",
      "input": {"location": "San Francisco, CA"}
    },
    {
      "type": "tool_use",
      "id": "toolu_02",
      "name": "get_weather",
      "input": {"location": "New York, NY"}
    },
    {
      "type": "tool_use",
      "id": "toolu_03",
      "name": "get_time",
      "input": {"timezone": "America/Los_Angeles"}
    },
    {
      "type": "tool_use",
      "id": "toolu_04",
      "name": "get_time",
      "input": {"timezone": "America/New_York"}
    }
  ]
}

```

Complete test script for parallel tools
Here’s a complete, runnable script to test and verify parallel tool calls are working correctly:
Python
TypeScript
Copy
```
#!/usr/bin/env python3
"""Test script to verify parallel tool calls with the Claude API"""
import os
from anthropic import Anthropic
# Initialize client
client = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY"))
# Define tools
tools = [
    {
        "name": "get_weather",
        "description": "Get the current weather in a given location",
        "input_schema": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "The city and state, e.g. San Francisco, CA"
                }
            },
            "required": ["location"]
        }
    },
    {
        "name": "get_time",
        "description": "Get the current time in a given timezone",
        "input_schema": {
            "type": "object",
            "properties": {
                "timezone": {
                    "type": "string",
                    "description": "The timezone, e.g. America/New_York"
                }
            },
            "required": ["timezone"]
        }
    }
]
# Test conversation with parallel tool calls
messages = [
    {
        "role": "user",
        "content": "What's the weather in SF and NYC, and what time is it there?"
    }
]
# Make initial request
print("Requesting parallel tool calls...")
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=messages,
    tools=tools
)
# Check for parallel tool calls
tool_uses = [block for block in response.content if block.type == "tool_use"]
print(f"\n✓ Claude made {len(tool_uses)} tool calls")
if len(tool_uses) > 1:
    print("✓ Parallel tool calls detected!")
    for tool in tool_uses:
        print(f"  - {tool.name}: {tool.input}")
else:
    print("✗ No parallel tool calls detected")
# Simulate tool execution and format results correctly
tool_results = []
for tool_use in tool_uses:
    if tool_use.name == "get_weather":
        if "San Francisco" in str(tool_use.input):
            result = "San Francisco: 68°F, partly cloudy"
        else:
            result = "New York: 45°F, clear skies"
    else:  # get_time
        if "Los_Angeles" in str(tool_use.input):
            result = "2:30 PM PST"
        else:
            result = "5:30 PM EST"
    tool_results.append({
        "type": "tool_result",
        "tool_use_id": tool_use.id,
        "content": result
    })
# Continue conversation with tool results
messages.extend([
    {"role": "assistant", "content": response.content},
    {"role": "user", "content": tool_results}  # All results in one message!
])
# Get final response
print("\nGetting final response...")
final_response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=messages,
    tools=tools
)
print(f"\nClaude's response:\n{final_response.content[0].text}")
# Verify formatting
print("\n--- Verification ---")
print(f"✓ Tool results sent in single user message: {len(tool_results)} results")
print("✓ No text before tool results in content array")
print("✓ Conversation formatted correctly for future parallel tool use")

```

This script demonstrates:
  * How to properly format parallel tool calls and results
  * How to verify that parallel calls are being made
  * The correct message structure that encourages future parallel tool use
  * Common mistakes to avoid (like text before tool results)

Run this script to test your implementation and ensure Claude is making parallel tool calls effectively.
#### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#maximizing-parallel-tool-use)
Maximizing parallel tool use
While Claude 4 models have excellent parallel tool use capabilities by default, you can increase the likelihood of parallel tool execution across all models with targeted prompting:
System prompts for parallel tool use
For Claude 4 models (Opus 4.1, Opus 4, and Sonnet 4), add this to your system prompt:
Copy
```
For maximum efficiency, whenever you need to perform multiple independent operations, invoke all relevant tools simultaneously rather than sequentially.

```

For even stronger parallel tool use (recommended if the default isn’t sufficient), use:
Copy
```
<use_parallel_tool_calls>
For maximum efficiency, whenever you perform multiple independent operations, invoke all relevant tools simultaneously rather than sequentially. Prioritize calling tools in parallel whenever possible. For example, when reading 3 files, run 3 tool calls in parallel to read all 3 files into context at the same time. When running multiple read-only commands like `ls` or `list_dir`, always run all of the commands in parallel. Err on the side of maximizing parallel tool calls rather than running too many tools sequentially.
</use_parallel_tool_calls>

```

User message prompting
You can also encourage parallel tool use within specific user messages:
Copy
```
# Instead of:
"What's the weather in Paris? Also check London."
# Use:
"Check the weather in Paris and London simultaneously."
# Or be explicit:
"Please use parallel tool calls to get the weather for Paris, London, and Tokyo at the same time."

```

**Parallel tool use with Claude Sonnet 3.7** Claude Sonnet 3.7 may be less likely to make make parallel tool calls in a response, even when you have not set `disable_parallel_tool_use`. To work around this, we recommend enabling [token-efficient tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/token-efficient-tool-use), which helps encourage Claude to use parallel tools. This beta feature also reduces latency and saves an average of 14% in output tokens.If you prefer not to opt into the token-efficient tool use beta, you can also introduce a “batch tool” that can act as a meta-tool to wrap invocations to other tools simultaneously. We find that if this tool is present, the model will use it to simultaneously call multiple tools in parallel for you.See [this example](https://github.com/anthropics/anthropic-cookbook/blob/main/tool_use/parallel_tools_claude_3_7_sonnet.ipynb) in our cookbook for how to use this workaround.
## 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-tool-use-and-tool-result-content-blocks)
Handling tool use and tool result content blocks
**Simpler with Tool runner** : The manual tool handling described in this section is automatically managed by [tool runner](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#tool-runner-beta). Use this section when you need custom control over tool execution.
Claude’s response differs based on whether it uses a client or server tool.
### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-results-from-client-tools)
Handling results from client tools
The response will have a `stop_reason` of `tool_use` and one or more `tool_use` content blocks that include:
  * `id`: A unique identifier for this particular tool use block. This will be used to match up the tool results later.
  * `name`: The name of the tool being used.
  * `input`: An object containing the input being passed to the tool, conforming to the tool’s `input_schema`.


Example API response with a `tool_use` content block
JSON
Copy
```
{
  "id": "msg_01Aq9w938a90dw8q",
  "model": "claude-sonnet-4-5",
  "stop_reason": "tool_use",
  "role": "assistant",
  "content": [
    {
      "type": "text",
      "text": "I'll check the current weather in San Francisco for you."
    },
    {
      "type": "tool_use",
      "id": "toolu_01A09q90qw90lq917835lq9",
      "name": "get_weather",
      "input": {"location": "San Francisco, CA", "unit": "celsius"}
    }
  ]
}

```

When you receive a tool use response for a client tool, you should:
  1. Extract the `name`, `id`, and `input` from the `tool_use` block.
  2. Run the actual tool in your codebase corresponding to that tool name, passing in the tool `input`.
  3. Continue the conversation by sending a new message with the `role` of `user`, and a `content` block containing the `tool_result` type and the following information: 
     * `tool_use_id`: The `id` of the tool use request this is a result for.
     * `content`: The result of the tool, as a string (e.g. `"content": "15 degrees"`), a list of nested content blocks (e.g. `"content": [{"type": "text", "text": "15 degrees"}]`), or a list of document blocks (e.g. `"content": ["type": "document", "source": {"type": "text", "media_type": "text/plain", "data": "15 degrees"}]`). These content blocks can use the `text`, `image`, or `document` types.
     * `is_error` (optional): Set to `true` if the tool execution resulted in an error.


**Important formatting requirements** :
  * Tool result blocks must immediately follow their corresponding tool use blocks in the message history. You cannot include any messages between the assistant’s tool use message and the user’s tool result message.
  * In the user message containing tool results, the tool_result blocks must come FIRST in the content array. Any text must come AFTER all tool results.

For example, this will cause a 400 error:
Copy
```
{"role": "user", "content": [
  {"type": "text", "text": "Here are the results:"},  // ❌ Text before tool_result
  {"type": "tool_result", "tool_use_id": "toolu_01", ...}
]}

```

This is correct:
Copy
```
{"role": "user", "content": [
  {"type": "tool_result", "tool_use_id": "toolu_01", ...},
  {"type": "text", "text": "What should I do next?"}  // ✅ Text after tool_result
]}

```

If you receive an error like “tool_use ids were found without tool_result blocks immediately after”, check that your tool results are formatted correctly.
Example of successful tool result
JSON
Copy
```
{
  "role": "user",
  "content": [
    {
      "type": "tool_result",
      "tool_use_id": "toolu_01A09q90qw90lq917835lq9",
      "content": "15 degrees"
    }
  ]
}

```

Example of tool result with images
JSON
Copy
```
{
  "role": "user",
  "content": [
    {
      "type": "tool_result",
      "tool_use_id": "toolu_01A09q90qw90lq917835lq9",
      "content": [
        {"type": "text", "text": "15 degrees"},
        {
          "type": "image",
          "source": {
            "type": "base64",
            "media_type": "image/jpeg",
            "data": "/9j/4AAQSkZJRg...",
          }
        }
      ]
    }
  ]
}

```

Example of empty tool result
JSON
Copy
```
{
  "role": "user",
  "content": [
    {
      "type": "tool_result",
      "tool_use_id": "toolu_01A09q90qw90lq917835lq9",
    }
  ]
}

```

Example of tool result with documents
JSON
Copy
```
{
  "role": "user",
  "content": [
    {
      "type": "tool_result",
      "tool_use_id": "toolu_01A09q90qw90lq917835lq9",
      "content": [
        {"type": "text", "text": "The weather is"},
        {
          "type": "document",
          "source": {
            "type": "text",
            "media_type": "text/plain",
            "data": "15 degrees"
          }
        }
      ]
    }
  ]
}

```

After receiving the tool result, Claude will use that information to continue generating a response to the original user prompt.
### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-results-from-server-tools)
Handling results from server tools
Claude executes the tool internally and incorporates the results directly into its response without requiring additional user interaction.
**Differences from other APIs** Unlike APIs that separate tool use or use special roles like `tool` or `function`, the Claude API integrates tools directly into the `user` and `assistant` message structure.Messages contain arrays of `text`, `image`, `tool_use`, and `tool_result` blocks. `user` messages include client content and `tool_result`, while `assistant` messages contain AI-generated content and `tool_use`.
### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-the-max-tokens-stop-reason)
Handling the `max_tokens` stop reason
If Claude’s [response is cut off due to hitting the `max_tokens` limit](https://docs.claude.com/en/docs/build-with-claude/handling-stop-reasons#max-tokens), and the truncated response contains an incomplete tool use block, you’ll need to retry the request with a higher `max_tokens` value to get the full tool use.
Python
TypeScript
Copy
```
# Check if response was truncated during tool use
if response.stop_reason == "max_tokens":
    # Check if the last content block is an incomplete tool_use
    last_block = response.content[-1]
    if last_block.type == "tool_use":
        # Send the request with higher max_tokens
        response = client.messages.create(
            model="claude-sonnet-4-5",
            max_tokens=4096,  # Increased limit
            messages=messages,
            tools=tools
        )

```

#### 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-the-pause-turn-stop-reason)
Handling the `pause_turn` stop reason
When using server tools like web search, the API may return a `pause_turn` stop reason, indicating that the API has paused a long-running turn. Here’s how to handle the `pause_turn` stop reason:
Python
TypeScript
Copy
```
import anthropic
client = anthropic.Anthropic()
# Initial request with web search
response = client.messages.create(
    model="claude-3-7-sonnet-latest",
    max_tokens=1024,
    messages=[
        {
            "role": "user",
            "content": "Search for comprehensive information about quantum computing breakthroughs in 2025"
        }
    ],
    tools=[{
        "type": "web_search_20250305",
        "name": "web_search",
        "max_uses": 10
    }]
)
# Check if the response has pause_turn stop reason
if response.stop_reason == "pause_turn":
    # Continue the conversation with the paused content
    messages = [
        {"role": "user", "content": "Search for comprehensive information about quantum computing breakthroughs in 2025"},
        {"role": "assistant", "content": response.content}
    ]
    # Send the continuation request
    continuation = client.messages.create(
        model="claude-3-7-sonnet-latest",
        max_tokens=1024,
        messages=messages,
        tools=[{
            "type": "web_search_20250305",
            "name": "web_search",
            "max_uses": 10
        }]
    )
    print(continuation)
else:
    print(response)

```

When handling `pause_turn`:
  * **Continue the conversation** : Pass the paused response back as-is in a subsequent request to let Claude continue its turn
  * **Modify if needed** : You can optionally modify the content before continuing if you want to interrupt or redirect the conversation
  * **Preserve tool state** : Include the same tools in the continuation request to maintain functionality


## 
[​](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#troubleshooting-errors)
Troubleshooting errors
**Built-in Error Handling** : [Tool runner](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#tool-runner-beta) provide automatic error handling for most common scenarios. This section covers manual error handling for advanced use cases.
There are a few different types of errors that can occur when using tools with Claude:
Tool execution error
If the tool itself throws an error during execution (e.g. a network error when fetching weather data), you can return the error message in the `content` along with `"is_error": true`:
JSON
Copy
```
{
  "role": "user",
  "content": [
    {
      "type": "tool_result",
      "tool_use_id": "toolu_01A09q90qw90lq917835lq9",
      "content": "ConnectionError: the weather service API is not available (HTTP 500)",
      "is_error": true
    }
  ]
}

```

Claude will then incorporate this error into its response to the user, e.g. “I’m sorry, I was unable to retrieve the current weather because the weather service API is not available. Please try again later.”
Invalid tool name
If Claude’s attempted use of a tool is invalid (e.g. missing required parameters), it usually means that the there wasn’t enough information for Claude to use the tool correctly. Your best bet during development is to try the request again with more-detailed `description` values in your tool definitions.However, you can also continue the conversation forward with a `tool_result` that indicates the error, and Claude will try to use the tool again with the missing information filled in:
JSON
Copy
```
{
  "role": "user",
  "content": [
    {
      "type": "tool_result",
      "tool_use_id": "toolu_01A09q90qw90lq917835lq9",
      "content": "Error: Missing required 'location' parameter",
      "is_error": true
    }
  ]
}

```

If a tool request is invalid or missing parameters, Claude will retry 2-3 times with corrections before apologizing to the user.
<search_quality_reflection> tags
To prevent Claude from reflecting on search quality with <search_quality_reflection> tags, add “Do not reflect on the quality of the returned search results in your response” to your prompt.
Server tool errors
When server tools encounter errors (e.g., network issues with Web Search), Claude will transparently handle these errors and attempt to provide an alternative response or explanation to the user. Unlike client tools, you do not need to handle `is_error` results for server tools.For web search specifically, possible error codes include:
  * `too_many_requests`: Rate limit exceeded
  * `invalid_input`: Invalid search query parameter
  * `max_uses_exceeded`: Maximum web search tool uses exceeded
  * `query_too_long`: Query exceeds maximum length
  * `unavailable`: An internal error occurred


Parallel tool calls not working
If Claude isn’t making parallel tool calls when expected, check these common issues:**1. Incorrect tool result formatting** The most common issue is formatting tool results incorrectly in the conversation history. This “teaches” Claude to avoid parallel calls.Specifically for parallel tool use:
  * ❌ **Wrong** : Sending separate user messages for each tool result
  * ✅ **Correct** : All tool results must be in a single user message


Copy
```
// ❌ This reduces parallel tool use
[
  {"role": "assistant", "content": [tool_use_1, tool_use_2]},
  {"role": "user", "content": [tool_result_1]},
  {"role": "user", "content": [tool_result_2]}  // Separate message
]
// ✅ This maintains parallel tool use
[
  {"role": "assistant", "content": [tool_use_1, tool_use_2]},
  {"role": "user", "content": [tool_result_1, tool_result_2]}  // Single message
]

```

See the [general formatting requirements above](https://docs.claude.com/en/docs/agents-and-tools/tool-use/implement-tool-use#handling-tool-use-and-tool-result-content-blocks) for other formatting rules.**2. Weak prompting** Default prompting may not be sufficient. Use stronger language:
Copy
```
<use_parallel_tool_calls>
For maximum efficiency, whenever you perform multiple independent operations,
invoke all relevant tools simultaneously rather than sequentially.
Prioritize calling tools in parallel whenever possible.
</use_parallel_tool_calls>

```

**3. Measuring parallel tool usage** To verify parallel tool calls are working:
Copy
```
# Calculate average tools per tool-calling message
tool_call_messages = [msg for msg in messages if any(
    block.type == "tool_use" for block in msg.content
)]
total_tool_calls = sum(
    len([b for b in msg.content if b.type == "tool_use"])
    for msg in tool_call_messages
)
avg_tools_per_message = total_tool_calls / len(tool_call_messages)
print(f"Average tools per message: {avg_tools_per_message}")
# Should be > 1.0 if parallel calls are working

```

**4. Model-specific behavior**
  * Claude Opus 4.1, Opus 4, and Sonnet 4: Excel at parallel tool use with minimal prompting
  * Claude Sonnet 3.7: May need stronger prompting or [token-efficient tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/token-efficient-tool-use)
  * Claude Haiku: Less likely to use parallel tools without explicit prompting


Was this page helpful?
YesNo
[Overview](https://docs.claude.com/en/docs/agents-and-tools/tool-use/overview)[Token-efficient tool use](https://docs.claude.com/en/docs/agents-and-tools/tool-use/token-efficient-tool-use)
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
