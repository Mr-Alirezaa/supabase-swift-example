// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient, SupabaseClient } from 'jsr:@supabase/supabase-js@2'

// Types for better type safety
interface TransferRequest {
  sender_account_id: string;
  recipient_email: string;
  amount: number;
  currency: string;
  category: string;
  description?: string;
}

interface User {
  id: string;
  email: string;
}

// Create Supabase client
function createSupabaseClient() {
  return createClient(
    Deno.env.get("SUPABASE_URL") ?? "",
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
  );
}

// Validate request data
function validateRequestData(data: TransferRequest): { valid: boolean; error?: string } {
  const { sender_account_id, recipient_email, amount, currency, category } = data;
  
  if (!sender_account_id || !recipient_email || !amount || !currency || !category) {
    return { valid: false, error: "Missing required fields" };
  }
  
  return { valid: true };
}

// Authenticate user from request
async function authenticateUser(req: Request, supabase: SupabaseClient) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return { authenticated: false, error: "Unauthorized: Missing token" };
  }
  
  const token = authHeader.replace("Bearer ", "");
  const { data: { user }, error: authError } = await supabase.auth.getUser(token);
  
  if (authError || !user) {
    return { authenticated: false, error: "Unauthorized: Invalid token" };
  }
  
  return { authenticated: true, user: user as User };
}

// Get recipient user by email
async function getRecipientUser(supabase: SupabaseClient, email: string) {
  // You will need to create a postgres function to get the user id by email, like this:
  // 
  // ```sql
  // CREATE OR REPLACE FUNCTION get_user_id_by_email(email TEXT)
  // RETURNS TABLE (id uuid)
  // SECURITY definer
  // SET search_path = ''
  // AS $$
  // BEGIN
  //   RETURN QUERY SELECT au.id FROM auth.users au WHERE au.email = $1;
  // END;
  // $$ LANGUAGE plpgsql;
  // ```
  const { data: recipientUsers, error: userError } = await supabase.rpc(
    "get_user_id_by_email",
    { email }
  );
  
  if (userError || !recipientUsers || recipientUsers.length === 0) {
    return { found: false, error: "Target user not found" };
  }
  
  return { found: true, userId: recipientUsers[0].id };
}

// Get recipient's account
async function getRecipientAccount(supabase: SupabaseClient, userId: string) {
  const { data: recipientAccounts, error: accountError } = await supabase
    .from("accounts")
    .select("id")
    .eq("user_id", userId)
    .order("created_at", { ascending: true })
    .limit(1);
  
  if (accountError || !recipientAccounts || recipientAccounts.length === 0) {
    return { found: false, error: "Target user has no accounts" };
  }
  
  return { found: true, accountId: recipientAccounts[0].id };
}

// Create a transaction record
async function createTransaction(
  supabase: SupabaseClient, 
  accountId: string, 
  type: 'debit' | 'credit', 
  amount: number,
  currency: string,
  category: string,
  description: string
) {
  const { error } = await supabase
    .from("transactions")
    .insert([
      {
        account_id: accountId,
        type,
        amount,
        currency,
        category,
        description,
        date: new Date().toISOString(),
      },
    ]);
  
  if (error) {
    return { 
      success: false, 
      error: `Failed to create ${type} transaction`, 
      details: error.message 
    };
  }
  
  return { success: true };
}

// Main handler function
Deno.serve(async (req) => {
  try {
    // Parse request body
    const { 
      sender_account_id, 
      recipient_email, 
      amount, 
      currency, 
      category = "Transfer", 
      description 
    } = await req.json() as TransferRequest;
    
    // Validate request data
    const validation = validateRequestData({ 
      sender_account_id, 
      recipient_email, 
      amount, 
      currency, 
      category, 
      description 
    });
    
    if (!validation.valid) {
      return new Response(JSON.stringify({ error: validation.error }), { status: 400 });
    }

    // Create Supabase client
    const supabase = createSupabaseClient();

    // Authenticate user
    const auth = await authenticateUser(req, supabase);
    if (!auth.authenticated) {
      return new Response(JSON.stringify({ error: auth.error }), { status: 401 });
    }
    const user = auth.user as User;

    // Get recipient user
    const recipientUser = await getRecipientUser(supabase, recipient_email);
    if (!recipientUser.found) {
      return new Response(JSON.stringify({ error: recipientUser.error }), { status: 404 });
    }

    // Get recipient account
    const recipientAccount = await getRecipientAccount(supabase, recipientUser.userId);
    if (!recipientAccount.found) {
      return new Response(JSON.stringify({ error: recipientAccount.error }), { status: 404 });
    }

    // Create debit transaction for sender
    const debitResult = await createTransaction(
      supabase,
      sender_account_id,
      'debit',
      amount,
      currency,
      category,
      description || `Transfer to ${recipient_email}`
    );
    
    if (!debitResult.success) {
      return new Response(
        JSON.stringify({ error: debitResult.error, details: debitResult.details }), 
        { status: 500 }
      );
    }

    // Create credit transaction for recipient
    const creditResult = await createTransaction(
      supabase,
      recipientAccount.accountId,
      'credit',
      amount,
      currency,
      category,
      description || `Transfer from ${user.email}`
    );
    
    if (!creditResult.success) {
      return new Response(
        JSON.stringify({ error: creditResult.error, details: creditResult.details }), 
        { status: 500 }
      );
    }

    return new Response(
      JSON.stringify({ message: "Transaction successful", amount, currency, recipient_email }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    );

  } catch (err) {
    const errorMessage = err instanceof Error ? err.message : "Internal Server Error";
    return new Response(JSON.stringify({ error: errorMessage }), { status: 500 });
  }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/transfer' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"sender_account_id":"123","recipient_email":"user@example.com","amount":100,"currency":"USD"}'

*/
