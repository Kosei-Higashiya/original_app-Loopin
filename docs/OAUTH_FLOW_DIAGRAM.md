# Google OAuth Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                     Google OAuth Login Flow                         │
└─────────────────────────────────────────────────────────────────────┘

1. User clicks "Googleでログイン" button
   │
   ├─► Button renders from: app/views/devise/shared/_links.html.erb
   │
   └─► POST /users/auth/google_oauth2
       │
       ├─► Redirects to Google OAuth consent screen
       │   (User logs in with Google account)
       │
       └─► Google redirects back with authorization code
           │
           └─► GET /users/auth/google_oauth2/callback
               │
               ├─► OmniauthCallbacksController#google_oauth2
               │   │
               │   ├─► User.from_omniauth(auth)
               │   │   │
               │   │   ├─► Search by provider + uid
               │   │   │   │
               │   │   │   ├─► Found? ──► Return existing user
               │   │   │   │
               │   │   │   └─► Not found?
               │   │   │       │
               │   │   │       ├─► Search by email
               │   │   │       │   │
               │   │   │       │   ├─► Found? ──► Link OAuth to existing account
               │   │   │       │   │
               │   │   │       │   └─► Not found? ──► Create new user
               │   │   │
               │   │   └─► Return user
               │   │
               │   ├─► Sign in user
               │   │
               │   └─► Redirect to dashboard
               │
               └─► Success! User is logged in

┌─────────────────────────────────────────────────────────────────────┐
│                     Database Schema Changes                         │
└─────────────────────────────────────────────────────────────────────┘

users table:
  - id (existing)
  - email (existing)
  - encrypted_password (existing)
  - name (existing)
  + provider (new) ──────► 'google_oauth2' for Google users, NULL for email users
  + uid (new) ───────────► Google user ID, NULL for email users
  
  INDEX: [provider, uid] (unique)

┌─────────────────────────────────────────────────────────────────────┐
│                     User Types Comparison                           │
└─────────────────────────────────────────────────────────────────────┘

Email/Password User:
  provider: NULL
  uid: NULL
  encrypted_password: present
  email: user@example.com
  
Google OAuth User:
  provider: 'google_oauth2'
  uid: '123456789'
  encrypted_password: random (auto-generated)
  email: user@gmail.com
  
Linked Account (started with email, later added Google):
  provider: 'google_oauth2'
  uid: '123456789'
  encrypted_password: original password (still valid)
  email: user@example.com
  
  ► Can log in with either email/password OR Google!

┌─────────────────────────────────────────────────────────────────────┐
│                     Security Features                               │
└─────────────────────────────────────────────────────────────────────┘

✓ CSRF Protection
  - omniauth-rails_csrf_protection gem
  - Prevents CSRF attacks on OAuth flow
  
✓ Secure Token Storage
  - Environment variables for CLIENT_ID and CLIENT_SECRET
  - .env files excluded from git
  
✓ Unique Constraints
  - Database index on [provider, uid]
  - Prevents duplicate OAuth accounts
  
✓ Password Management
  - OAuth users get random password
  - Password validation skipped for OAuth users
  
✓ Account Linking
  - Automatic linking when email matches
  - Seamless transition from email to OAuth
```
