// Supabase Edge Function for License Activation
// Deploy: supabase functions deploy activate-license

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

serve(async (req) => {
  // Handle CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const supabaseClient = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    )

    const { licenseKey, machineId, machineName, osVersion } = await req.json()

    // Validate input
    if (!licenseKey || !machineId) {
      return new Response(
        JSON.stringify({ success: false, message: 'Missing required fields' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 1. Find the license
    const { data: license, error: licenseError } = await supabaseClient
      .from('licenses')
      .select('*')
      .eq('license_key', licenseKey)
      .single()

    if (licenseError || !license) {
      return new Response(
        JSON.stringify({ success: false, message: 'Invalid license key' }),
        { status: 404, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 2. Check if license is active
    if (license.status !== 'active') {
      return new Response(
        JSON.stringify({ 
          success: false, 
          message: `License is ${license.status}. Contact support@brx.dev` 
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 3. Check expiration for yearly licenses
    if (license.product_tier === 'yearly' && license.expires_at) {
      const expiresAt = new Date(license.expires_at)
      if (expiresAt < new Date()) {
        return new Response(
          JSON.stringify({ 
            success: false, 
            message: 'License has expired. Please renew at brx.dev' 
          }),
          { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
      }
    }

    // 4. Check if this machine is already activated
    const { data: existingActivation } = await supabaseClient
      .from('activations')
      .select('*')
      .eq('license_id', license.id)
      .eq('machine_id', machineId)
      .is('deactivated_at', null)
      .single()

    if (existingActivation) {
      // Already activated, just update last_seen
      await supabaseClient
        .from('activations')
        .update({ last_seen: new Date().toISOString() })
        .eq('id', existingActivation.id)

      return new Response(
        JSON.stringify({
          success: true,
          message: 'License already activated on this machine',
          tier: license.product_tier,
          seatsUsed: license.seats_used,
          seatsTotal: license.seats_total
        }),
        { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 5. Check seat limit
    if (license.seats_used >= license.seats_total) {
      return new Response(
        JSON.stringify({
          success: false,
          message: `All ${license.seats_total} seats are used. Deactivate a machine or upgrade at brx.dev`,
          seatsUsed: license.seats_used,
          seatsTotal: license.seats_total
        }),
        { status: 403, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 6. Create new activation
    const { error: activationError } = await supabaseClient
      .from('activations')
      .insert({
        license_id: license.id,
        machine_id: machineId,
        machine_name: machineName,
        os_version: osVersion
      })

    if (activationError) {
      return new Response(
        JSON.stringify({ success: false, message: 'Failed to activate license' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // 7. Increment seats_used
    const newSeatsUsed = license.seats_used + 1
    await supabaseClient
      .from('licenses')
      .update({ seats_used: newSeatsUsed })
      .eq('id', license.id)

    // 8. Success!
    return new Response(
      JSON.stringify({
        success: true,
        message: 'License activated successfully',
        tier: license.product_tier,
        seatsUsed: newSeatsUsed,
        seatsTotal: license.seats_total
      }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )

  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, message: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})

