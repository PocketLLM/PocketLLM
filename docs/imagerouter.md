Quick start
Get an API key
Generate images with any model available on ImageRouter:
Curl
Javascript
Python
Terminal window
curl 'https://api.imagerouter.io/v1/openai/images/generations' \
-H 'Authorization: Bearer YOUR_API_KEY' \
-H 'Content-Type: application/json' \
--data-raw '{"prompt": "YOUR_PROMPT", "model": "test/test"}'

Rate Limits
To ensure fair usage and prevent abuse of our API, we have implemented rate limiting on our generative endpoints.

Your allowance for image and video generation is calculated dynamically from your current account balance. The formulas below are applied every second when your request arrives:

Rate Limit Calculator
Your balance (USD):
0
Image generation: 6 req/s

Video generation: 1 req/s

Formula
Image generation
limitPerSecond = balanceUSD * 4

minimum 6 req/s
maximum 100 req/s
Video generation
limitPerSecond = balanceUSD / 6

minimum 1 req/s
maximum 20 req/s
Where to see your limits
Open the API Keys page inside the dashboard. Your personalised rate limits are displayed at the top of the page.

Lifting Limits
Adding more balance will immediately raise the calculated caps (up to the hard maximums above). Head over to the Pricing page to deposit credits.

If you have a special use-case that still needs higher throughput, please contact us.

Models
Get models available on ImageRouter

Curl
Javascript
Python
Terminal window
curl 'https://api.imagerouter.io/v1/models'

You can also just open it in your browser: https://api.imagerouter.io/v1/models

Image Generation
Generate images with any model available on ImageRouter.

Curl
Javascript
Python
Terminal window
curl 'https://api.imagerouter.io/v1/openai/images/generations' \
-H 'Authorization: Bearer YOUR_API_KEY' \
-H 'Content-Type: application/json' \
--data-raw '{"prompt": "YOUR_PROMPT", "model": "test/test"}'

Parameners:
prompt* Text prompt for generating images.
model* Image model to use for generation.
quality [auto, low, medium, high] - default “auto”; Supported models have “quality” feature label here
size [auto, WIDTHxHEIGHT (eg 1024x1024)] - default “auto”; Accepted values are different for each model. Some models and providers completely ignore size.
response_format [url, b64_json] - default “url”.
image[] Input image(s) for supported image editing models.
mask[] Some models require a mask file to specify areas to edit.
Please contact me if you miss anything.


Image Edits
Image editing is very similar to image generation. Key differences:

Instead of JSON, encode your request as multipart/form-data
Specify input image(s)
If needed, specify edit mask
For Image Editing models, see the list of models with Edit label, or filter for Image-to-Image models.

Curl
Javascript
Python
Terminal window
curl -X POST "https://api.imagerouter.io/v1/openai/images/edits" \
-H "Authorization: Bearer YOUR_API_KEY" \
-F "prompt=YOUR_PROMPT" \
-F "model=openai/gpt-image-1" \
-F "image[]=@your_image1.webp" \
-F "image[]=@your_image2.webp" \
-F "mask[]=@your_mask.webp"

note: /v1/openai/images/generations and /v1/openai/images/edits are the same, we have both for compatibility reasons.

Parameners:
Same as Image Generation


Video Generation
Generate videos with any video model available on ImageRouter.

Videos are in Beta, this API can change later.

Curl
Javascript
Python
Terminal window
curl 'https://api.imagerouter.io/v1/openai/videos/generations' \
-H 'Authorization: Bearer YOUR_API_KEY' \
-H 'Content-Type: application/json' \
--data-raw '{"prompt": "YOUR_PROMPT", "model": "ir/test-video"}'

Post parameners:

prompt* Text prompt for generating video.
model* Video model to use.
Currently, every other parameter is ignored & defaulted (aspectRatio=16:9, durationSeconds=5 or 6) for simplicity. They will be added in the future. Please contact me if you miss anything.

openapi: 3.1.0
info:
  title: Image Router API
  version: 0.0.1
servers:
  - url: https://api.imagerouter.io
components:
  schemas:
    ImageGenerationRequest:
      type: object
      properties:
        prompt:
          type: string
          minLength: 1
        model:
          type: string
          minLength: 1
        response_format:
          type: string
          enum: &a1
            - url
            - b64_json
          default: url
        quality:
          type: string
          enum: &a2
            - auto
            - low
            - medium
            - high
          default: auto
        size:
          type: string
          default: auto
      required:
        - prompt
        - model
    VideoGenerationRequest:
      type: object
      properties:
        prompt:
          type: string
          minLength: 1
        model:
          type: string
          minLength: 1
        response_format:
          type: string
          enum: &a3
            - url
            - b64_json
          default: url
        size:
          type: string
          default: auto
      required:
        - prompt
        - model
    ImageEditRequest:
      type: object
      properties:
        prompt:
          type: string
          minLength: 1
        model:
          type: string
          minLength: 1
        response_format:
          type: string
          enum: *a1
          default: url
        quality:
          type: string
          enum: *a2
          default: auto
        size:
          type: string
          default: auto
        image: {}
        mask: {}
      required:
        - prompt
        - model
  parameters: {}
paths:
  /v1/openai/images/generations:
    post:
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                prompt:
                  type: string
                  minLength: 1
                model:
                  type: string
                  minLength: 1
                response_format:
                  type: string
                  enum: *a1
                  default: url
                quality:
                  type: string
                  enum: *a2
                  default: auto
                size:
                  type: string
                  default: auto
              required:
                - prompt
                - model
      responses:
        "200":
          description: Success
  /v1/openai/videos/generations:
    post:
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                prompt:
                  type: string
                  minLength: 1
                model:
                  type: string
                  minLength: 1
                response_format:
                  type: string
                  enum: *a3
                  default: url
                size:
                  type: string
                  default: auto
              required:
                - prompt
                - model
      responses:
        "200":
          description: Success
  /v1/openai/images/edits:
    post:
      requestBody:
        required: true
        content:
          multipart/form-data:
            schema:
              $ref: "#/components/schemas/ImageEditRequest"
      responses:
        "200":
          description: Success
  /v1/models:
    get:
      responses:
        "200":
          description: Success
webhooks: {}