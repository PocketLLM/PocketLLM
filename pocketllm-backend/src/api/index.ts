import Fastify from 'fastify'
import { ZodTypeProvider, withZod } from 'fastify-zod'
import { supabaseAdmin } from '../shared/supabaseClient.ts'

// Import route plugins
import authRoutes from './routes/auth.ts'
import chatRoutes from './routes/chats.ts'
import jobRoutes from './routes/jobs.ts'
import modelRoutes from './routes/models.ts'

// Augment FastifyRequest to include the 'user' property, making it available on authenticated requests
declare module 'fastify' {
  interface FastifyRequest {
    user: { id: string }
  }
}

// Initialize Fastify with Zod support
const fastify = Fastify().withTypeProvider<ZodTypeProvider>()
withZod(fastify)

// Decorate the Fastify instance with an authentication handler
fastify.decorate('authenticate', async function(request, reply) {
  try {
    const token = request.headers.authorization?.replace('Bearer ', '')
    if (!token) {
      throw new Error('Missing or malformed authorization header')
    }
    const { data, error } = await supabaseAdmin.auth.getUser(token)
    if (error || !data.user) {
      throw new Error('Invalid, expired, or malformed token')
    }
    // Attach user to the request object
    request.user = { id: data.user.id }
  } catch (err) {
    reply.code(401).send({ error: 'Unauthorized', message: err.message })
  }
})

// Register public routes that do not require authentication
fastify.register(authRoutes)

// Register a plugin that applies the authentication hook to all routes within it
fastify.register(async (instance) => {
  instance.addHook('preHandler', instance.authenticate)

  // Register protected routes
  instance.register(chatRoutes)
  instance.register(jobRoutes)
  instance.register(modelRoutes)
})

// Main handler for the Supabase Edge Function
Deno.serve(async (req) => {
  try {
    const url = new URL(req.url)
    const response = await fastify.inject({
      method: req.method,
      url: url.pathname,
      query: Object.fromEntries(url.searchParams),
      headers: Object.fromEntries(req.headers.entries()),
      body: req.body ? await req.text() : undefined
    });

    return new Response(response.rawPayload, {
      status: response.statusCode,
      headers: response.headers,
    });
  } catch (err) {
    console.error('Error in Deno.serve handler:', err);
    return new Response(JSON.stringify({ error: 'Internal Server Error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    });
  }
});
