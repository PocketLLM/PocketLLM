Models Endpoints
Model Management API

Toggle themeWall AssetsCat FrameLampCat ToyLamp LightDeskChairOrange Cat IdleLamp LightScreenScreen LightLamp Light Large
Examples
Real world code examples

List Models


GET
 /v1/models

List all models available to the user.

200

Successful Response


data
array<BaseModelCard|FTModelCard>


BaseModelCard
{object}
aliases
array<string>


capabilities
*
ModelCapabilities


ModelCapabilities
{object}
classification
boolean

Default Value: false

completion_chat
boolean

Default Value: true

completion_fim
boolean

Default Value: false

fine_tuning
boolean

Default Value: false

function_calling
boolean

Default Value: true

vision
boolean

Default Value: false

created
integer

default_model_temperature
number|null

deprecation
date-time|null

deprecation_replacement_model
string|null

description
string|null

id
*
string

max_context_length
integer

Default Value: 32768

name
string|null

object
string

Default Value: "model"

owned_by
string

Default Value: "mistralai"

type
"base"

Default Value: "base"


FTModelCard
{object}
Extra fields for fine-tuned models.

aliases
array<string>

archived
boolean

Default Value: false


capabilities
*
ModelCapabilities


ModelCapabilities
{object}
classification
boolean

Default Value: false

completion_chat
boolean

Default Value: true

completion_fim
boolean

Default Value: false

fine_tuning
boolean

Default Value: false

function_calling
boolean

Default Value: true

vision
boolean

Default Value: false

created
integer

default_model_temperature
number|null

deprecation
date-time|null

deprecation_replacement_model
string|null

description
string|null

id
*
string

job
*
string

max_context_length
integer

Default Value: 32768

name
string|null

object
string

Default Value: "model"

owned_by
string

Default Value: "mistralai"

root
*
string

type
"fine-tuned"

Default Value: "fine-tuned"

object
string

Default Value: "list"


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.models.list()

    # Handle response
    print(res)

200


[
  {
    "id": "<model_id>",
    "capabilities": {
      "completion_chat": true,
      "completion_fim": false,
      "function_calling": false,
      "fine_tuning": false,
      "vision": false,
      "classification": false
    },
    "job": "<job_id>",
    "root": "open-mistral-7b",
    "object": "model",
    "created": 1756746619,
    "owned_by": "<owner_id>",
    "name": null,
    "description": null,
    "max_context_length": 32768,
    "aliases": [],
    "deprecation": null,
    "deprecation_replacement_model": null,
    "default_model_temperature": null,
    "TYPE": "fine-tuned",
    "archived": false
  }
]
Retrieve Model


GET
 /v1/models/{model_id}

Retrieve information about a model.


Parameters
application/json

model_id
*
string

The ID of the model to retrieve.

200

Response Type
BaseModelCard|FTModelCard
Successful Response


BaseModelCard
{object}
aliases
array<string>


capabilities
*
ModelCapabilities


ModelCapabilities
{object}
classification
boolean

Default Value: false

completion_chat
boolean

Default Value: true

completion_fim
boolean

Default Value: false

fine_tuning
boolean

Default Value: false

function_calling
boolean

Default Value: true

vision
boolean

Default Value: false

created
integer

default_model_temperature
number|null

deprecation
date-time|null

deprecation_replacement_model
string|null

description
string|null

id
*
string

max_context_length
integer

Default Value: 32768

name
string|null

object
string

Default Value: "model"

owned_by
string

Default Value: "mistralai"

type
"base"

Default Value: "base"


FTModelCard
{object}
Extra fields for fine-tuned models.

aliases
array<string>

archived
boolean

Default Value: false


capabilities
*
ModelCapabilities

created
integer

default_model_temperature
number|null

deprecation
date-time|null

deprecation_replacement_model
string|null

description
string|null

id
*
string

job
*
string

max_context_length
integer

Default Value: 32768

name
string|null

object
string

Default Value: "model"

owned_by
string

Default Value: "mistralai"

root
*
string

type
"fine-tuned"

Default Value: "fine-tuned"


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.models.retrieve(model_id="ft:open-mistral-7b:587a6b29:20240514:7e773925")

    # Handle response
    print(res)

200


{
  "id": "<your_model_id>",
  "capabilities": {
    "completion_chat": true,
    "completion_fim": false,
    "function_calling": false,
    "fine_tuning": false,
    "vision": false,
    "classification": false
  },
  "job": "<job_id>",
  "root": "open-mistral-7b",
  "object": "model",
  "created": 1756746619,
  "owned_by": "<owner_id>",
  "name": null,
  "description": null,
  "max_context_length": 32768,
  "aliases": [],
  "deprecation": null,
  "deprecation_replacement_model": null,
  "default_model_temperature": null,
  "TYPE": "fine-tuned",
  "archived": false
}
Delete Model


DELETE
 /v1/models/{model_id}

Delete a fine-tuned model.


Parameters
application/json

model_id
*
string

The ID of the model to delete.

200

Successful Response


deleted
boolean

Default Value: true

The deletion status


id
*
string

The ID of the deleted model.

object
string

Default Value: "model"

The object type that was deleted


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.models.delete(model_id="ft:open-mistral-7b:587a6b29:20240514:7e773925")

    # Handle response
    print(res)

200


{
  "id": "ft:open-mistral-7b:587a6b29:20240514:7e773925",
  "object": "model",
  "deleted": true
}
Update Fine Tuned Model


PATCH
 /v1/fine_tuning/models/{model_id}

Update a model name or description.


Parameters
application/json

model_id
*
string

The ID of the model to update.


Request Body
application/json

description
string|null

name
string|null

200

Response Type
CompletionFTModelOut|ClassifierFTModelOut
OK


CompletionFTModelOut
{object}
aliases
array<string>

archived
*
boolean


capabilities
*
FTModelCapabilitiesOut


FTModelCapabilitiesOut
{object}
created
*
integer

description
string|null

id
*
string

job
*
string

max_context_length
integer

Default Value: 32768

model_type
"completion"

Default Value: "completion"

name
string|null

object
"model"

Default Value: "model"

owned_by
*
string

root
*
string

root_version
*
string

workspace_id
*
string


ClassifierFTModelOut
{object}
aliases
array<string>

archived
*
boolean


capabilities
*
FTModelCapabilitiesOut


classifier_targets
*
array<ClassifierTargetOut>

created
*
integer

description
string|null

id
*
string

job
*
string

max_context_length
integer

Default Value: 32768

model_type
"classifier"

Default Value: "classifier"

name
string|null

object
"model"

Default Value: "model"

owned_by
*
string

root
*
string

root_version
*
string

workspace_id
*
string


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.models.update(model_id="ft:open-mistral-7b:587a6b29:20240514:7e773925")

    # Handle response
    print(res)

200


{
  "archived": false,
  "capabilities": {},
  "created": 87,
  "id": "ipsum eiusmod",
  "job": "consequat do",
  "owned_by": "reprehenderit ut dolore",
  "root": "occaecat dolor sit",
  "root_version": "nostrud",
  "workspace_id": "aute aliqua aute commodo"
}
Archive Fine Tuned Model


POST
 /v1/fine_tuning/models/{model_id}/archive

Archive a fine-tuned model.


Parameters
application/json

model_id
*
string

The ID of the model to archive.

200

OK

archived
boolean

Default Value: true

id
*
string

object
"model"

Default Value: "model"


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.models.archive(model_id="ft:open-mistral-7b:587a6b29:20240514:7e773925")

    # Handle response
    print(res)

200


{
  "id": "ipsum eiusmod"
}
Unarchive Fine Tuned Model


DELETE
 /v1/fine_tuning/models/{model_id}/archive

Un-archive a fine-tuned model.


Parameters
application/json

model_id
*
string

The ID of the model to unarchive.

200

OK

archived
boolean

Default Value: false

id
*
string

object
"model"

Default Value: "model"


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.models.unarchive(model_id="ft:open-mistral-7b:587a6b29:20240514:7e773925")

    # Handle response
    print(res)

200


{
  "id": "ipsum eiusmod"
}