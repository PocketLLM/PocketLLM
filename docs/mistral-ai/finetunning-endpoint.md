Fine Tuning Endpoints
Fine-tuning API

Toggle themeWall AssetsCat FrameLampCat ToyLamp LightDeskChairOrange Cat IdleLamp LightScreenScreen LightLamp Light Large
Examples
Real world code examples

Get Fine Tuning Jobs


GET
 /v1/fine_tuning/jobs

Get a list of fine-tuning jobs for your organization and user.

200

OK


data
array<CompletionJobOut|ClassifierJobOut>

object
"list"

Default Value: "list"

total
*
integer


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.fine_tuning.jobs.list(page=0, page_size=100, created_by_me=False)

    # Handle response
    print(res)

200


{
  "total": 87
}
Create Fine Tuning Job


POST
 /v1/fine_tuning/jobs

Create a new fine-tuning job, it will be queued for processing.


Parameters
application/json

dry_run
boolean|null

If true the job is not spawned, instead the query returns a handful of useful metadata for the user to perform sanity checks (see LegacyJobMetadataOut response).
Otherwise, the job is started and the query returns the job ID along with some of the input parameters (see JobOut response).

Request Body
application/json

auto_start
boolean

This field will be required in a future release.


classifier_targets
array<ClassifierTargetIn>|null


hyperparameters
*
CompletionTrainingParametersIn|ClassifierTrainingParametersIn


integrations
array<WandbIntegration>|null

A list of integrations to enable for your fine-tuning job.

invalid_sample_skip_percentage
number

Default Value: 0

job_type
"completion"|"classifier"

model
*
"ministral-3b-latest"|"ministral-8b-latest"|"open-mistral-7b"|"open-mistral-nemo"|"mistral-small-latest"|"mistral-medium-latest"|"mistral-large-latest"|"pixtral-12b-latest"|"codestral-latest"

The name of the model to fine-tune.


repositories
array<GithubRepositoryIn>|null

suffix
string|null

A string that will be added to your fine-tuning model name. For example, a suffix of "my-great-model" would produce a model name like ft:open-mistral-7b:my-great-model:xxx...


training_files
array<TrainingFile>

validation_files
array<string>|null

A list containing the IDs of uploaded files that contain validation data. If you provide these files, the data is used to generate validation metrics periodically during fine-tuning. These metrics can be viewed in checkpoints when getting the status of a running fine-tuning job. The same data should not be present in both train and validation files.

200

Response Type
CompletionJobOut|ClassifierJobOut|LegacyJobMetadataOut
OK


CompletionJobOut
{object}

ClassifierJobOut
{object}

LegacyJobMetadataOut
{object}

TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.fine_tuning.jobs.create(model="Camaro", hyperparameters={
        "learning_rate": 0.0001,
    }, invalid_sample_skip_percentage=0)

    # Handle response
    print(res)

200


{
  "auto_start": false,
  "created_at": 87,
  "hyperparameters": {},
  "id": "ipsum eiusmod",
  "model": "ministral-3b-latest",
  "modified_at": 14,
  "status": "QUEUED",
  "training_files": [
    "consequat do"
  ]
}
Get Fine Tuning Job


GET
 /v1/fine_tuning/jobs/{job_id}

Get a fine-tuned job details by its UUID.


Parameters
application/json

job_id
*
string

The ID of the job to analyse.

200

Response Type
CompletionDetailedJobOut|ClassifierDetailedJobOut
OK


CompletionDetailedJobOut
{object}

ClassifierDetailedJobOut
{object}

TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.fine_tuning.jobs.get(job_id="c167a961-ffca-4bcf-93ac-6169468dd389")

    # Handle response
    print(res)

200


{
  "auto_start": false,
  "created_at": 87,
  "hyperparameters": {},
  "id": "ipsum eiusmod",
  "model": "ministral-3b-latest",
  "modified_at": 14,
  "status": "QUEUED",
  "training_files": [
    "consequat do"
  ]
}
Cancel Fine Tuning Job


POST
 /v1/fine_tuning/jobs/{job_id}/cancel

Request the cancellation of a fine tuning job.


Parameters
application/json

job_id
*
string

The ID of the job to cancel.

200

Response Type
CompletionDetailedJobOut|ClassifierDetailedJobOut
OK


CompletionDetailedJobOut
{object}

ClassifierDetailedJobOut
{object}

TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.fine_tuning.jobs.cancel(job_id="6188a2f6-7513-4e0f-89cc-3f8088523a49")

    # Handle response
    print(res)

200


{
  "auto_start": false,
  "created_at": 87,
  "hyperparameters": {},
  "id": "ipsum eiusmod",
  "model": "ministral-3b-latest",
  "modified_at": 14,
  "status": "QUEUED",
  "training_files": [
    "consequat do"
  ]
}
Start Fine Tuning Job


POST
 /v1/fine_tuning/jobs/{job_id}/start

Request the start of a validated fine tuning job.


Parameters
application/json

job_id
*
string

200

Response Type
CompletionDetailedJobOut|ClassifierDetailedJobOut
OK


CompletionDetailedJobOut
{object}
auto_start
*
boolean


checkpoints
array<CheckpointOut>


CheckpointOut
{object}

created_at
*
integer

The UNIX timestamp (in seconds) for when the checkpoint was created.

Example:


1716963433

metrics
*
MetricOut


step_number
*
integer

created_at
*
integer


events
array<EventOut>

fine_tuned_model
string|null


hyperparameters
*
CompletionTrainingParameters

id
*
string


integrations
array<WandbIntegrationOut>|null

job_type
"completion"

Default Value: "completion"


metadata
JobMetadataOut|null


model
*
"ministral-3b-latest"|"ministral-8b-latest"|"open-mistral-7b"|"open-mistral-nemo"|"mistral-small-latest"|"mistral-medium-latest"|"mistral-large-latest"|"pixtral-12b-latest"|"codestral-latest"

The name of the model to fine-tune.

modified_at
*
integer

object
"job"

Default Value: "job"


repositories
array<GithubRepositoryOut>


GithubRepositoryOut
{object}
commit_id
*
string

name
*
string

owner
*
string

ref
string|null

type
"github"

Default Value: "github"

weight
number

Default Value: 1

status
*
"QUEUED"|"STARTED"|"VALIDATING"|"VALIDATED"|"RUNNING"|"FAILED_VALIDATION"|"FAILED"|"SUCCESS"|"CANCELLED"|"CANCELLATION_REQUESTED"

suffix
string|null

trained_tokens
integer|null

training_files
*
array<string>

validation_files
array<string>|null


ClassifierDetailedJobOut
{object}
auto_start
*
boolean


checkpoints
array<CheckpointOut>


classifier_targets
*
array<ClassifierTargetOut>

created_at
*
integer


events
array<EventOut>

fine_tuned_model
string|null


hyperparameters
*
ClassifierTrainingParameters

id
*
string


integrations
array<WandbIntegrationOut>|null

job_type
"classifier"

Default Value: "classifier"


metadata
JobMetadataOut|null


model
*
"ministral-3b-latest"|"ministral-8b-latest"|"open-mistral-7b"|"open-mistral-nemo"|"mistral-small-latest"|"mistral-medium-latest"|"mistral-large-latest"|"pixtral-12b-latest"|"codestral-latest"

modified_at
*
integer

object
"job"

Default Value: "job"

status
*
"QUEUED"|"STARTED"|"VALIDATING"|"VALIDATED"|"RUNNING"|"FAILED_VALIDATION"|"FAILED"|"SUCCESS"|"CANCELLED"|"CANCELLATION_REQUESTED"

suffix
string|null

trained_tokens
integer|null

training_files
*
array<string>

validation_files
array<string>|null


TypeScript


Python


cURL


from mistralai import Mistral
import os


with Mistral(
    api_key=os.getenv("MISTRAL_API_KEY", ""),
) as mistral:

    res = mistral.fine_tuning.jobs.start(job_id="56553e4d-0679-471e-b9ac-59a77d671103")

    # Handle response
    print(res)

200


{
  "auto_start": false,
  "created_at": 87,
  "hyperparameters": {},
  "id": "ipsum eiusmod",
  "model": "ministral-3b-latest",
  "modified_at": 14,
  "status": "QUEUED",
  "training_files": [
    "consequat do"
  ]
}