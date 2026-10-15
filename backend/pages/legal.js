// Public legal and support pages: /, /privacy, /terms, /support, /delete-account.
// App Store Connect and Google Play ask for these as plain web URLs. Edit the
// constants below, not the page text, when the contact details change.
const express = require('express');

const APP = 'Loosen';
const COMPANY = 'Sightinfusion';
const EMAIL = 'anand@sightinfusion.com';
const UPDATED = '15 October 2026';

const esc = (s) => String(s).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

const ARROW =
  '<svg viewBox="0 0 24 24" width="20" height="20" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><line x1="5" y1="12" x2="19" y2="12"/><polyline points="12 5 19 12 12 19"/></svg>';

const CSS = `
:root{--bg:#fff;--soft:#f6f8f6;--ink:#14201b;--ink2:#566860;--line:#e4eae5;--accent:#1c6a56;--accent-soft:#e6f1ec;--warm:#a85d12;--warm-soft:#fdf3e6}
@media (prefers-color-scheme:dark){:root{--bg:#0e1411;--soft:#151d19;--ink:#e8efea;--ink2:#9fb0a8;--line:#25302b;--accent:#6fcdb0;--accent-soft:#18312a;--warm:#e6a966;--warm-soft:#2b2115}}
*{box-sizing:border-box}
html{-webkit-text-size-adjust:100%;scroll-behavior:smooth}
@media (prefers-reduced-motion:reduce){html{scroll-behavior:auto}}
body{margin:0;min-height:100vh;display:flex;flex-direction:column;background:var(--bg);color:var(--ink);font:16px/1.7 -apple-system,BlinkMacSystemFont,"Segoe UI",Roboto,Helvetica,Arial,sans-serif;-webkit-font-smoothing:antialiased}
a{color:var(--accent)}
:focus-visible{outline:2px solid var(--accent);outline-offset:2px;border-radius:4px}
.wrap{width:100%;max-width:1040px;margin:0 auto;padding:0 24px}

.bar{border-bottom:1px solid var(--line)}
.bar .wrap{display:flex;align-items:center;min-height:64px}
.brand{display:flex;align-items:center;gap:10px;color:var(--ink);text-decoration:none;font-weight:700;font-size:18px;letter-spacing:-.01em}
.mark{width:28px;height:28px;border-radius:8px;background:var(--accent);color:var(--bg);display:grid;place-items:center;font-size:15px;font-weight:800}

main.wrap{flex:1;padding-top:48px;padding-bottom:72px}
.head{margin-bottom:36px;max-width:680px}
h1{margin:0 0 8px;font-size:clamp(28px,4vw,38px);line-height:1.15;letter-spacing:-.02em;font-weight:750}
.meta{margin:0 0 14px;font-size:14px;color:var(--ink2)}
.lead{margin:0;font-size:17px;line-height:1.65;color:var(--ink2)}

.doc{max-width:720px}
.sec{padding:28px 0;border-top:1px solid var(--line);scroll-margin-top:16px}
.sec:first-of-type{border-top:0;padding-top:0}
.sec h2{display:flex;gap:12px;align-items:baseline;margin:0 0 16px;font-size:24px;line-height:1.3;letter-spacing:-.015em;font-weight:700}
.sec h2 .n{flex:none;min-width:28px;color:var(--accent);font-weight:700}
.sec h3{font-size:16px;margin:26px 0 6px}
.sec p,.sec ul,.sec ol{margin:0 0 16px}
.sec ul,.sec ol{padding-left:22px}
.sec li{margin:6px 0}
.sec li::marker{color:var(--accent)}
.sec>:last-child{margin-bottom:0}
em{font-style:normal;font-weight:600}
table{width:100%;border-collapse:collapse;font-size:15px;margin:8px 0 20px}
th,td{text-align:left;vertical-align:top;padding:12px 14px 12px 0;border-bottom:1px solid var(--line)}
th{font-size:12px;font-weight:600;text-transform:uppercase;letter-spacing:.06em;color:var(--ink2);border-bottom-color:var(--ink2)}
td:first-child{font-weight:600;width:28%}
.note{background:var(--accent-soft);border-radius:10px;padding:18px 22px;margin:0 0 36px}
.note p{margin:0}
.note p+p{margin-top:10px}
.note ul{margin:8px 0 0;padding-left:20px}
.note li{margin:4px 0}
.note li::marker{color:var(--accent)}
.warn{background:var(--warm-soft);border-left:3px solid var(--warm);border-radius:6px;padding:16px 20px;margin:0 0 18px}
.warn p{margin:0 0 10px}
.warn ul{margin:0;padding-left:20px}

.panel{max-width:720px;border:1px solid var(--line);border-radius:12px;padding:24px 28px;margin-bottom:16px}
.panel h2{margin:0 0 10px;font-size:19px;letter-spacing:-.01em}
.panel p,.panel ul,.panel ol{margin:0 0 12px}
.panel ul{padding-left:22px}
.panel li{margin:5px 0}
.panel li::marker{color:var(--accent)}
.panel>:last-child{margin-bottom:0}
.btn{display:inline-block;background:var(--accent);color:var(--bg);text-decoration:none;font-weight:600;padding:10px 18px;border-radius:8px}
.btn:hover{filter:brightness(1.1)}
.contact{display:flex;gap:16px 24px;align-items:center;flex-wrap:wrap}
.contact div{flex:1 1 300px}
.contact p{color:var(--ink2)}
.qa{max-width:720px}
.qa h2{margin:36px 0 4px;font-size:22px;letter-spacing:-.01em}
.qa h3{margin:0 0 6px;font-size:17px}
.qa div{padding:20px 0;border-bottom:1px solid var(--line)}
.qa div:last-child{border-bottom:0}
.qa p{margin:0;color:var(--ink2)}
.steps{list-style:none;counter-reset:s;padding:0!important;display:grid;gap:12px}
.steps li{counter-increment:s;display:flex;gap:14px;align-items:baseline;margin:0}
.steps li::before{content:counter(s);flex:none;width:26px;height:26px;border-radius:50%;border:1px solid var(--accent);color:var(--accent);display:grid;place-items:center;font-weight:700;font-size:13px}
.two{display:grid;grid-template-columns:1fr 1fr;gap:16px;max-width:720px;margin-bottom:16px}
.two .panel{margin:0}
.links{max-width:720px;border-top:1px solid var(--line)}
.links a{display:flex;justify-content:space-between;align-items:center;gap:16px;padding:20px 4px;border-bottom:1px solid var(--line);text-decoration:none;color:var(--ink)}
.links a:hover strong{color:var(--accent)}
.links strong{display:block;font-size:18px}
.links span{display:block;color:var(--ink2);font-size:15px}
.links svg{flex:none;color:var(--ink2)}

footer{border-top:1px solid var(--line)}
.foot{display:flex;flex-wrap:wrap;justify-content:space-between;gap:10px 24px;padding-top:22px;padding-bottom:22px;color:var(--ink2);font-size:14px}
.foot nav{display:flex;flex-wrap:wrap;gap:6px 20px}
.foot a{color:var(--ink2);text-decoration:none}
.foot a:hover{color:var(--accent)}

@media (max-width:600px){
  .wrap{padding:0 18px}
  main.wrap{padding-top:32px;padding-bottom:56px}
  .two{grid-template-columns:1fr}
  .panel{padding:20px}
  .sec{padding:28px 0}
  .sec h2{font-size:21px}
  table,thead,tbody,tr,th,td{display:block}
  thead{display:none}
  tr{padding:10px 0;border-bottom:1px solid var(--line)}
  td{border:0;padding:2px 0;width:auto!important}
  td:first-child{color:var(--accent)}
}
@media print{footer{display:none}}
`;

function shell({ title, description, head, main }) {
  const footLinks = [
    ['/privacy', 'Privacy Policy'],
    ['/terms', 'Terms of Use'],
    ['/support', 'Support'],
    ['/delete-account', 'Delete account'],
  ]
    .map(([href, label]) => `<a href="${href}">${label}</a>`)
    .join('');
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>${esc(title)} · ${APP}</title>
<meta name="description" content="${esc(description)}">
<meta name="color-scheme" content="light dark">
<style>${CSS}</style>
</head>
<body>
<header class="bar"><div class="wrap"><a class="brand" href="/"><span class="mark" aria-hidden="true">L</span>${APP}</a></div></header>
<main class="wrap">
  <div class="head">
    <h1>${head.title}</h1>
    ${head.meta ? `<p class="meta">${head.meta}</p>` : ''}
    ${head.lead ? `<p class="lead">${head.lead}</p>` : ''}
  </div>
${main}
</main>
<footer><div class="wrap foot"><span>&copy; ${new Date().getFullYear()} ${COMPANY}</span><nav aria-label="Footer">${footLinks}<a href="mailto:${EMAIL}">${EMAIL}</a></nav></div></footer>
</body>
</html>`;
}

// Legal documents: an <h1>, intro and optional summary note, then numbered
// <h2> sections, all on one page.
function docPage({ title, description, body }) {
  const parts = body.split(/<h2>([\s\S]*?)<\/h2>/);
  const pre = parts[0];
  const grab = (re) => (pre.match(re) || [])[1] || '';
  const note = (pre.match(/<div class="note">[\s\S]*?<\/div>/) || [''])[0];
  const sections = [];
  for (let i = 1; i < parts.length; i += 2) {
    const m = parts[i].match(/^(\d+)\.\s*([\s\S]*)$/);
    sections.push(`<section class="sec" id="s${m[1]}"><h2><span class="n">${m[1]}</span>${m[2]}</h2>${parts[i + 1]}</section>`);
  }
  return shell({
    title,
    description,
    head: {
      title: grab(/<h1>([\s\S]*?)<\/h1>/),
      meta: grab(/<p class="meta">([\s\S]*?)<\/p>/),
      lead: grab(/<p class="lead">([\s\S]*?)<\/p>/),
    },
    main: `<div class="doc">
${note}
${sections.join('\n')}
</div>`,
  });
}

const privacy = `
<h1>Privacy Policy</h1>
<p class="meta">Last updated ${UPDATED}</p>
<p class="lead">${APP} is a stretching app by ${COMPANY}. This page explains in plain language what we collect, why, and the choices you have.</p>

<div class="note">
<p><strong>At a glance</strong></p>
<ul>
<li>We collect what the app needs to work: your account, the answers you give during setup, and your activity in the app.</li>
<li>Health-related answers, such as pain areas, injuries or pregnancy, are used only to choose safe stretches for you. Never for ads.</li>
<li>We never sell your data. Ads come from Google AdMob.</li>
<li>You can delete your account and all its data in the app at any time.</li>
</ul>
</div>

<h2>1. What we collect</h2>
<ul>
<li><strong>Account.</strong> Your email address and a password (stored only as a one-way hash). If you sign in with Google or Apple, your account ID from them and the email and name they share (Apple may give a private relay address).</li>
<li><strong>Profile and setup.</strong> Name, age, gender, country, height, weight, lifestyle, sports, goals, equipment and time per day.</li>
<li><strong>Health-related answers.</strong> Pain areas, injuries, recent surgery, pregnancy, movement limits, your flexibility check and any stretches you mark as painful.</li>
<li><strong>Your activity.</strong> Sessions, streaks, favourites, reminders, custom routines and your daily plan.</li>
<li><strong>Technical data.</strong> Your IP address and request logs (kept by our hosting provider), short-lived counters that block abuse, and advertising identifiers collected by AdMob.</li>
</ul>
<p>We do not collect your precise location, contacts, photos, microphone recordings or payment details. The app has no analytics or crash-reporting tools.</p>

<h2>2. How we use it</h2>
<p>To run the app and build your daily plan, to email verification and password-reset codes, to keep the service secure, to show ads, and to meet legal obligations.</p>
<p>If you are in the EEA or UK, we rely on our contract with you (running the app), your consent (health-related answers, and ads where required) and our legitimate interests (security). By completing setup you consent to us using your health-related answers to choose suitable stretches. You can withdraw this by editing your answers in <em>Profile</em> or by deleting your account. We do not use your data to train AI models.</p>

<h2>3. Ads</h2>
<p>${APP} is free and shows ads from <strong>Google AdMob</strong>: banner and native ads inside some screens, an occasional full-screen ad after a session, and an ad when you return to the app. No ads appear during your first three sessions. AdMob may use your advertising identifier, IP address and ad interactions to serve and measure ads.</p>
<p>Where the law requires it, the app asks for your consent before any ad is requested. You can reset or limit your advertising identifier in your phone&rsquo;s privacy settings. We never give advertisers your profile, health answers or activity.</p>

<h2>4. Who else receives your data</h2>
<ul>
<li><strong>Vercel</strong> hosts our server and <strong>MongoDB Atlas</strong> stores your data.</li>
<li>An <strong>email provider</strong> sends your verification and reset codes.</li>
<li><strong>Google</strong> provides sign-in, ads and the app&rsquo;s fonts. <strong>Apple</strong> provides Sign in with Apple on iPhone.</li>
<li><strong>jsDelivr</strong> delivers the stretch videos.</li>
</ul>
<p>Vercel, MongoDB and the email provider act only on our instructions. Google and jsDelivr see your IP address when you load their content and follow their own privacy policies. We may also share data if the law requires it or in a sale of the business. Our providers may process data in India, the United States and the EU.</p>

<h2>5. Storing and deleting your data</h2>
<p>Your sign-in token is kept in your phone&rsquo;s secure storage. Reminders are local notifications scheduled by your phone. We keep your account data until you delete it.</p>
<p><strong>To delete everything,</strong> go to <em>Profile &rarr; Account &amp; security &rarr; Delete my account and data</em>. Your profile, health answers, history, routines, plans, favourites and reminders are removed immediately and backups are overwritten in their normal cycle. Verification codes expire after 15 minutes and abuse counters within an hour. See <a href="/delete-account">Delete account</a> for details.</p>

<h2>6. Your rights</h2>
<p>You can see and correct most of your data in <em>Profile</em> and delete it in the app. You may also ask us for a copy of your data, to correct or erase it, to restrict or object to its use, or to withdraw consent, by emailing us from your account address. We reply within 30 days. You can complain to your data protection authority (in India, the Data Protection Board after using our grievance process below). California residents have the right to know, correct and delete their data and are never treated differently for using these rights.</p>
<p>We protect data with encryption in transit, hashed passwords, attempt limits on codes, and an access-restricted database.</p>

<h2>7. Children and changes</h2>
<p>${APP} is not for children under 13, and under 18s should use it with a parent&rsquo;s permission. If you think a child has given us data, tell us and we will delete it. If we make a material change to this policy we will update the date above and notify you in the app where the law requires it.</p>

<h2>8. Contact</h2>
<p>${COMPANY} &middot; <a href="mailto:${EMAIL}">${EMAIL}</a></p>
<p><strong>Grievance Officer (India).</strong> Email us with the subject &ldquo;Privacy grievance&rdquo;. We acknowledge complaints within 72 hours and aim to resolve them within 30 days.</p>
`;

const terms = `
<h1>Terms of Use</h1>
<p class="meta">Last updated ${UPDATED}</p>
<p class="lead">These terms are the agreement between you and ${COMPANY} for using the ${APP} app. By creating an account or using the app you accept them and our <a href="/privacy">Privacy Policy</a>.</p>

<h2>1. Using ${APP}</h2>
<ul>
<li>You must be at least 13 years old, and under 18s need a parent or guardian&rsquo;s permission.</li>
<li>Give accurate information, keep your password private, and tell us if you think your account has been accessed by someone else. You are responsible for activity on your account.</li>
<li>Do not break the law, access other people&rsquo;s accounts, probe or overload our servers, scrape or reverse engineer the app, or put unlawful or offensive content in it, including in custom routine names.</li>
</ul>

<h2>2. Health notice: not medical advice</h2>
<div class="warn">
<p><strong>${APP} gives general stretching guidance. It is not medical advice, diagnosis or treatment and does not replace a doctor or physiotherapist.</strong></p>
<ul>
<li>Talk to a health professional before you start if you are pregnant, recovering from surgery or injury, have a medical condition, or are unsure stretching is safe for you.</li>
<li>Stretch gently. Stop straight away if you feel sharp pain, dizziness, numbness or tingling, and get medical help if it continues.</li>
<li>Routines are based on the answers you give, which we cannot verify. You use ${APP} at your own risk and are responsible for working within your limits.</li>
</ul>
</div>

<h2>3. Your content and ours</h2>
<p>You own the routines you create and allow us to store them to run the app for you. The app, its routines, descriptions, videos, audio and software belong to ${COMPANY} or its licensors. We give you a personal, non-transferable licence to use the app for your own non-commercial use.</p>

<h2>4. Ads and third-party services</h2>
<p>${APP} is free and supported by ads from Google AdMob, shown in some screens, after some sessions and when you return to the app. Features such as Google Sign-In and Sign in with Apple depend on third-party services with their own terms, and we are not responsible for them or for the content of ads.</p>

<h2>5. Changes and ending</h2>
<p>We may change, suspend or stop features at any time, and may close accounts that break these terms. You can stop using the app and delete your account whenever you like (see <a href="/delete-account">Delete account</a>). We will tell you in the app or by email before a material change to these terms takes effect; using the app afterwards means you accept it.</p>

<h2>6. Warranties and liability</h2>
<p>To the fullest extent the law allows, ${APP} is provided &ldquo;as is&rdquo; and &ldquo;as available&rdquo;, with no promise of any fitness, flexibility or health result or of uninterrupted service. We are not liable for indirect or consequential losses, and our total liability to you is limited to INR 1,000. Nothing here limits liability that cannot be limited by law, including for death or personal injury caused by negligence, or your statutory consumer rights.</p>

<h2>7. Governing law and contact</h2>
<p>These terms are governed by the laws of India, and the courts of India have jurisdiction, without limiting any mandatory consumer rights you have where you live. If part of these terms is unenforceable, the rest stays in force. Questions or problems? Email <a href="mailto:${EMAIL}">${EMAIL}</a> and we will try to resolve it first.</p>
`;

const qa = (q, a) => `<div><h3>${q}</h3><p>${a}</p></div>`;

const supportPage = () =>
  shell({
    title: 'Support',
    description: `Get help with ${APP}: contact details and answers to common questions.`,
    head: {
      title: 'Support',
      lead: `Questions, problems or feedback about ${APP}? We read every message and usually reply within two working days.`,
    },
    main: `
<section class="panel contact">
  <div>
    <h2>Email us</h2>
    <p>Use the email address on your account. If something is not working, add your phone model, operating system version and what you were doing.</p>
  </div>
  <a class="btn" href="mailto:${EMAIL}">${EMAIL}</a>
</section>

<section class="qa">
<h2>Common questions</h2>
${qa('I did not get my verification or reset code', 'Check your spam folder, then use <em>Resend code</em> in the app. Codes last 15 minutes. After several wrong tries a code stops working and you need to request a new one.')}
${qa('I forgot my password', 'On the login screen choose <em>Forgot your password?</em>, enter your email, then enter the code we send and choose a new one. If you signed up with Google or Apple, tap <em>Continue with Google</em> or <em>Continue with Apple</em> instead.')}
${qa('My reminders are not arriving', `Make sure notifications are allowed for ${APP} in your phone settings and that battery saver is not restricting the app. On Android 12 and later, also allow alarms and reminders for the app.`)}
${qa('A stretch hurts', 'Stop right away. After your session, mark the stretch as painful so routines containing it are left out of your plan. If pain continues, please see a health professional. Read our <a href="/terms#s2">health notice</a>.')}
${qa('How do I delete my account?', 'Go to <em>Profile &rarr; Account &amp; security &rarr; Delete my account and data</em>. Full details are on the <a href="/delete-account">Delete account</a> page.')}
${qa('How is my data used?', 'Read our <a href="/privacy">Privacy Policy</a>. It explains what we collect, why, and who we share it with.')}
</section>`,
  });

const deletePage = () =>
  shell({
    title: 'Delete your account',
    description: `How to delete your ${APP} account and what happens to your data.`,
    head: {
      title: 'Delete your account',
      lead: `You can delete your ${APP} account and its data yourself, any time, from inside the app.`,
    },
    main: `
<section class="panel">
  <h2>In the app</h2>
  <ol class="steps">
    <li><div>Open ${APP} and sign in.</div></li>
    <li><div>Tap <strong>Profile</strong>, then <strong>Account &amp; security</strong>.</div></li>
    <li><div>Tap <strong>Delete my account and data</strong> and confirm. It happens straight away and cannot be undone.</div></li>
  </ol>
</section>

<div class="two">
  <section class="panel">
    <h2>What is deleted</h2>
    <ul>
      <li>Account details: email address, password hash and Google or Apple identifier</li>
      <li>Your profile and health-related answers</li>
      <li>Session history, streaks and daily plans</li>
      <li>Active routines, custom routines and favourites</li>
      <li>Reminder settings (reminders on your phone are cancelled when you sign out)</li>
    </ul>
  </section>
  <section class="panel">
    <h2>What may remain</h2>
    <p>Copies in our database provider&rsquo;s backups are overwritten in their normal backup cycle. Short-lived abuse-protection counters expire on their own within an hour. Emails you sent to support may be kept as a record of the request. We keep nothing else that identifies you, unless the law requires it.</p>
    <p>Ads come from Google AdMob. To reset or limit your advertising identifier, use your phone&rsquo;s privacy settings. See our <a href="/privacy">Privacy Policy</a>.</p>
  </section>
</div>

<section class="panel">
  <h2>If you cannot open the app</h2>
  <p>Email <a href="mailto:${EMAIL}?subject=Delete%20my%20${APP}%20account">${EMAIL}</a> from the address registered to your account with the subject &ldquo;Delete my ${APP} account&rdquo;. We will confirm your request and delete the account within 30 days, usually much sooner.</p>
</section>`,
  });

const hubRow = (href, heading, text) =>
  `<a href="${href}"><div><strong>${heading}</strong><span>${text}</span></div>${ARROW}</a>`;

const hubPage = () =>
  shell({
    title: 'Legal and support',
    description: `Privacy Policy, Terms of Use, support and account deletion for the ${APP} stretching app.`,
    head: {
      title: `${APP}: privacy, terms and support`,
      lead: `${APP} builds a short daily stretching routine around your body. Here is how we look after your information, the rules for using the app, and where to get help.`,
    },
    main: `<div class="links">
${hubRow('/privacy', 'Privacy Policy', 'What we collect, why, who sees it and the choices you have')}
${hubRow('/terms', 'Terms of Use', 'The agreement for using the app, including an important health notice')}
${hubRow('/support', 'Support', 'Contact us and find answers to common questions')}
${hubRow('/delete-account', 'Delete your account', 'How to remove your account and what happens to your data')}
</div>`,
  });

const pages = {
  '/': hubPage(),
  '/privacy': docPage({
    title: 'Privacy Policy',
    description: `How ${APP} collects, uses and protects your information.`,
    body: privacy,
  }),
  '/terms': docPage({
    title: 'Terms of Use',
    description: `The terms for using the ${APP} stretching app, including an important health notice.`,
    body: terms,
  }),
  '/support': supportPage(),
  '/delete-account': deletePage(),
};

const router = express.Router();

for (const [path, html] of Object.entries(pages)) {
  router.get(path, (_req, res) => {
    res.set('Cache-Control', 'no-cache');
    res.type('html').send(html);
  });
}

const aliases = {
  '/privacy-policy': '/privacy',
  '/terms-of-service': '/terms',
  '/terms-and-conditions': '/terms',
  '/tos': '/terms',
  '/help': '/support',
  '/contact': '/support',
  '/account-deletion': '/delete-account',
  '/delete': '/delete-account',
};
for (const [from, to] of Object.entries(aliases)) {
  router.get(from, (_req, res) => res.redirect(301, to));
}

module.exports = router;
