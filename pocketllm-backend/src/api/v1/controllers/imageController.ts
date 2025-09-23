import { FastifyRequest, FastifyReply } from 'fastify'
import { supabaseAdmin } from '../../../shared/supabaseClient.ts'
import { generateImage } from '../../../shared/providers/imageRouter.ts'
import { handleError } from '../../../shared/utils/errorHandler.ts'
import { z } from 'zod'
import { createImageJobSchema, getJobStatusSchema } from '../schemas/imageSchemas.ts'

type CreateImageJobRequest = FastifyRequest<{
  Body: z.infer<typeof createImageJobSchema.body>,
  User: { id: string }
}>

type GetJobStatusRequest = FastifyRequest<{
  Params: z.infer<typeof getJobStatusSchema.params>,
  User: { id: string }
}>

// Helper to convert a base64 string to an ArrayBuffer for uploading.
// `atob` is available in the Deno global scope.
function base64ToArrayBuffer(b64: string) {
    const byteString = atob(b64);
    const len = byteString.length;
    const bytes = new Uint8Array(len);
    for (let i = 0; i < len; i++) {
        bytes[i] = byteString.charCodeAt(i);
    }
    return bytes.buffer;
}

// The asynchronous worker function that processes the image generation job.
async function processImageGeneration(jobId: string, userId: string, inputData: any) {
    try {
        await supabaseAdmin.from('jobs').update({ status: 'processing', updated_at: new Date() }).eq('id', jobId)

        const imageRouterApiKey = Deno.env.get('IMAGEROUTER_API_KEY');
        if (!imageRouterApiKey) {
            throw new Error('IMAGEROUTER_API_KEY is not set in environment variables.');
        }

        const result = await generateImage(inputData, imageRouterApiKey);
        const imageBuffer = base64ToArrayBuffer(result.base64Image);

        const filePath = `private/generated_images/${userId}/${jobId}.png`;
        const { error: uploadError } = await supabaseAdmin.storage
            .from('user_assets')
            .upload(filePath, imageBuffer, {
                contentType: result.mimeType,
                upsert: true, // Overwrite if it already exists for some reason
            });

        if (uploadError) {
            throw new Error(`Failed to upload image to storage: ${uploadError.message}`);
        }

        const { data: urlData } = supabaseAdmin.storage
            .from('user_assets')
            .getPublicUrl(filePath);

        const outputData = { imageUrl: urlData.publicUrl };

        await supabaseAdmin
            .from('jobs')
            .update({ status: 'completed', output_data: outputData, updated_at: new Date() })
            .eq('id', jobId);

    } catch (error) {
        console.error(`Image generation failed for job ${jobId}:`, error);
        const errorMessage = error instanceof Error ? error.message : 'An unknown error occurred during image processing.';
        await supabaseAdmin
            .from('jobs')
            .update({ status: 'failed', error_log: errorMessage, updated_at: new Date() })
            .eq('id', jobId);
    }
}

export async function handleNewImageJob(request: CreateImageJobRequest, reply: FastifyReply) {
  try {
    const userId = request.user.id

    const { data: newJob, error: jobError } = await supabaseAdmin
      .from('jobs')
      .insert({
        user_id: userId,
        job_type: 'image_generation',
        status: 'pending',
        input_data: request.body,
      })
      .select('id')
      .single()

    if (jobError || !newJob) throw new Error(`Failed to create job: ${jobError?.message}`)

    // Immediately respond to the client
    reply.status(202).send({ jobId: newJob.id })

    // Start the async processing
    processImageGeneration(newJob.id, userId, request.body)

  } catch (error) {
    return handleError(reply, error, 'Failed to create image generation job.')
  }
}

export async function getJobStatus(request: GetJobStatusRequest, reply: FastifyReply) {
    try {
        const userId = request.user.id
        const { jobId } = request.params

        const { data: job, error } = await supabaseAdmin
            .from('jobs')
            .select('id, status, output_data, error_log')
            .eq('id', jobId)
            .eq('user_id', userId)
            .single()

        if (error || !job) {
            return reply.status(404).send({ error: 'Job not found' })
        }

        return reply.status(200).send(job)

    } catch (error) {
        return handleError(reply, error, 'Failed to get job status.')
    }
}
