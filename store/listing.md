# Loosen: store listing and privacy forms

Copy these into App Store Connect and Google Play Console. Re-check them against the app on the day you submit; the privacy forms must match what the app really does.

## URLs

| Field | URL |
|---|---|
| Privacy policy | https://fitness-backend-eight.vercel.app/privacy |
| Terms of use (Apple: add to the description or custom EULA field) | https://fitness-backend-eight.vercel.app/terms |
| Support URL | https://fitness-backend-eight.vercel.app/support |
| Account deletion URL (Play: Data safety > Data deletion) | https://fitness-backend-eight.vercel.app/delete-account |
| Contact email | anand@sightinfusion.com (change `EMAIL` in `backend/pages/legal.js` if you use another) |

## Listing text

**App name:** Loosen
**Apple subtitle (30 chars):** Daily stretching for you
**Play short description (80 chars):** Daily stretching routines built around your body, limits and schedule.
**Category:** Health & Fitness
**Apple keywords (100 chars):** stretching,flexibility,mobility,yoga,back pain,desk,warm up,posture,routine,reminder,physio

**Full description**

Loosen builds a short daily stretching routine around you: the tight spots you have, the injuries you are working around, the equipment you actually own and the minutes you can spare.

How it works
- Answer a few quick questions and get a plan made for your body, refreshed every day.
- A calm voice talks you through each hold, so you never need to look at your phone. Prefer beeps or silence? Switch any time.
- Skip anything that hurts. Mark a stretch as painful and Loosen leaves routines that contain it out of your plan.
- Build your own routines from the stretch library and save your favourites.
- Follow your streak, history and flexibility progress.
- Set reminders that fit your day, such as a desk break or an evening wind-down.

Made to be gentle
- Routines respect limits like no kneeling, no floor work, recent surgery and pregnancy.
- Free to use, with ads. No subscriptions, no in-app purchases.
- Delete your account and all its data from inside the app, any time.

Loosen offers general stretching guidance and is not medical advice. Talk to a doctor or physiotherapist before starting if you are pregnant, injured or unsure whether stretching is right for you.

**What's new (first release):** Welcome to Loosen. Your daily stretching plan, guided by voice, built around your body.

## Age rating

- Apple: 4+. No objectionable content, no unrestricted web access, no user-generated content shared with others. Answer "None" to every content question, including "Medical or Treatment Information" (the app gives general stretching guidance, not diagnosis).
- Google Play (IARC questionnaire): category "Reference, News or Educational" or "Health & Fitness" style apps answer No to violence, sexual content, language, controlled substances and gambling. Expected rating: Everyone. Declare that the app contains ads.
- Target audience: 13 and over (matches the Privacy Policy and Terms). Do not select "children" as a target group; that triggers the Families policy and rules out AdMob personalised ads.

## Google Play: Data safety form

Does the app collect or share user data? **Yes.** Is all data encrypted in transit? **Yes (HTTPS).** Can users request deletion? **Yes**, in the app and at the deletion URL above. Is the app following Families policy? **No.**

| Data type | Collected | Shared | Purpose | Optional | Notes |
|---|---|---|---|---|---|
| Email address | Yes | No | Account management, app functionality | No | |
| Name | Yes | No | Account management, personalisation | Yes | |
| User IDs (account ID, Google ID, Apple ID) | Yes | No | Account management | No | |
| Health info (pain areas, injuries, surgery, pregnancy, limits) | Yes | No | App functionality, personalisation | Yes | Never used for ads |
| Fitness info (flexibility level, sessions, streaks, history) | Yes | No | App functionality, personalisation | No | |
| Other user-generated content (custom routines) | Yes | No | App functionality | Yes | |
| Device or other IDs (advertising ID) | Yes | Yes (Google AdMob) | Advertising | No | Collected by the AdMob SDK |
| Approximate location (derived from IP by AdMob) | Yes | Yes (Google AdMob) | Advertising | No | Verify against Google's current AdMob disclosure guidance |
| App interactions (ad interactions) | Yes | Yes (Google AdMob) | Advertising, analytics | No | Same |

Not collected: precise location, contacts, photos or videos, audio, files, calendar, financial info, messages, web browsing history, crash logs or diagnostics (revisit if you add a crash reporter).

Google publishes the exact list of what AdMob collects: search "Google Play Data safety AdMob". Re-check it when you submit; if it differs from this table, follow Google's list.

## Apple: App Privacy ("nutrition label")

Do you or your third-party partners collect data? **Yes.** Data is linked to the user's identity; tracking depends on AdMob settings (see below).

| Apple data type | Linked to user | Used for |
|---|---|---|
| Contact info: Email address, Name | Yes | App functionality, account |
| Health & Fitness: Health, Fitness | Yes | App functionality, personalisation |
| User content: Other user content (custom routines) | Yes | App functionality |
| Identifiers: User ID | Yes | App functionality |
| Identifiers: Device ID (advertising) | Yes | Third-party advertising |
| Usage data: Advertising data, Product interaction | Yes | Third-party advertising |
| Location: Coarse location (from IP, via AdMob) | Yes | Third-party advertising |

**Tracking:** if AdMob serves personalised ads on iOS it uses the advertising identifier for tracking, which means:
1. Answer Yes to tracking in App Privacy for the advertising data above.
2. Add `NSUserTrackingUsageDescription` to `ios/Runner/Info.plist` and show the App Tracking Transparency prompt before requesting ads (Google's UMP SDK can show it from the consent form you set up in AdMob > Privacy & messaging).
3. If you would rather not track, serve only non-personalised ads on iOS and answer No to tracking.

Also required for iOS: `PrivacyInfo.xcprivacy` (item 18), the Google SKAdNetwork identifiers in `Info.plist`, and the Sign in with Apple capability on the App ID (item 15, code is done; Apple requires it because the app offers Google sign-in).

## App review notes (Apple) / access instructions (Play)

> Loosen does not need an account to look around: tap "Explore with a sample account" on the welcome screen. To test sign-up, use any email you control; a 6-digit verification code is emailed. Or sign in with the demo account below (create it yourself before submitting; mark it onboarding-complete).
>
> Demo account: _email_ / _password_
>
> The app shows ads after the first three sessions (Google AdMob). There are no in-app purchases. Account deletion is in Profile > Account & security > Delete my account and data.

## Before you submit: checklist

- [ ] Sign in with Apple: enable the capability on the App ID and regenerate provisioning profiles. Deleting an account removes it from the database; the Apple-side link is not revoked (no key is configured).
- [ ] Replace the Google test AdMob ad unit IDs and app IDs with your real ones.
- [ ] Confirm the company name, contact email and governing law in `backend/pages/legal.js`, then redeploy.
- [ ] Open all four URLs in a browser and confirm they load.
- [ ] Add screenshots (Play: phone, plus 7" and 10" tablets if you list tablets; Apple: 6.9" and 6.5" iPhone, and iPad if supported).
- [ ] Upload the signed `.aab` (Play) and complete the Data safety form above.
- [ ] Complete App Privacy (Apple) and decide on the tracking prompt.
