import { createClient } from 'https://esm.sh/@supabase/supabase-js@2';

try {
  const config = await import('./config.js');
  if (config.SUPABASE_URL && config.SUPABASE_ANON_KEY) {
    const supabase = createClient(config.SUPABASE_URL, config.SUPABASE_ANON_KEY);
    const confirmationCode = new URL(window.location.href).searchParams.get('code');
    if (confirmationCode) {
      const { error } = await supabase.auth.exchangeCodeForSession(confirmationCode);
      if (error) console.warn('Email confirmed, but this browser could not start a signed-in session.', error);
    } else {
      const { error } = await supabase.auth.getSession();
      if (error) console.warn('Email confirmed, but this browser could not start a signed-in session.', error);
    }
  }
} catch (error) {
  console.warn('Could not initialize the welcome page authentication callback.', error);
}
