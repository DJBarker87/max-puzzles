# Deployment Checklist

## Pre-Deployment

- [ ] All tests passing: `npm test`
- [ ] Type check passing: `npm run type-check`
- [ ] Build succeeds: `npm run build`
- [ ] Preview build locally: `npm run preview`

## Environment Variables (Vercel Dashboard)

Set these in Vercel project settings:

### Required
- `VITE_SUPABASE_URL` - Your Supabase project URL
- `VITE_SUPABASE_ANON_KEY` - Your Supabase anon key

### Optional
- `VITE_ANALYTICS_ENABLED` - Set to "true" to enable analytics
- `VITE_APP_VERSION` - App version string

## Supabase Setup

1. Create a new Supabase project
2. Run migrations from `supabase/migrations/`
3. Enable Row Level Security on all tables
4. Copy URL and anon key to Vercel

## Domain Setup

1. Add custom domain in Vercel
2. Configure DNS (CNAME or A record)
3. SSL certificate auto-provisioned

## Post-Deployment

- [ ] Test PWA installation on mobile
- [ ] Test offline functionality
- [ ] Test guest mode
- [ ] Test account creation
- [ ] Test puzzle generation
- [ ] Test print/PDF export
- [ ] Monitor error logs

## Rollback

If issues are found:
1. Go to Vercel dashboard
2. Select previous deployment
3. Click "Promote to Production"
