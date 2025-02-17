// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

// Setup type definitions for built-in Supabase Runtime APIs
import "jsr:@supabase/functions-js/edge-runtime.d.ts"
import { createClient } from 'jsr:@supabase/supabase-js@2'

Deno.serve(async (req) => {
  try {
    // Parse request body
    const { originAccount, targetUserEmail, amount, currency, category = "Transfer", description } = await req.json();
    // Validate request body
    if (!originAccount || !targetUserEmail || !amount || !currency || !category) {
      return new Response(JSON.stringify({ error: "Missing required fields" }), { status: 400 });
    }

    // Create Supabase client
    const supabase = createClient(
      Deno.env.get("SUPABASE_URL") ?? "",
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") ?? ""
    );

    // Validate authenticated user
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(JSON.stringify({ error: "Unauthorized: Missing token" }), { status: 401 });
    }
    const token = authHeader.replace("Bearer ", "");
    const { data: { user }, error: authError } = await supabase.auth.getUser(token);
    if (authError || !user) {
      return new Response(JSON.stringify({ error: "Unauthorized: Invalid token" }), { status: 401 });
    }

    // Get the target user by email
    const { data: targetUsers, error: userError } = await supabase.rpc(
      "get_user_id_by_email",
      {
        email: targetUserEmail,
      }
    )

    if (userError || !targetUsers || targetUsers.length === 0) {
      return new Response(JSON.stringify({ error: "Target user not found" }), { status: 404 });
    }

    const targetUserId = targetUsers[0].id;

    // Get target user's first account
    const { data: targetAccounts, error: accountError } = await supabase
      .from("accounts")
      .select("id")
      .eq("user_id", targetUserId)
      .order("created_at", { ascending: true })
      .limit(1);

    if (accountError || !targetAccounts || targetAccounts.length === 0) {
      return new Response(JSON.stringify({ error: "Target user has no accounts" }), { status: 404 });
    }

    const targetAccount = targetAccounts[0].id;

    // Insert debit transaction for origin account
    const { error: debitError } = await supabase
      .from("transactions")
      .insert([
        {
          account_id: originAccount,
          type: "debit",
          amount,
          currency,
          category,
          description: description || "Transfer to " + targetUserEmail,
          date: new Date().toISOString(),
        },
      ]);

    if (debitError) {
      return new Response(JSON.stringify({ error: "Failed to create debit transaction", details: debitError.message }), { status: 500 });
    }

    
    // Insert credit transaction for target account
    const { error: creditError } = await supabase
      .from("transactions")
      .insert([
        {
          account_id: targetAccount,
          type: "credit",
          amount,
          currency,
          category,
          description: description || "Transfer from " + user.email,
          date: new Date().toISOString(),
        },
      ]);

    if (creditError) {
      return new Response(JSON.stringify({ error: "Failed to create credit transaction", details: creditError.message }), { status: 500 });
    }

    return new Response(
      JSON.stringify({ message: "Transaction successful", amount, currency, targetUserEmail }),
      { headers: { "Content-Type": "application/json" }, status: 200 }
    );

  } catch (err) {
    return new Response(JSON.stringify({ error: err.message || "Internal Server Error" }), { status: 500 });
  }
})

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/transfer' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
