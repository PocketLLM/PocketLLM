import { createClient } from '@supabase/supabase-js'

// This client is intended for use in a server-side environment (e.g., Supabase Edge Functions).
// It uses the Service Role Key for administrative access.
const supabaseUrl = Deno.env.get('SUPABASE_URL')
const supabaseServiceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

if (!supabaseUrl || !supabaseServiceRoleKey) {
  console.error('Supabase environment variables (SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY) are not set!')
  throw new Error('Supabase URL and service role key are required for server-side client.')
}

export const supabaseAdmin = createClient(supabaseUrl, supabaseServiceRoleKey)
