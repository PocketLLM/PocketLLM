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

# Thinking in LangGraph

> Learn how to think about building agents with LangGraph by breaking down a customer support email agent into discrete steps

LangGraph can change how you think about the agents you build. When you build an agent with LangGraph, you will first break it apart into discrete steps called **nodes**. Then, you will describe the different decisions and transitions for each of your nodes. Finally, you will connect your nodes together through a shared **state** that each node can read from and write to. In this tutorial, we'll guide you through the thought process of building a customer support email agent with LangGraph.

## Start with the process you want to automate

Imagine that you need to build an AI agent that handles customer support emails. Your product team has given you these requirements:

The agent should:

* Read incoming customer emails
* Classify them by urgency and topic
* Search relevant documentation to answer questions
* Draft appropriate responses
* Escalate complex issues to human agents
* Schedule follow-ups when needed

Example scenarios to handle:

1. Simple product question: "How do I reset my password?"
2. Bug report: "The export feature crashes when I select PDF format"
3. Urgent billing issue: "I was charged twice for my subscription!"
4. Feature request: "Can you add dark mode to the mobile app?"
5. Complex technical issue: "Our API integration fails intermittently with 504 errors"

To implement an agent in LangGraph, you will usually follow the same five steps.

## Step 1: Map out your workflow as discrete steps

Start by identifying the distinct steps in your process. Each step will become a **node** (a function that does one specific thing). Then sketch how these steps connect to each other.

```mermaid  theme={null}
flowchart TD
    A[START] --> B[Read Email]
    B --> C[Classify Intent]

    C -.-> D[Doc Search]
    C -.-> E[Bug Track]
    C -.-> F[Human Review]

    D --> G[Draft Reply]
    E --> G
    F --> G

    G -.-> H[Human Review]
    G -.-> I[Send Reply]

    H --> J[END]
    I --> J[END]
```

The arrows show possible paths, but the actual decision of which path to take happens inside each node.

Now that you've identified the components in your workflow, let's understand what each node needs to do:

* Read Email: Extract and parse the email content
* Classify Intent: Use an LLM to categorize urgency and topic, then route to appropriate action
* Doc Search: Query your knowledge base for relevant information
* Bug Track: Create or update issue in tracking system
* Draft Reply: Generate an appropriate response
* Human Review: Escalate to human agent for approval or handling
* Send Reply: Dispatch the email response

<Tip>
  Notice that some nodes make decisions about where to go next (Classify Intent, Draft Reply, Human Review), while others always proceed to the same next step (Read Email always goes to Classify Intent, Doc Search always goes to Draft Reply).
</Tip>

## Step 2: Identify what each step needs to do

For each node in your graph, determine what type of operation it represents and what context it needs to work properly.

<CardGroup cols={2}>
  <Card title="LLM Steps" icon="brain" href="#llm-steps">
    Use when you need to understand, analyze, generate text, or make reasoning decisions
  </Card>

  <Card title="Data Steps" icon="database" href="#data-steps">
    Use when you need to retrieve information from external sources
  </Card>

  <Card title="Action Steps" icon="bolt" href="#action-steps">
    Use when you need to perform external actions
  </Card>

  <Card title="User Input Steps" icon="user" href="#user-input-steps">
    Use when you need human intervention
  </Card>
</CardGroup>

### LLM Steps

When a step needs to understand, analyze, generate text, or make reasoning decisions:

<AccordionGroup>
  <Accordion title="Classify Intent Node">
    * Static context (prompt): Classification categories, urgency definitions, response format
    * Dynamic context (from state): Email content, sender information
    * Desired outcome: Structured classification that determines routing
  </Accordion>

  <Accordion title="Draft Reply Node">
    * Static context (prompt): Tone guidelines, company policies, response templates
    * Dynamic context (from state): Classification results, search results, customer history
    * Desired outcome: Professional email response ready for review
  </Accordion>
</AccordionGroup>

### Data Steps

When a step needs to retrieve information from external sources:

<AccordionGroup>
  <Accordion title="Document Search Node">
    * Parameters: Query built from intent and topic
    * Retry strategy: Yes, with exponential backoff for transient failures
    * Caching: Could cache common queries to reduce API calls
  </Accordion>

  <Accordion title="Customer History Lookup">
    * Parameters: Customer email or ID from state
    * Retry strategy: Yes, but with fallback to basic info if unavailable
    * Caching: Yes, with time-to-live to balance freshness and performance
  </Accordion>
</AccordionGroup>

### Action Steps

When a step needs to perform an external action:

<AccordionGroup>
  <Accordion title="Send Reply Node">
    * When to execute: After approval (human or automated)
    * Retry strategy: Yes, with exponential backoff for network issues
    * Should not cache: Each send is a unique action
  </Accordion>

  <Accordion title="Bug Track Node">
    * When to execute: Always when intent is "bug"
    * Retry strategy: Yes, critical to not lose bug reports
    * Returns: Ticket ID to include in response
  </Accordion>
</AccordionGroup>

### User Input Steps

When a step needs human intervention:

<AccordionGroup>
  <Accordion title="Human Review Node">
    * Context for decision: Original email, draft response, urgency, classification
    * Expected input format: Approval boolean plus optional edited response
    * When triggered: High urgency, complex issues, or quality concerns
  </Accordion>
</AccordionGroup>

## Step 3: Design your state

State is the shared [memory](/oss/python/concepts/memory) accessible to all nodes in your agent. Think of it as the notebook your agent uses to keep track of everything it learns and decides as it works through the process.

### What belongs in state?

Ask yourself these questions about each piece of data:

<CardGroup cols={2}>
  <Card title="Include in State" icon="check">
    Does it need to persist across steps? If yes, it goes in state.
  </Card>

  <Card title="Don't Store" icon="code">
    Can you derive it from other data? If yes, compute it when needed instead of storing it in state.
  </Card>
</CardGroup>

For our email agent, we need to track:

* The original email and sender info (can't reconstruct these)
* Classification results (needed by multiple downstream nodes)
* Search results and customer data (expensive to re-fetch)
* The draft response (needs to persist through review)
* Execution metadata (for debugging and recovery)

### Keep state raw, format prompts on-demand

<Tip>
  A key principle: your state should store raw data, not formatted text. Format prompts inside nodes when you need them.
</Tip>

This separation means:

* Different nodes can format the same data differently for their needs
* You can change prompt templates without modifying your state schema
* Debugging is clearer - you see exactly what data each node received
* Your agent can evolve without breaking existing state

Let's define our state:

```python  theme={null}
from typing import TypedDict, Literal

# Define the structure for email classification
class EmailClassification(TypedDict):
    intent: Literal["question", "bug", "billing", "feature", "complex"]
    urgency: Literal["low", "medium", "high", "critical"]
    topic: str
    summary: str

class EmailAgentState(TypedDict):
    # Raw email data
    email_content: str
    sender_email: str
    email_id: str

    # Classification result
    classification: EmailClassification | None

    # Raw search/API results
    search_results: list[str] | None  # List of raw document chunks
    customer_history: dict | None  # Raw customer data from CRM

    # Generated content
    draft_response: str | None
    messages: list[str] | None
```

Notice that the state contains only raw data - no prompt templates, no formatted strings, no instructions. The classification output is stored as a single dictionary, straight from the LLM.

## Step 4: Build your nodes

Now we implement each step as a function. A node in LangGraph is just a Python function that takes the current state and returns updates to it.

### Handle errors appropriately

Different errors need different handling strategies:

| Error Type                                                      | Who Fixes It       | Strategy                           | When to Use                                      |
| --------------------------------------------------------------- | ------------------ | ---------------------------------- | ------------------------------------------------ |
| Transient errors (network issues, rate limits)                  | System (automatic) | Retry policy                       | Temporary failures that usually resolve on retry |
| LLM-recoverable errors (tool failures, parsing issues)          | LLM                | Store error in state and loop back | LLM can see the error and adjust its approach    |
| User-fixable errors (missing information, unclear instructions) | Human              | Pause with `interrupt()`           | Need user input to proceed                       |
| Unexpected errors                                               | Developer          | Let them bubble up                 | Unknown issues that need debugging               |

<Tabs>
  <Tab title="Transient errors" icon="rotate">
    Add a retry policy to automatically retry network issues and rate limits:

    ```python  theme={null}
    from langgraph.types import RetryPolicy

    workflow.add_node(
        "search_documentation",
        search_documentation,
        retry_policy=RetryPolicy(max_attempts=3, initial_interval=1.0)
    )
    ```
  </Tab>

  <Tab title="LLM-recoverable" icon="brain">
    Store the error in state and loop back so the LLM can see what went wrong and try again:

    ```python  theme={null}
    from langgraph.types import Command


    def execute_tool(state: State) -> Command[Literal["agent", "execute_tool"]]:
        try:
            result = run_tool(state['tool_call'])
            return Command(update={"tool_result": result}, goto="agent")
        except ToolError as e:
            # Let the LLM see what went wrong and try again
            return Command(
                update={"tool_result": f"Tool error: {str(e)}"},
                goto="agent"
            )
    ```
  </Tab>

  <Tab title="User-fixable" icon="user">
    Pause and collect information from the user when needed (like account IDs, order numbers, or clarifications):

    ```python  theme={null}
    from langgraph.types import Command


    def lookup_customer_history(state: State) -> Command[Literal["draft_response"]]:
        if not state.get('customer_id'):
            user_input = interrupt({
                "message": "Customer ID needed",
                "request": "Please provide the customer's account ID to look up their subscription history"
            })
            return Command(
                update={"customer_id": user_input['customer_id']},
                goto="lookup_customer_history"
            )
        # Now proceed with the lookup
        customer_data = fetch_customer_history(state['customer_id'])
        return Command(update={"customer_history": customer_data}, goto="draft_response")
    ```
  </Tab>

  <Tab title="Unexpected" icon="triangle-exclamation">
    Let them bubble up for debugging. Don't catch what you can't handle:

    ```python  theme={null}
    def send_reply(state: EmailAgentState):
        try:
            email_service.send(state["draft_response"])
        except Exception:
            raise  # Surface unexpected errors
    ```
  </Tab>
</Tabs>

### Implementing our email agent nodes

We'll implement each node as a simple function. Remember: nodes take state, do work, and return updates.

<AccordionGroup>
  <Accordion title="Read and classify nodes" icon="brain">
    ```python  theme={null}
    from typing import Literal
    from langgraph.graph import StateGraph, START, END
    from langgraph.types import interrupt, Command, RetryPolicy
    from langchain_openai import ChatOpenAI
    from langchain_core.messages import HumanMessage

    llm = ChatOpenAI(model="gpt-4")

    def read_email(state: EmailAgentState) -> dict:
        """Extract and parse email content"""
        # In production, this would connect to your email service
        return {
            "messages": [HumanMessage(content=f"Processing email: {state['email_content']}")]
        }

    def classify_intent(state: EmailAgentState) -> Command[Literal["search_documentation", "human_review", "draft_response", "bug_tracking"]]:
        """Use LLM to classify email intent and urgency, then route accordingly"""

        # Create structured LLM that returns EmailClassification dict
        structured_llm = llm.with_structured_output(EmailClassification)

        # Format the prompt on-demand, not stored in state
        classification_prompt = f"""
        Analyze this customer email and classify it:

        Email: {state['email_content']}
        From: {state['sender_email']}

        Provide classification including intent, urgency, topic, and summary.
        """

        # Get structured response directly as dict
        classification = structured_llm.invoke(classification_prompt)

        # Determine next node based on classification
        if classification['intent'] == 'billing' or classification['urgency'] == 'critical':
            goto = "human_review"
        elif classification['intent'] in ['question', 'feature']:
            goto = "search_documentation"
        elif classification['intent'] == 'bug':
            goto = "bug_tracking"
        else:
            goto = "draft_response"

        # Store classification as a single dict in state
        return Command(
            update={"classification": classification},
            goto=goto
        )
    ```
  </Accordion>

  <Accordion title="Search and tracking nodes" icon="database">
    ```python  theme={null}
    def search_documentation(state: EmailAgentState) -> Command[Literal["draft_response"]]:
        """Search knowledge base for relevant information"""

        # Build search query from classification
        classification = state.get('classification', {})
        query = f"{classification.get('intent', '')} {classification.get('topic', '')}"

        try:
            # Implement your search logic here
            # Store raw search results, not formatted text
            search_results = [
                "Reset password via Settings > Security > Change Password",
                "Password must be at least 12 characters",
                "Include uppercase, lowercase, numbers, and symbols"
            ]
        except SearchAPIError as e:
            # For recoverable search errors, store error and continue
            search_results = [f"Search temporarily unavailable: {str(e)}"]

        return Command(
            update={"search_results": search_results},  # Store raw results or error
            goto="draft_response"
        )

    def bug_tracking(state: EmailAgentState) -> Command[Literal["draft_response"]]:
        """Create or update bug tracking ticket"""

        # Create ticket in your bug tracking system
        ticket_id = "BUG-12345"  # Would be created via API

        return Command(
            update={
                "search_results": [f"Bug ticket {ticket_id} created"],
                "current_step": "bug_tracked"
            },
            goto="draft_response"
        )
    ```
  </Accordion>

  <Accordion title="Response nodes" icon="pen-to-square">
    ```python  theme={null}
    def draft_response(state: EmailAgentState) -> Command[Literal["human_review", "send_reply"]]:
        """Generate response using context and route based on quality"""

        classification = state.get('classification', {})

        # Format context from raw state data on-demand
        context_sections = []

        if state.get('search_results'):
            # Format search results for the prompt
            formatted_docs = "\n".join([f"- {doc}" for doc in state['search_results']])
            context_sections.append(f"Relevant documentation:\n{formatted_docs}")

        if state.get('customer_history'):
            # Format customer data for the prompt
            context_sections.append(f"Customer tier: {state['customer_history'].get('tier', 'standard')}")

        # Build the prompt with formatted context
        draft_prompt = f"""
        Draft a response to this customer email:
        {state['email_content']}

        Email intent: {classification.get('intent', 'unknown')}
        Urgency level: {classification.get('urgency', 'medium')}

        {chr(10).join(context_sections)}

        Guidelines:
        - Be professional and helpful
        - Address their specific concern
        - Use the provided documentation when relevant
        """

        response = llm.invoke(draft_prompt)

        # Determine if human review needed based on urgency and intent
        needs_review = (
            classification.get('urgency') in ['high', 'critical'] or
            classification.get('intent') == 'complex'
        )

        # Route to appropriate next node
        goto = "human_review" if needs_review else "send_reply"

        return Command(
            update={"draft_response": response.content},  # Store only the raw response
            goto=goto
        )

    def human_review(state: EmailAgentState) -> Command[Literal["send_reply", END]]:
        """Pause for human review using interrupt and route based on decision"""

        classification = state.get('classification', {})

        # interrupt() must come first - any code before it will re-run on resume
        human_decision = interrupt({
            "email_id": state.get('email_id',''),
            "original_email": state.get('email_content',''),
            "draft_response": state.get('draft_response',''),
            "urgency": classification.get('urgency'),
            "intent": classification.get('intent'),
            "action": "Please review and approve/edit this response"
        })

        # Now process the human's decision
        if human_decision.get("approved"):
            return Command(
                update={"draft_response": human_decision.get("edited_response", state.get('draft_response',''))},
                goto="send_reply"
            )
        else:
            # Rejection means human will handle directly
            return Command(update={}, goto=END)

    def send_reply(state: EmailAgentState) -> dict:
        """Send the email response"""
        # Integrate with email service
        print(f"Sending reply: {state['draft_response'][:100]}...")
        return {}
    ```
  </Accordion>
</AccordionGroup>

## Step 5: Wire it together

Now we connect our nodes into a working graph. Since our nodes handle their own routing decisions, we only need a few essential edges.

To enable [human-in-the-loop](/oss/python/langgraph/interrupts) with `interrupt()`, we need to compile with a [checkpointer](/oss/python/langgraph/persistence) to save state between runs:

<Accordion title="Graph compilation code" icon="diagram-project" defaultOpen={true}>
  ```python  theme={null}
  from langgraph.checkpoint.memory import MemorySaver
  from langgraph.types import RetryPolicy

  # Create the graph
  workflow = StateGraph(EmailAgentState)

  # Add nodes with appropriate error handling
  workflow.add_node("read_email", read_email)
  workflow.add_node("classify_intent", classify_intent)

  # Add retry policy for nodes that might have transient failures
  workflow.add_node(
      "search_documentation",
      search_documentation,
      retry_policy=RetryPolicy(max_attempts=3)
  )
  workflow.add_node("bug_tracking", bug_tracking)
  workflow.add_node("draft_response", draft_response)
  workflow.add_node("human_review", human_review)
  workflow.add_node("send_reply", send_reply)

  # Add only the essential edges
  workflow.add_edge(START, "read_email")
  workflow.add_edge("read_email", "classify_intent")
  workflow.add_edge("send_reply", END)

  # Compile with checkpointer for persistence, in case run graph with Local_Server --> Please compile without checkpointer
  memory = MemorySaver()
  app = workflow.compile(checkpointer=memory)
  ```
</Accordion>

The graph structure is minimal because routing happens inside nodes through [`Command`](https://reference.langchain.com/python/langgraph/types/#langgraph.types.Command) objects. Each node declares where it can go using type hints like `Command[Literal["node1", "node2"]]`, making the flow explicit and traceable.

### Try out your agent

Let's run our agent with an urgent billing issue that needs human review:

<Accordion title="Testing the agent" icon="flask">
  ```python  theme={null}
  # Test with an urgent billing issue
  initial_state = {
      "email_content": "I was charged twice for my subscription! This is urgent!",
      "sender_email": "customer@example.com",
      "email_id": "email_123",
      "messages": []
  }

  # Run with a thread_id for persistence
  config = {"configurable": {"thread_id": "customer_123"}}
  result = app.invoke(initial_state, config)
  # The graph will pause at human_review
  print(f"Draft ready for review: {result['draft_response'][:100]}...")

  # When ready, provide human input to resume
  from langgraph.types import Command

  human_response = Command(
      resume={
          "approved": True,
          "edited_response": "We sincerely apologize for the double charge. I've initiated an immediate refund..."
      }
  )

  # Resume execution
  final_result = app.invoke(human_response, config)
  print(f"Email sent successfully!")
  ```
</Accordion>

The graph pauses when it hits `interrupt()`, saves everything to the checkpointer, and waits. It can resume days later, picking up exactly where it left off. The `thread_id` ensures all state for this conversation is preserved together.

## Summary and next steps

### Key Insights

Building this email agent has shown us the LangGraph way of thinking:

<CardGroup cols={2}>
  <Card title="Break into discrete steps" icon="sitemap" href="#step-1-map-out-your-workflow-as-discrete-steps">
    Each node does one thing well. This decomposition enables streaming progress updates, durable execution that can pause and resume, and clear debugging since you can inspect state between steps.
  </Card>

  <Card title="State is shared memory" icon="database" href="#step-3-design-your-state">
    Store raw data, not formatted text. This lets different nodes use the same information in different ways.
  </Card>

  <Card title="Nodes are functions" icon="code" href="#step-4-build-your-nodes">
    They take state, do work, and return updates. When they need to make routing decisions, they specify both the state updates and the next destination.
  </Card>

  <Card title="Errors are part of the flow" icon="triangle-exclamation" href="#handle-errors-appropriately">
    Transient failures get retries, LLM-recoverable errors loop back with context, user-fixable problems pause for input, and unexpected errors bubble up for debugging.
  </Card>

  <Card title="Human input is first-class" icon="user" href="/oss/python/langgraph/interrupts">
    The `interrupt()` function pauses execution indefinitely, saves all state, and resumes exactly where it left off when you provide input. When combined with other operations in a node, it must come first.
  </Card>

  <Card title="Graph structure emerges naturally" icon="diagram-project" href="#step-5-wire-it-together">
    You define the essential connections, and your nodes handle their own routing logic. This keeps control flow explicit and traceable - you can always understand what your agent will do next by looking at the current node.
  </Card>
</CardGroup>

### Advanced considerations

<Accordion title="Node granularity trade-offs" icon="sliders">
  <Info>
    This section explores the trade-offs in node granularity design. Most applications can skip this and use the patterns shown above.
  </Info>

  You might wonder: why not combine `Read Email` and `Classify Intent` into one node?

  Or why separate Doc Search from Draft Reply?

  The answer involves trade-offs between resilience and observability.

  **The resilience consideration:** LangGraph's [durable execution](/oss/python/langgraph/durable-execution) creates checkpoints at node boundaries. When a workflow resumes after an interruption or failure, it starts from the beginning of the node where execution stopped. Smaller nodes mean more frequent checkpoints, which means less work to repeat if something goes wrong. If you combine multiple operations into one large node, a failure near the end means re-executing everything from the start of that node.

  Why we chose this breakdown for the email agent:

  * **Isolation of external services:** Doc Search and Bug Track are separate nodes because they call external APIs. If the search service is slow or fails, we want to isolate that from the LLM calls. We can add retry policies to these specific nodes without affecting others.

  * **Intermediate visibility:** Having `Classify Intent` as its own node lets us inspect what the LLM decided before taking action. This is valuable for debugging and monitoring—you can see exactly when and why the agent routes to human review.

  * **Different failure modes:** LLM calls, database lookups, and email sending have different retry strategies. Separate nodes let you configure these independently.

  * **Reusability and testing:** Smaller nodes are easier to test in isolation and reuse in other workflows.

  A different valid approach: You could combine `Read Email` and `Classify Intent` into a single node. You'd lose the ability to inspect the raw email before classification and would repeat both operations on any failure in that node. For most applications, the observability and debugging benefits of separate nodes are worth the trade-off.

  Application-level concerns: The caching discussion in Step 2 (whether to cache search results) is an application-level decision, not a LangGraph framework feature. You implement caching within your node functions based on your specific requirements—LangGraph doesn't prescribe this.

  Performance considerations: More nodes doesn't mean slower execution. LangGraph writes checkpoints in the background by default ([async durability mode](/oss/python/langgraph/durable-execution#durability-modes)), so your graph continues running without waiting for checkpoints to complete. This means you get frequent checkpoints with minimal performance impact. You can adjust this behavior if needed—use `"exit"` mode to checkpoint only at completion, or `"sync"` mode to block execution until each checkpoint is written.
</Accordion>

### Where to go from here

This was an introduction to thinking about building agents with LangGraph. You can extend this foundation with:

<CardGroup cols={2}>
  <Card title="Human-in-the-loop patterns" icon="user-check" href="/oss/python/langgraph/interrupts">
    Learn how to add tool approval before execution, batch approval, and other patterns
  </Card>

  <Card title="Subgraphs" icon="diagram-nested" href="/oss/python/langgraph/use-subgraphs">
    Create subgraphs for complex multi-step operations
  </Card>

  <Card title="Streaming" icon="tower-broadcast" href="/oss/python/langgraph/streaming">
    Add streaming to show real-time progress to users
  </Card>

  <Card title="Observability" icon="chart-line" href="/oss/python/langgraph/observability">
    Add observability with LangSmith for debugging and monitoring
  </Card>

  <Card title="Tool Integration" icon="wrench" href="/oss/python/langchain/tools">
    Integrate more tools for web search, database queries, and API calls
  </Card>

  <Card title="Retry Logic" icon="rotate" href="/oss/python/langgraph/use-graph-api#add-retry-policies">
    Implement retry logic with exponential backoff for failed operations
  </Card>
</CardGroup>

***

<Callout icon="pen-to-square" iconType="regular">
  [Edit the source of this page on GitHub.](https://github.com/langchain-ai/docs/edit/main/src/oss/langgraph/thinking-in-langgraph.mdx)
</Callout>

<Tip icon="terminal" iconType="regular">
  [Connect these docs programmatically](/use-these-docs) to Claude, VSCode, and more via MCP for    real-time answers.
</Tip>
