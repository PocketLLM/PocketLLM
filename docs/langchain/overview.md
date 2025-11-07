# LangChain overview

<Callout icon="bullhorn" color="#DFC5FE" iconType="regular">
  **LangChain v1.0 is now available!**

  For a complete list of changes and instructions on how to upgrade your code, see the [release notes](/oss/python/releases/langchain-v1) and [migration guide](/oss/python/migrate/langchain-v1).

  If you encounter any issues or have feedback, please [open an issue](https://github.com/langchain-ai/docs/issues/new?template=01-langchain.yml) so we can improve. To view v0.x documentation, [go to the archived content](https://github.com/langchain-ai/langchain/tree/v0.3/docs/docs).
</Callout>

LangChain is the easiest way to start building agents and applications powered by LLMs. With under 10 lines of code, you can connect to OpenAI, Anthropic, Google, and [more](/oss/python/integrations/providers/overview). LangChain provides a pre-built agent architecture and model integrations to help you get started quickly and seamlessly incorporate LLMs into your agents and applications.

We recommend you use LangChain if you want to quickly build agents and autonomous applications. Use [LangGraph](/oss/python/langgraph/overview), our low-level agent orchestration framework and runtime, when you have more advanced needs that require a combination of deterministic and agentic workflows, heavy customization, and carefully controlled latency.

LangChain [agents](/oss/python/langchain/agents) are built on top of LangGraph in order to provide durable execution, streaming, human-in-the-loop, persistence, and more. You do not need to know LangGraph for basic LangChain agent usage.

## <Icon icon="download" size={20} /> Install

<CodeGroup>
  ```bash pip theme={null}
  pip install -U langchain
  # Requires Python 3.10+
  ```

  ```bash uv theme={null}
  uv add langchain
  # Requires Python 3.10+
  ```
</CodeGroup>

## <Icon icon="wand-magic-sparkles" /> Create an agent

```python  theme={null}
# pip install -qU "langchain[anthropic]" to call the model

from langchain.agents import create_agent

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="claude-sonnet-4-5-20250929",
    tools=[get_weather],
    system_prompt="You are a helpful assistant",
)

# Run the agent
agent.invoke(
    {"messages": [{"role": "user", "content": "what is the weather in sf"}]}
)
```

## <Icon icon="star" size={20} /> Core benefits

<Columns cols={2}>
  <Card title="Standard model interface" icon="arrows-rotate" href="/oss/python/langchain/models" arrow cta="Learn more">
    Different providers have unique APIs for interacting with models, including the format of responses. LangChain standardizes how you interact with models so that you can seamlessly swap providers and avoid lock-in.
  </Card>

  <Card title="Easy to use, highly flexible agent" icon="wand-magic-sparkles" href="/oss/python/langchain/agents" arrow cta="Learn more">
    LangChain's agent abstraction is designed to be easy to get started with, letting you build a simple agent in under 10 lines of code. But it also provides enough flexibility to allow you to do all the context engineering your heart desires.
  </Card>

  <Card title="Built on top of LangGraph" icon="circle-nodes" href="/oss/python/langgraph/overview" arrow cta="Learn more">
    LangChain's agents are built on top of LangGraph. This allows us to take advantage of LangGraph's durable execution, human-in-the-loop support, persistence, and more.
  </Card>

  <Card title="Debug with LangSmith" icon="eye" href="/langsmith/home" arrow cta="Learn more">
    Gain deep visibility into complex agent behavior with visualization tools that trace execution paths, capture state transitions, and provide detailed runtime metrics.
  </Card>
</Columns>

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langchain/overview.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>


# Install LangChain

To install the LangChain package:

<CodeGroup>
  ```bash pip theme={null}
  pip install -U langchain
  # Requires Python 3.10+
  ```

  ```bash uv theme={null}
  uv add langchain
  # Requires Python 3.10+
  ```
</CodeGroup>

LangChain provides integrations to hundreds of LLMs and thousands of other integrations. These live in independent provider packages. For example:

<CodeGroup>
  ```bash pip theme={null}
  # Installing the OpenAI integration
  pip install -U langchain-openai

  # Installing the Anthropic integration
  pip install -U langchain-anthropic
  ```

  ```bash uv theme={null}
  # Installing the OpenAI integration
  uv add langchain-openai

  # Installing the Anthropic integration
  uv add langchain-anthropic
  ```
</CodeGroup>

<Tip>
  See the [Integrations tab](/oss/python/integrations/providers/overview) for a full list of available integrations.
</Tip>

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langchain/install.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>

# Quickstart

This quickstart takes you from a simple setup to a fully functional AI agent in just a few minutes.

## Build a basic agent

Start by creating a simple agent that can answer questions and call tools. The agent will use Claude Sonnet 4.5 as its language model, a basic weather function as a tool, and a simple prompt to guide its behavior.

<Info>
  For this example, you will need to set up a [Claude (Anthropic)](https://www.anthropic.com/) account and get an API key. Then, set the `ANTHROPIC_API_KEY` environment variable in your terminal.
</Info>

```python  theme={null}
from langchain.agents import create_agent

def get_weather(city: str) -> str:
    """Get weather for a given city."""
    return f"It's always sunny in {city}!"

agent = create_agent(
    model="claude-sonnet-4-5-20250929",
    tools=[get_weather],
    system_prompt="You are a helpful assistant",
)

# Run the agent
agent.invoke(
    {"messages": [{"role": "user", "content": "what is the weather in sf"}]}
)
```

<Tip>
  To learn how to trace your agent with LangSmith, see the [LangSmith documentation](/langsmith/trace-with-langchain).
</Tip>

## Build a real-world agent

Next, build a practical weather forecasting agent that demonstrates key production concepts:

1. **Detailed system prompts** for better agent behavior
2. **Create tools** that integrate with external data
3. **Model configuration** for consistent responses
4. **Structured output** for predictable results
5. **Conversational memory** for chat-like interactions
6. **Create and run the agent** create a fully functional agent

Let's walk through each step:

<Steps>
  <Step title="Define the system prompt">
    The system prompt defines your agent’s role and behavior. Keep it specific and actionable:

    ```python wrap theme={null}
    SYSTEM_PROMPT = """You are an expert weather forecaster, who speaks in puns.

    You have access to two tools:

    - get_weather_for_location: use this to get the weather for a specific location
    - get_user_location: use this to get the user's location

    If a user asks you for the weather, make sure you know the location. If you can tell from the question that they mean wherever they are, use the get_user_location tool to find their location."""
    ```
  </Step>

  <Step title="Create tools">
    [Tools](/oss/python/langchain/tools) let a model interact with external systems by calling functions you define.
    Tools can depend on [runtime context](/oss/python/langchain/runtime) and also interact with [agent memory](/oss/python/langchain/short-term-memory).

    Notice below how the `get_user_location` tool uses runtime context:

    ```python  theme={null}
    from dataclasses import dataclass
    from langchain.tools import tool, ToolRuntime

    @tool
    def get_weather_for_location(city: str) -> str:
        """Get weather for a given city."""
        return f"It's always sunny in {city}!"

    @dataclass
    class Context:
        """Custom runtime context schema."""
        user_id: str

    @tool
    def get_user_location(runtime: ToolRuntime[Context]) -> str:
        """Retrieve user information based on user ID."""
        user_id = runtime.context.user_id
        return "Florida" if user_id == "1" else "SF"
    ```

    <Tip>
      Tools should be well-documented: their name, description, and argument names become part of the model's prompt.
      LangChain's [`@tool` decorator](https://reference.langchain.com/python/langchain/tools/#langchain.tools.tool) adds metadata and enables runtime injection via the `ToolRuntime` parameter.
    </Tip>
  </Step>

  <Step title="Configure your model">
    Set up your [language model](/oss/python/langchain/models) with the right [parameters](/oss/python/langchain/models#parameters) for your use case:

    ```python  theme={null}
    from langchain.chat_models import init_chat_model

    model = init_chat_model(
        "claude-sonnet-4-5-20250929",
        temperature=0.5,
        timeout=10,
        max_tokens=1000
    )
    ```
  </Step>

  <Step title="Define response format">
    Optionally, define a structured response format if you need the agent responses to match
    a specific schema.

    ```python  theme={null}
    from dataclasses import dataclass

    # We use a dataclass here, but Pydantic models are also supported.
    @dataclass
    class ResponseFormat:
        """Response schema for the agent."""
        # A punny response (always required)
        punny_response: str
        # Any interesting information about the weather if available
        weather_conditions: str | None = None
    ```
  </Step>

  <Step title="Add memory">
    Add [memory](/oss/python/langchain/short-term-memory) to your agent to maintain state across interactions. This allows
    the agent to remember previous conversations and context.

    ```python  theme={null}
    from langgraph.checkpoint.memory import InMemorySaver

    checkpointer = InMemorySaver()
    ```

    <Info>
      In production, use a persistent checkpointer that saves to a database.
      See [Add and manage memory](/oss/python/langgraph/add-memory#manage-short-term-memory) for more details.
    </Info>
  </Step>

  <Step title="Create and run the agent">
    Now assemble your agent with all the components and run it!

    ```python  theme={null}
    agent = create_agent(
        model=model,
        system_prompt=SYSTEM_PROMPT,
        tools=[get_user_location, get_weather_for_location],
        context_schema=Context,
        response_format=ResponseFormat,
        checkpointer=checkpointer
    )

    # `thread_id` is a unique identifier for a given conversation.
    config = {"configurable": {"thread_id": "1"}}

    response = agent.invoke(
        {"messages": [{"role": "user", "content": "what is the weather outside?"}]},
        config=config,
        context=Context(user_id="1")
    )

    print(response['structured_response'])
    # ResponseFormat(
    #     punny_response="Florida is still having a 'sun-derful' day! The sunshine is playing 'ray-dio' hits all day long! I'd say it's the perfect weather for some 'solar-bration'! If you were hoping for rain, I'm afraid that idea is all 'washed up' - the forecast remains 'clear-ly' brilliant!",
    #     weather_conditions="It's always sunny in Florida!"
    # )


    # Note that we can continue the conversation using the same `thread_id`.
    response = agent.invoke(
        {"messages": [{"role": "user", "content": "thank you!"}]},
        config=config,
        context=Context(user_id="1")
    )

    print(response['structured_response'])
    # ResponseFormat(
    #     punny_response="You're 'thund-erfully' welcome! It's always a 'breeze' to help you stay 'current' with the weather. I'm just 'cloud'-ing around waiting to 'shower' you with more forecasts whenever you need them. Have a 'sun-sational' day in the Florida sunshine!",
    #     weather_conditions=None
    # )
    ```
  </Step>
</Steps>

<Expandable title="Full example code">
  ```python  theme={null}
  from dataclasses import dataclass

  from langchain.agents import create_agent
  from langchain.chat_models import init_chat_model
  from langchain.tools import tool, ToolRuntime
  from langgraph.checkpoint.memory import InMemorySaver


  # Define system prompt
  SYSTEM_PROMPT = """You are an expert weather forecaster, who speaks in puns.

  You have access to two tools:

  - get_weather_for_location: use this to get the weather for a specific location
  - get_user_location: use this to get the user's location

  If a user asks you for the weather, make sure you know the location. If you can tell from the question that they mean wherever they are, use the get_user_location tool to find their location."""

  # Define context schema
  @dataclass
  class Context:
      """Custom runtime context schema."""
      user_id: str

  # Define tools
  @tool
  def get_weather_for_location(city: str) -> str:
      """Get weather for a given city."""
      return f"It's always sunny in {city}!"

  @tool
  def get_user_location(runtime: ToolRuntime[Context]) -> str:
      """Retrieve user information based on user ID."""
      user_id = runtime.context.user_id
      return "Florida" if user_id == "1" else "SF"

  # Configure model
  model = init_chat_model(
      "claude-sonnet-4-5-20250929",
      temperature=0
  )

  # Define response format
  @dataclass
  class ResponseFormat:
      """Response schema for the agent."""
      # A punny response (always required)
      punny_response: str
      # Any interesting information about the weather if available
      weather_conditions: str | None = None

  # Set up memory
  checkpointer = InMemorySaver()

  # Create agent
  agent = create_agent(
      model=model,
      system_prompt=SYSTEM_PROMPT,
      tools=[get_user_location, get_weather_for_location],
      context_schema=Context,
      response_format=ResponseFormat,
      checkpointer=checkpointer
  )

  # Run agent
  # `thread_id` is a unique identifier for a given conversation.
  config = {"configurable": {"thread_id": "1"}}

  response = agent.invoke(
      {"messages": [{"role": "user", "content": "what is the weather outside?"}]},
      config=config,
      context=Context(user_id="1")
  )

  print(response['structured_response'])
  # ResponseFormat(
  #     punny_response="Florida is still having a 'sun-derful' day! The sunshine is playing 'ray-dio' hits all day long! I'd say it's the perfect weather for some 'solar-bration'! If you were hoping for rain, I'm afraid that idea is all 'washed up' - the forecast remains 'clear-ly' brilliant!",
  #     weather_conditions="It's always sunny in Florida!"
  # )


  # Note that we can continue the conversation using the same `thread_id`.
  response = agent.invoke(
      {"messages": [{"role": "user", "content": "thank you!"}]},
      config=config,
      context=Context(user_id="1")
  )

  print(response['structured_response'])
  # ResponseFormat(
  #     punny_response="You're 'thund-erfully' welcome! It's always a 'breeze' to help you stay 'current' with the weather. I'm just 'cloud'-ing around waiting to 'shower' you with more forecasts whenever you need them. Have a 'sun-sational' day in the Florida sunshine!",
  #     weather_conditions=None
  # )
  ```
</Expandable>

<Tip>
  To learn how to trace your agent with LangSmith, see the [LangSmith documentation](/langsmith/trace-with-langchain).
</Tip>

Congratulations! You now have an AI agent that can:

* **Understand context** and remember conversations
* **Use multiple tools** intelligently
* **Provide structured responses** in a consistent format
* **Handle user-specific information** through context
* **Maintain conversation state** across interactions

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langchain/quickstart.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>
