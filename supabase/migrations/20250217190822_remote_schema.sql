drop policy "Enable users to view their own data only" on "public"."transactions";

alter table "public"."transactions" disable row level security;

alter table "public"."accounts" add constraint "accounts_user_id_fkey" FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE not valid;

alter table "public"."accounts" validate constraint "accounts_user_id_fkey";

set check_function_bodies = off;

CREATE OR REPLACE FUNCTION public.get_user_id_by_email(email text)
 RETURNS TABLE(id uuid)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
BEGIN
  RETURN QUERY SELECT au.id FROM auth.users au WHERE au.email = $1;
END;
$function$
;


