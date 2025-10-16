# 🔐 BRX Supabase License Setup

## ✅ Quick Setup (5 minutes)

### 1️⃣ Create Database Tables

Go to your Supabase SQL Editor and run:
```sql
-- Copy entire contents from supabase/schema.sql
```

Or visit: https://mraxgilahgpxrichbcdl.supabase.co/project/default/sql

### 2️⃣ Deploy Edge Functions

```bash
# Install Supabase CLI if you haven't
brew install supabase/tap/supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref mraxgilahgpxrichbcdl

# Deploy the functions
supabase functions deploy activate-license
supabase functions deploy license-checkin
```

### 3️⃣ Test It!

```bash
# Generate a test license key
swift scripts/generate-license.swift

# Insert test license in Supabase SQL Editor:
INSERT INTO licenses (license_key, email, product_tier, seats_total)
VALUES ('BRX-XXXX-XXXX-XXXX-XXXX', 'test@example.com', 'lifetime', 1);

# Try activating
brx activate --license-key BRX-XXXX-XXXX-XXXX-XXXX
```

---

## 🎯 What You Get

### ✅ Online Activation
- Validates license with Supabase
- Checks seat limits
- Tracks activations per machine
- Prevents sharing/piracy

### ✅ Offline Fallback
- If Supabase is unreachable, falls back to local validation
- Users can still work offline

### ✅ Seat Management
```sql
-- Check license usage
SELECT 
  l.license_key,
  l.email,
  l.product_tier,
  l.seats_used || '/' || l.seats_total as seats,
  COUNT(a.id) as active_machines
FROM licenses l
LEFT JOIN activations a ON a.license_id = l.id AND a.deactivated_at IS NULL
GROUP BY l.id;
```

### ✅ Revoke Licenses
```sql
-- Revoke a license
UPDATE licenses SET status = 'revoked' WHERE license_key = 'BRX-XXXX...';
```

---

## 🔗 Integrate with Lemon Squeezy

### Webhook Handler (add to your site)

```typescript
// pages/api/webhooks/lemon-squeezy.ts
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'https://mraxgilahgpxrichbcdl.supabase.co',
  process.env.SUPABASE_SERVICE_ROLE_KEY!
)

export default async function handler(req, res) {
  const { event_name, data } = req.body

  if (event_name === 'order_created') {
    // Generate license key
    const licenseKey = await generateLicenseKey()
    
    // Determine tier and seats
    const productId = data.attributes.first_order_item.product_id
    let tier = 'yearly'
    let seats = 1
    
    if (productId === 'YOUR_LIFETIME_PRODUCT_ID') {
      tier = 'lifetime'
    } else if (productId === 'YOUR_TEAM_PRODUCT_ID') {
      tier = 'team'
      seats = data.meta.custom_data.seats || 5
    }
    
    // Create license in Supabase
    await supabase.from('licenses').insert({
      license_key: licenseKey,
      email: data.attributes.user_email,
      product_tier: tier,
      seats_total: seats,
      expires_at: tier === 'yearly' ? addOneYear() : null
    })
    
    // Email license key to customer
    await sendLicenseEmail(data.attributes.user_email, licenseKey)
  }

  res.status(200).json({ received: true })
}
```

---

## 📊 Analytics Queries

### Active Users
```sql
SELECT COUNT(DISTINCT machine_id) as active_machines
FROM activations
WHERE deactivated_at IS NULL
AND last_seen > NOW() - INTERVAL '7 days';
```

### Revenue Breakdown
```sql
SELECT 
  product_tier,
  COUNT(*) as licenses,
  SUM(seats_total) as total_seats,
  SUM(seats_used) as used_seats
FROM licenses
WHERE status = 'active'
GROUP BY product_tier;
```

### Expiring Soon
```sql
SELECT license_key, email, expires_at
FROM licenses
WHERE product_tier = 'yearly'
AND expires_at < NOW() + INTERVAL '30 days'
AND expires_at > NOW()
ORDER BY expires_at;
```

---

## 🛠️ Development Tips

### Test Locally (Offline Mode)
```bash
# Just use local validation
brx activate --license-key BRX-0A22-ISMC-BXLS-4D0E
# Falls back to offline if Supabase unreachable
```

### Generate Test Keys
```bash
swift scripts/generate-license.swift
```

### Check Your License
```bash
brx activate
# Shows if license is active
```

---

## 🔒 Security Notes

1. ✅ Anon key is safe in client app (it's public-facing)
2. ✅ RLS policies protect data
3. ✅ Edge Functions use service role for admin actions
4. ✅ Checksum prevents key generation without your script
5. ⚠️ Keep service role key secret (never commit to git)

---

## 🎉 That's It!

Your license system is now:
- ✅ Preventing piracy with online validation
- ✅ Managing seat limits automatically
- ✅ Working offline with cached validation
- ✅ Tracking usage analytics
- ✅ Integrated with Lemon Squeezy

Cost: **$0/month** on Supabase free tier for <500 users! 🚀

