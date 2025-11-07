# Model Context Protocol (MCP)

[Model Context Protocol (MCP)](https://modelcontextprotocol.io/introduction) is an open protocol that standardizes how applications provide tools and context to LLMs. LangChain agents can use tools defined on MCP servers using the [`langchain-mcp-adapters`](https://github.com/langchain-ai/langchain-mcp-adapters) library.

## Install

Install the `langchain-mcp-adapters` library to use MCP tools in LangGraph:

<CodeGroup>
  ```bash pip theme={null}
  pip install langchain-mcp-adapters
  ```

  ```bash uv theme={null}
  uv add langchain-mcp-adapters
  ```
</CodeGroup>

## Transport types

MCP supports different transport mechanisms for client-server communication:

* **stdio** – Client launches server as a subprocess and communicates via standard input/output. Best for local tools and simple setups.
* **Streamable HTTP** – Server runs as an independent process handling HTTP requests. Supports remote connections and multiple clients.
* **Server-Sent Events (SSE)** – a variant of streamable HTTP optimized for real-time streaming communication.

## Use MCP tools

`langchain-mcp-adapters` enables agents to use tools defined across one or more MCP server.

```python Accessing multiple MCP servers icon="server" theme={null}
from langchain_mcp_adapters.client import MultiServerMCPClient  # [!code highlight]
from langchain.agents import create_agent


client = MultiServerMCPClient(  # [!code highlight]
    {
        "math": {
            "transport": "stdio",  # Local subprocess communication
            "command": "python",
            # Absolute path to your math_server.py file
            "args": ["/path/to/math_server.py"],
        },
        "weather": {
            "transport": "streamable_http",  # HTTP-based remote server
            # Ensure you start your weather server on port 8000
            "url": "http://localhost:8000/mcp",
        }
    }
)

tools = await client.get_tools()  # [!code highlight]
agent = create_agent(
    "claude-sonnet-4-5-20250929",
    tools  # [!code highlight]
)
math_response = await agent.ainvoke(
    {"messages": [{"role": "user", "content": "what's (3 + 5) x 12?"}]}
)
weather_response = await agent.ainvoke(
    {"messages": [{"role": "user", "content": "what is the weather in nyc?"}]}
)
```

<Note>
  `MultiServerMCPClient` is **stateless by default**. Each tool invocation creates a fresh MCP `ClientSession`, executes the tool, and then cleans up.
</Note>

## Custom MCP servers

To create your own MCP servers, you can use the `mcp` library. This library provides a simple way to define [tools](https://modelcontextprotocol.io/docs/learn/server-concepts#tools-ai-actions) and run them as servers.

<CodeGroup>
  ```bash pip theme={null}
  pip install mcp
  ```

  ```bash uv theme={null}
  uv add mcp
  ```
</CodeGroup>

Use the following reference implementations to test your agent with MCP tool servers.

```python title="Math server (stdio transport)" icon="floppy-disk" theme={null}
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Math")

@mcp.tool()
def add(a: int, b: int) -> int:
    """Add two numbers"""
    return a + b

@mcp.tool()
def multiply(a: int, b: int) -> int:
    """Multiply two numbers"""
    return a * b

if __name__ == "__main__":
    mcp.run(transport="stdio")
```

```python title="Weather server (streamable HTTP transport)" icon="wifi" theme={null}
from mcp.server.fastmcp import FastMCP

mcp = FastMCP("Weather")

@mcp.tool()
async def get_weather(location: str) -> str:
    """Get weather for location."""
    return "It's always sunny in New York"

if __name__ == "__main__":
    mcp.run(transport="streamable-http")
```

## Stateful tool usage

For stateful servers that maintain context between tool calls, use `client.session()` to create a persistent `ClientSession`.

```python Using MCP ClientSession for stateful tool usage theme={null}
from langchain_mcp_adapters.tools import load_mcp_tools

client = MultiServerMCPClient({...})
async with client.session("math") as session:
    tools = await load_mcp_tools(session)
```

## Additional resources

* [MCP documentation](https://modelcontextprotocol.io/introduction)
* [MCP Transport documentation](https://modelcontextprotocol.io/docs/concepts/transports)
* [`langchain-mcp-adapters`](https://github.com/langchain-ai/langchain-mcp-adapters)

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langchain/mcp.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>

# Human-in-the-loop

The Human-in-the-Loop (HITL) middleware lets you add human oversight to agent tool calls.
When a model proposes an action that might require review — for example, writing to a file or executing SQL — the middleware can pause execution and wait for a decision.

It does this by checking each tool call against a configurable policy. If intervention is needed, the middleware issues an [interrupt](https://reference.langchain.com/python/langgraph/types/#langgraph.types.interrupt) that halts execution. The graph state is saved using LangGraph’s [persistence layer](/oss/python/langgraph/persistence), so execution can pause safely and resume later.

A human decision then determines what happens next: the action can be approved as-is (`approve`), modified before running (`edit`), or rejected with feedback (`reject`).

## Interrupt decision types

The middleware defines three built-in ways a human can respond to an interrupt:

| Decision Type | Description                                                               | Example Use Case                                    |
| ------------- | ------------------------------------------------------------------------- | --------------------------------------------------- |
| ✅ `approve`   | The action is approved as-is and executed without changes.                | Send an email draft exactly as written              |
| ✏️ `edit`     | The tool call is executed with modifications.                             | Change the recipient before sending an email        |
| ❌ `reject`    | The tool call is rejected, with an explanation added to the conversation. | Reject an email draft and explain how to rewrite it |

The available decision types for each tool depend on the policy you configure in `interrupt_on`.
When multiple tool calls are paused at the same time, each action requires a separate decision.
Decisions must be provided in the same order as the actions appear in the interrupt request.

<Tip>
  When **editing** tool arguments, make changes conservatively. Significant modifications to the original arguments may cause the model to re-evaluate its approach and potentially execute the tool multiple times or take unexpected actions.
</Tip>

## Configuring interrupts

To use HITL, add the middleware to the agent’s `middleware` list when creating the agent.

You configure it with a mapping of tool actions to the decision types that are allowed for each action. The middleware will interrupt execution when a tool call matches an action in the mapping.

```python  theme={null}
from langchain.agents import create_agent
from langchain.agents.middleware import HumanInTheLoopMiddleware # [!code highlight]
from langgraph.checkpoint.memory import InMemorySaver # [!code highlight]


agent = create_agent(
    model="gpt-4o",
    tools=[write_file_tool, execute_sql_tool, read_data_tool],
    middleware=[
        HumanInTheLoopMiddleware( # [!code highlight]
            interrupt_on={
                "write_file": True,  # All decisions (approve, edit, reject) allowed
                "execute_sql": {"allowed_decisions": ["approve", "reject"]},  # No editing allowed
                # Safe operation, no approval needed
                "read_data": False,
            },
            # Prefix for interrupt messages - combined with tool name and args to form the full message
            # e.g., "Tool execution pending approval: execute_sql with query='DELETE FROM...'"
            # Individual tools can override this by specifying a "description" in their interrupt config
            description_prefix="Tool execution pending approval",
        ),
    ],
    # Human-in-the-loop requires checkpointing to handle interrupts.
    # In production, use a persistent checkpointer like AsyncPostgresSaver.
    checkpointer=InMemorySaver(),  # [!code highlight]
)
```

<Info>
  You must configure a checkpointer to persist the graph state across interrupts.
  In production, use a persistent checkpointer like [`AsyncPostgresSaver`](https://reference.langchain.com/python/langgraph/checkpoints/#langgraph.checkpoint.postgres.aio.AsyncPostgresSaver). For testing or prototyping, use [`InMemorySaver`](https://reference.langchain.com/python/langgraph/checkpoints/#langgraph.checkpoint.memory.InMemorySaver).

  When invoking the agent, pass a `config` that includes the **thread ID** to associate execution with a conversation thread.
  See the [LangGraph interrupts documentation](/oss/python/langgraph/interrupts) for details.
</Info>

## Responding to interrupts

When you invoke the agent, it runs until it either completes or an interrupt is raised. An interrupt is triggered when a tool call matches the policy you configured in `interrupt_on`. In that case, the invocation result will include an `__interrupt__` field with the actions that require review. You can then present those actions to a reviewer and resume execution once decisions are provided.

```python  theme={null}
from langgraph.types import Command

# Human-in-the-loop leverages LangGraph's persistence layer.
# You must provide a thread ID to associate the execution with a conversation thread,
# so the conversation can be paused and resumed (as is needed for human review).
config = {"configurable": {"thread_id": "some_id"}} # [!code highlight]
# Run the graph until the interrupt is hit.
result = agent.invoke(
    {
        "messages": [
            {
                "role": "user",
                "content": "Delete old records from the database",
            }
        ]
    },
    config=config # [!code highlight]
)

# The interrupt contains the full HITL request with action_requests and review_configs
print(result['__interrupt__'])
# > [
# >    Interrupt(
# >       value={
# >          'action_requests': [
# >             {
# >                'name': 'execute_sql',
# >                'arguments': {'query': 'DELETE FROM records WHERE created_at < NOW() - INTERVAL \'30 days\';'},
# >                'description': 'Tool execution pending approval\n\nTool: execute_sql\nArgs: {...}'
# >             }
# >          ],
# >          'review_configs': [
# >             {
# >                'action_name': 'execute_sql',
# >                'allowed_decisions': ['approve', 'reject']
# >             }
# >          ]
# >       }
# >    )
# > ]


# Resume with approval decision
agent.invoke(
    Command( # [!code highlight]
        resume={"decisions": [{"type": "approve"}]}  # or "edit", "reject" [!code highlight]
    ), # [!code highlight]
    config=config # Same thread ID to resume the paused conversation
)
```

### Decision types

<Tabs>
  <Tab title="✅ approve">
    Use `approve` to approve the tool call as-is and execute it without changes.

    ```python  theme={null}
    agent.invoke(
        Command(
            # Decisions are provided as a list, one per action under review.
            # The order of decisions must match the order of actions
            # listed in the `__interrupt__` request.
            resume={
                "decisions": [
                    {
                        "type": "approve",
                    }
                ]
            }
        ),
        config=config  # Same thread ID to resume the paused conversation
    )
    ```
  </Tab>

  <Tab title="✏️ edit">
    Use `edit` to modify the tool call before execution.
    Provide the edited action with the new tool name and arguments.

    ```python  theme={null}
    agent.invoke(
        Command(
            # Decisions are provided as a list, one per action under review.
            # The order of decisions must match the order of actions
            # listed in the `__interrupt__` request.
            resume={
                "decisions": [
                    {
                        "type": "edit",
                        # Edited action with tool name and args
                        "edited_action": {
                            # Tool name to call.
                            # Will usually be the same as the original action.
                            "name": "new_tool_name",
                            # Arguments to pass to the tool.
                            "args": {"key1": "new_value", "key2": "original_value"},
                        }
                    }
                ]
            }
        ),
        config=config  # Same thread ID to resume the paused conversation
    )
    ```

    <Tip>
      When **editing** tool arguments, make changes conservatively. Significant modifications to the original arguments may cause the model to re-evaluate its approach and potentially execute the tool multiple times or take unexpected actions.
    </Tip>
  </Tab>

  <Tab title="❌ reject">
    Use `reject` to reject the tool call and provide feedback instead of execution.

    ```python  theme={null}
    agent.invoke(
        Command(
            # Decisions are provided as a list, one per action under review.
            # The order of decisions must match the order of actions
            # listed in the `__interrupt__` request.
            resume={
                "decisions": [
                    {
                        "type": "reject",
                        # An explanation about why the action was rejected
                        "message": "No, this is wrong because ..., instead do this ...",
                    }
                ]
            }
        ),
        config=config  # Same thread ID to resume the paused conversation
    )
    ```

    The `message` is added to the conversation as feedback to help the agent understand why the action was rejected and what it should do instead.

    ***

    ### Multiple decisions

    When multiple actions are under review, provide a decision for each action in the same order as they appear in the interrupt:

    ```python  theme={null}
    {
        "decisions": [
            {"type": "approve"},
            {
                "type": "edit",
                "edited_action": {
                    "name": "tool_name",
                    "args": {"param": "new_value"}
                }
            },
            {
                "type": "reject",
                "message": "This action is not allowed"
            }
        ]
    }
    ```
  </Tab>
</Tabs>

## Execution lifecycle

The middleware defines an `after_model` hook that runs after the model generates a response but before any tool calls are executed:

1. The agent invokes the model to generate a response.
2. The middleware inspects the response for tool calls.
3. If any calls require human input, the middleware builds a `HITLRequest` with `action_requests` and `review_configs` and calls [interrupt](https://reference.langchain.com/python/langgraph/types/#langgraph.types.interrupt).
4. The agent waits for human decisions.
5. Based on the `HITLResponse` decisions, the middleware executes approved or edited calls, synthesizes [ToolMessage](https://reference.langchain.com/python/langchain/messages/#langchain.messages.ToolMessage)'s for rejected calls, and resumes execution.

## Custom HITL logic

For more specialized workflows, you can build custom HITL logic directly using the [interrupt](https://reference.langchain.com/python/langgraph/types/#langgraph.types.interrupt) primitive and [middleware](/oss/python/langchain/middleware) abstraction.

Review the [execution lifecycle](#execution-lifecycle) above to understand how to integrate interrupts into the agent's operation.

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langchain/human-in-the-loop.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>
