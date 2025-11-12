Classifiers Endpoints
Classifiers API.

Toggle themeWall AssetsCat FrameLampCat ToyLamp LightDeskChairOrange Cat IdleLamp LightScreenScreen LightLamp Light Large
Examples
Real world code examples

Moderations


POST
 /v1/moderations


Request Body
application/json

input
*
string|array<string>

Text to classify.


model
*
string

ID of the model to use.

200

Successful Response


id
*
string

model
*
string


results
*
array<ModerationObject>


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.classifiers.moderate(model="Durango", inputs=[
        "<value 1>",
        "<value 2>",
    ])

    # Handle response
    print(res)

200


{
  "id": "4d71ae510af942108ef7344f903e2b88",
  "model": "mistral-moderation-latest",
  "results": [
    {
      "categories": {
        "sexual": false,
        "hate_and_discrimination": false,
        "violence_and_threats": false,
        "dangerous_and_criminal_content": false,
        "selfharm": false,
        "health": false,
        "financial": false,
        "law": false,
        "pii": false
      },
      "category_scores": {
        "sexual": 0.0011335690505802631,
        "hate_and_discrimination": 0.0030753696337342262,
        "violence_and_threats": 0.0003569706459529698,
        "dangerous_and_criminal_content": 0.002251847181469202,
        "selfharm": 0.00017952796770259738,
        "health": 0.0002780309587251395,
        "financial": 0.00008481103577651083,
        "law": 0.00004539786823443137,
        "pii": 0.0023967307060956955
      }
    },
    {
      "categories": {
        "sexual": false,
        "hate_and_discrimination": false,
        "violence_and_threats": false,
        "dangerous_and_criminal_content": false,
        "selfharm": false,
        "health": false,
        "financial": false,
        "law": false,
        "pii": false
      },
      "category_scores": {
        "sexual": 0.000626334105618298,
        "hate_and_discrimination": 0.0013670255430042744,
        "violence_and_threats": 0.0002611903182696551,
        "dangerous_and_criminal_content": 0.0030753696337342262,
        "selfharm": 0.00010889690747717395,
        "health": 0.00015843621804378927,
        "financial": 0.000191104321856983,
        "law": 0.00004006369272246957,
        "pii": 0.0035936026833951473
      }
    }
  ]
}
Chat Moderations


POST
 /v1/chat/moderations


Request Body
application/json


input
*
array<SystemMessage|UserMessage|AssistantMessage|ToolMessage>|array<array<SystemMessage|UserMessage|AssistantMessage|ToolMessage>>

Chat to classify

model
*
string

200

Successful Response


id
*
string

model
*
string


results
*
array<ModerationObject>


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.classifiers.moderate_chat(inputs=[
        {
            "content": "<value>",
            "role": "tool",
        },
    ], model="LeBaron")

    # Handle response
    print(res)

200


{
  "id": "352bce1a55814127a3b0bc4fb8f02a35",
  "model": "mistral-moderation-latest",
  "results": [
    {
      "categories": {
        "sexual": false,
        "hate_and_discrimination": false,
        "violence_and_threats": false,
        "dangerous_and_criminal_content": false,
        "selfharm": false,
        "health": false,
        "financial": false,
        "law": false,
        "pii": false
      },
      "category_scores": {
        "sexual": 0.0010322310263291001,
        "hate_and_discrimination": 0.001597845577634871,
        "violence_and_threats": 0.00020342698553577065,
        "dangerous_and_criminal_content": 0.0029810327105224133,
        "selfharm": 0.00017952796770259738,
        "health": 0.0002959570847451687,
        "financial": 0.000079673009167891,
        "law": 0.00004539786823443137,
        "pii": 0.004198795650154352
      }
    }
  ]
}
Classifications


POST
 /v1/classifications


Request Body
application/json

input
*
string|array<string>

Text to classify.


model
*
string

ID of the model to use.

200

Successful Response


id
*
string

model
*
string


results
*
array<map<ClassificationTargetResult>>


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.classifiers.classify(model="Silverado", inputs=[
        "<value 1>",
    ])

    # Handle response
    print(res)

200


{
  "id": "mod-e5cc70bb28c444948073e77776eb30ef",
  "model": "consequat do",
  "results": [
    [
      {
        "scores": [
          87
        ]
      }
    ]
  ]
}
Chat Classifications


POST
 /v1/chat/classifications


Request Body
application/json


input
*
InstructRequest|array<InstructRequest>

Chat to classify

model
*
string

200

Successful Response


id
*
string

model
*
string


results
*
array<map<ClassificationTargetResult>>


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.classifiers.classify_chat(model="Camry", inputs=[
        {
            "messages": [
                {
                    "content": "<value>",
                    "role": "system",
                },
            ],
        },
    ])

    # Handle response
    print(res)

200


{
  "id": "mod-e5cc70bb28c444948073e77776eb30ef",
  "model": "consequat do",
  "results": [
    [
      {
        "scores": [
          87
        ]
      }
    ]
  ]
}