const nodemailer = require('nodemailer');

const smtpUser = process.env.SMTP_USER || process.env.SMTP_USE;
const smtpPass = (process.env.SMTP_PASS || '').replace(/\s+/g, '');
const hasSmtp = !!(smtpUser && smtpPass);

const transport = hasSmtp
  ? nodemailer.createTransport(
      process.env.SMTP_HOST
        ? {
            host: process.env.SMTP_HOST,
            port: Number(process.env.SMTP_PORT || 587),
            secure: Number(process.env.SMTP_PORT) === 465,
            auth: {
              user: smtpUser,
              pass: smtpPass,
            },
          }
        : {
            service: 'gmail',
            auth: {
              user: smtpUser,
              pass: smtpPass,
            },
          }
    )
  : null;


async function sendCode(email, code, purpose) {
  if (!transport) {
    console.log(`[mailer] (No SMTP configured - simulation) (${purpose}) code for ${email}: ${code}`);
    return;
  }

  const isVerify = purpose === 'verify';
  const subject = isVerify ? 'Verify your Fitness App account' : 'Reset your password';
  const actionText = isVerify ? 'verify your email address' : 'reset your password';

  const html = `
    <div style="font-family: Arial, sans-serif; max-width: 500px; margin: 0 auto; padding: 24px; border: 1px solid #e0e0e0; border-radius: 12px; background-color: #ffffff;">
      <h2 style="color: #1a1a1a; margin-top: 0;">${subject}</h2>
      <p style="color: #555555; font-size: 16px;">
        Use the following verification code to ${actionText}:
      </p>
      <div style="text-align: center; margin: 30px 0;">
        <span style="display: inline-block; font-size: 32px; font-weight: bold; letter-spacing: 6px; color: #ff5722; background: #fff3e0; padding: 12px 24px; border-radius: 8px;">
          ${code}
        </span>
      </div>
      <p style="color: #777777; font-size: 14px; margin-bottom: 4px;">
        This code expires in 15 minutes.
      </p>
      <p style="color: #999999; font-size: 12px; margin-top: 20px; border-top: 1px solid #eeeeee; padding-top: 12px;">
        If you did not request this code, you can safely ignore this email.
      </p>
    </div>
  `;

  try {
    let from = (process.env.SMTP_FROM || '').trim();
    if (!from || !from.includes('@')) {
      from = `"Fitness App" <${smtpUser}>`;
    } else if (!from.includes('<') && from.includes(' ')) {
      const parts = from.trim().split(/\s+/);
      const emailPart = parts.pop();
      const namePart = parts.join(' ').replace(/["']/g, '');
      from = `"${namePart}" <${emailPart}>`;
    }

    const info = await transport.sendMail({
      from,
      to: email,
      subject,
      text: `Your code is ${code}. It expires in 15 minutes.`,
      html,
    });
    console.log(`[mailer] Sent ${purpose} email to ${email}: ${info.messageId}`);
  } catch (err) {
    console.error(`[mailer] Error sending email to ${email}:`, err.message);
  }
}

module.exports = { sendCode };

