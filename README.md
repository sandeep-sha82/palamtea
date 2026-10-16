# Juniper & Bloom storefront

A responsive tea and coffee storefront inspired by Palampur and the Kangra Valley. The public page works immediately with sample content. Connecting Supabase enables the admin panel to manage products, banners, and the displayed business name.

## Run locally

Serve this folder over HTTP (ES modules do not work reliably from a `file://` URL). For example, from this folder run `python3 -m http.server 8000`, then open `http://localhost:8000`.

## Connect Supabase

1. Create a Supabase project and run `supabase-schema.sql` in its SQL Editor.
2. In Supabase Authentication, disable public sign-ups. Create the first admin user from the dashboard.
3. Copy that user's UUID from Authentication, then run the commented `insert into public.store_admins` statement at the bottom of the SQL file with the UUID.
4. Copy `config.example.js` to `config.js`. Fill in the project's URL and its public anon/publishable key. Never use a service role key in the browser.
5. Host the folder on any static web host. The SQL setup creates a public `store-images` bucket with admin-only uploads. In the Products or Banners tab, choose an image file from your device to upload it, or paste an image URL. Public Google Drive share links are also accepted; set Drive access to “Anyone with the link” so visitors can see the image.

The admin login button is the small person icon in the header. Supabase row-level security lets anyone read published items, while only user IDs listed in `store_admins` can edit or delete content or upload files. The included admin UI supports creating, editing, publishing/hiding, ordering, and deleting products and banners. The Brand tab lets an admin change the business name, replace the default “J” with another character, or upload/paste a logo image; the logo is shown in both the header and footer.

## Customize

Update the contact email/address and story copy in `index.html`, and change the brand name under the Brand tab after setup. The included sample product and banner content is shown when Supabase is not configured or has no published rows.
