# Juniper & Bloom storefront

A responsive tea and coffee storefront inspired by Palampur and the Kangra Valley. The public page works immediately with sample content. Connecting Supabase enables the admin panel to manage products, banners, and the displayed business name.

## Run locally

Serve this folder over HTTP (ES modules do not work reliably from a `file://` URL). For example, from this folder run `python3 -m http.server 8000`, then open `http://localhost:8000`.

## Connect Supabase

1. Create a Supabase project and run `supabase-schema.sql` in its SQL Editor.
2. In Supabase Authentication, enable email/password sign-ups for customer accounts. Configure the project Site URL and allowed redirect URLs, including https://aurumkangratea.netlify.app/welcome.html and https://aurumkangratea.com/welcome.html. Create the first admin user from the dashboard.
3. Copy that user's UUID from Authentication, then run the commented `insert into public.store_admins` statement in the SQL file with the UUID.
4. Copy `config.example.js` to `config.js`. Fill in the project's URL and its public anon/publishable key. Never use a service role key in the browser.
5. Host the folder on any static web host. The SQL setup creates a public `store-images` bucket with admin-only uploads. In the Products or Banners tab, choose an image file from your device to upload it, or paste an image URL. Public Google Drive share links are also accepted; set Drive access to “Anyone with the link” so visitors can see the image.

The admin login button is the small person icon in the header. Supabase row-level security lets anyone read published items, while only user IDs listed in `store_admins` can edit or delete content or upload files. The included admin UI supports creating, editing, publishing/hiding, ordering, and deleting products and banners. The Brand tab lets an admin change the business name, replace the default “J” with another character, or upload/paste a logo image; the logo is shown in both the header and footer.

## Customize

Update the contact email/address and story copy in `index.html`, and change the brand name under the Brand tab after setup. The included sample product and banner content is shown when Supabase is not configured or has no published rows.

## Customer accounts and saved orders

Customers can create an email/password account or sign in from the account icon in the header. An account is optional: guest checkout is also available. Every checkout saves delivery details and a snapshot of product names, quantities, and server-checked prices in the customer_orders and order_items tables. Guest orders appear in the admin Orders tab; signed-in customers can also revisit their own order history. Row-level security restricts order details to the customer who owns them and store admins.

Run the updated supabase-schema.sql in the Supabase SQL Editor to create the order tables, access policies, and place_customer_order function. The function checks current product availability and prices before saving an order. Enable email/password sign-ups in Supabase Authentication so customers can register. If email confirmation is on, customers must confirm their email before signing in.

The admin Orders tab lists guest and account orders and lets an admin update their status. Orders are requests, not paid or confirmed purchases. The store should follow up with the customer to confirm availability, delivery charges, and payment instructions.

The admin Reports tab shows registered customer accounts and estimated unique browsers. Existing registrations are backfilled when the updated schema is run. Visitor tracking uses a first-party browser identifier saved in local storage, so it counts browsers rather than reliably identifying people across devices; counts begin after the report migration is installed.

Admins can turn off purchasing for an individual product in Products → Edit → “Allow add to cart” while leaving it visible. To add the required `available_for_purchase` column to an existing Supabase project, run the updated `supabase-schema.sql` in Supabase SQL Editor. It includes an `ALTER TABLE ... ADD COLUMN IF NOT EXISTS` migration.

Online payment is not enabled yet. When you select a provider, add checkout through a Supabase Edge Function or another trusted server endpoint: re-read current prices from Supabase, create the provider checkout session there, and verify the provider's signed webhook before marking an order paid. Keep secret keys out of `config.js` and the browser bundle.


## Edit the section below products

The admin panel's “Below products” tab edits the garden/story section title, small heading, description, image, and button text. Run the updated `supabase-schema.sql` in Supabase SQL Editor to add the section settings columns to an existing project. Images can be uploaded to the existing `store-images` bucket.


## Contact and social links

The admin Brand tab now manages the contact email and optional Facebook and Instagram URLs. The email updates the contact link and mail order requests; social links appear in the footer when supplied. Run the updated `supabase-schema.sql` to add these settings to an existing project.
