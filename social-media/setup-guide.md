# Social Media Scheduler — n8n Setup Guide

Replaces Postiz (CT115). Posts to Twitter/X, Facebook, Instagram on a schedule.
Queue is managed via `social_posts` table in MariaDB `Callon-dad` database.

---

## Step 1 — Create the Database Table

SSH to MariaDB (CT102) or run from n8n via MySQL node:

```bash
ssh root@192.168.0.6
mysql -u admin -p Callon-dad < /path/to/social_posts.sql
```

Or paste the SQL from `social-media/social_posts.sql` directly into phpMyAdmin.

---

## Step 2 — API Credentials

### Twitter/X

> **Cost:** Twitter API Basic = $100/month (required for posting).
> Free tier is read-only. Check if your Postiz credentials included elevated access.

1. Go to developer.twitter.com → Projects & Apps → your app
2. In App Settings → Keys and Tokens
3. Generate OAuth 2.0 Client ID and Client Secret
4. In n8n: Credentials → New → "X (Twitter) OAuth2 API"
   - Client ID + Client Secret from above
   - Callback URL: `http://192.168.0.28:5678/rest/oauth2-credential/callback`
5. Note the credential ID after saving — replace `TWITTER_CRED_ID` in workflow JSON

**Alternative if you don't want to pay $100/month:**
Skip Twitter (`post_twitter = 0` on all rows) and focus on Facebook + Instagram which are free.

---

### Facebook Page

1. Go to developers.facebook.com → your app (or create one, type: Business)
2. Add "Pages API" product
3. Get a **Page Access Token** (long-lived, 60 days):
   - Graph API Explorer → select your page → generate token
   - Extend it: `GET https://graph.facebook.com/oauth/access_token?grant_type=fb_exchange_token&client_id=APP_ID&client_secret=APP_SECRET&fb_exchange_token=SHORT_TOKEN`
4. Get your **Page ID**: Facebook Page → About → scroll to bottom, or via Graph API Explorer

5. In n8n: Settings → Variables (or Workflow → Variables):
   - `FB_PAGE_TOKEN` = your long-lived Page Access Token
   - `FB_PAGE_ID` = your numeric Page ID

---

### Instagram Business

> Requires: Instagram Business or Creator account + linked to a Facebook Page

1. Same Facebook App as above
2. Add "Instagram Graph API" product in your app
3. Get your **Instagram User ID**:
   - `GET https://graph.facebook.com/v19.0/me/accounts?access_token=PAGE_TOKEN`
   - Then: `GET https://graph.facebook.com/v19.0/PAGE_ID?fields=instagram_business_account&access_token=PAGE_TOKEN`
4. In n8n Variables:
   - `IG_USER_ID` = your Instagram Business Account ID (numeric)

> **Image required:** Instagram feed posts must have an `image_url`. Posts with no image will fail.
> Set `post_instagram = 0` for text-only posts.

---

## Step 3 — Import the Workflow

1. In n8n UI: Workflows → Import → paste contents of `n8n-workflows/social-media-scheduler.json`
2. Open the "Post Tweet" node → update credential to your saved X credential
3. Verify MySQL nodes show the correct credential (`yI791T2LiqB957Vc`)
4. Set n8n Variables (Settings → Variables):
   - `FB_PAGE_TOKEN`
   - `FB_PAGE_ID`
   - `IG_USER_ID`
5. Activate the workflow

---

## Step 4 — Stop CT115 (Postiz)

Once workflow is active and tested:

```bash
ssh claude@192.168.0.10
sudo pct stop 115
sudo pct set 115 --onboot 0   # already 0, but confirm
```

Remove from Caddyfile on CT500:
```bash
ssh root@192.168.0.13
# Remove the social.call-on.media block from /etc/caddy/Caddyfile
caddy reload --config /etc/caddy/Caddyfile
```

---

## Step 5 — Scheduling Posts

Insert rows into `social_posts` in phpMyAdmin or via a simple form:

```sql
INSERT INTO social_posts (content, image_url, post_twitter, post_facebook, post_instagram, scheduled_at)
VALUES (
  'Your post content here',
  'https://your-image-url.jpg',  -- NULL if no image
  1,                              -- 1 = post to Twitter
  1,                              -- 1 = post to Facebook
  1,                              -- 1 = post to Instagram (needs image_url)
  '2026-06-01 09:00:00'
);
```

The n8n workflow polls every 5 minutes and picks up anything with `scheduled_at <= NOW()` and `status = 'pending'`.

---

## Monitoring

Check post results:

```sql
SELECT id, LEFT(content,50), post_twitter, post_facebook, post_instagram,
       status, twitter_status, facebook_status, instagram_status, posted_at, error_log
FROM social_posts
ORDER BY scheduled_at DESC
LIMIT 20;
```

Failed posts: `status = 'failed'` — check `error_log` column and n8n execution history.

---

## Optional: Quick Post Web Form

A simple PHP form on CT500 to add posts without phpMyAdmin:
- Drop a PHP file in `/var/www/html/` on CT500
- Password-protect it in the Caddyfile with `basicauth`
- Let me know and I'll build it
