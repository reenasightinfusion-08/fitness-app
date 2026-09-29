// OpenAPI 3 spec, served at /api/docs (UI) and /api/docs.json (raw).
// Keep in sync with routes/*.js. All responses use the { success, message, data } envelope.

const envelope = (dataSchema, example) => ({
  type: 'object',
  required: ['success', 'message', 'data'],
  properties: {
    success: { type: 'boolean', example: true },
    message: { type: 'string', example: example || 'OK' },
    data: dataSchema,
  },
});

const jsonBody = (schema, example) => ({
  required: true,
  content: { 'application/json': { schema, ...(example && { example }) } },
});

const okResponse = (description, dataSchema, message) => ({
  description,
  content: { 'application/json': { schema: envelope(dataSchema, message) } },
});

const err = (description, message) => ({
  description,
  content: {
    'application/json': {
      schema: { $ref: '#/components/schemas/Error' },
      example: { success: false, message, data: null },
    },
  },
});

const nullData = { type: 'object', nullable: true, example: null };
const emailProp = { type: 'string', format: 'email', example: 'user@example.com' };
const auth = [{ bearerAuth: [] }];

module.exports = {
  openapi: '3.0.3',
  info: {
    title: 'Fitness App API',
    version: '1.0.0',
    description:
      'Every response uses the envelope `{ success, message, data }`. Errors return `success: false` and `data: null` (extra context such as `retryAfter` goes inside `data`).',
  },
  servers: [
    { url: 'https://fitness-backend-eight.vercel.app', description: 'Production' },
    { url: 'http://localhost:4000', description: 'Local' },
  ],
  tags: [{ name: 'Health' }, { name: 'Auth' }, { name: 'Users' }, { name: 'Stretches' }],
  components: {
    securitySchemes: { bearerAuth: { type: 'http', scheme: 'bearer', bearerFormat: 'JWT' } },
    schemas: {
      Error: {
        type: 'object',
        properties: {
          success: { type: 'boolean', example: false },
          message: { type: 'string', example: 'Something went wrong' },
          data: { type: 'object', nullable: true, example: null },
        },
      },
      TokenData: {
        type: 'object',
        properties: {
          token: { type: 'string', example: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...' },
          email: emailProp,
        },
      },
      User: {
        type: 'object',
        properties: {
          _id: { type: 'string' },
          email: emailProp,
          isVerified: { type: 'boolean' },
          name: { type: 'string' },
          age: { type: 'number', nullable: true },
          gender: { type: 'string', nullable: true },
          country: { type: 'string', nullable: true, example: 'India' },
          heightCm: { type: 'number', nullable: true },
          weightKg: { type: 'number', nullable: true },
          lifestyle: { type: 'string', nullable: true },
          sports: { type: 'array', items: { type: 'string' } },
          goals: { type: 'array', items: { type: 'string' } },
          painAreas: { type: 'array', items: { type: 'string' } },
          noKneel: { type: 'boolean' },
          noFloor: { type: 'boolean' },
          hadRecentSurgery: { type: 'boolean' },
          isPregnant: { type: 'boolean' },
          injurySeverity: { type: 'object', additionalProperties: { type: 'string' } },
          equipment: { type: 'array', items: { type: 'string' } },
          equipmentNone: { type: 'boolean' },
          flexAnswers: {
            type: 'array',
            items: {
              type: 'object',
              required: ['question', 'answer', 'score'],
              properties: {
                question: { type: 'string' },
                answer: { type: 'string' },
                score: { type: 'number' },
              },
            },
          },
          flexibilityLevel: { type: 'number', example: 1 },
          minutesPerDay: { type: 'number', example: 10 },
          timeOfDay: { type: 'string', nullable: true },
          reminderOn: { type: 'boolean' },
          reminderTime: {
            type: 'object',
            properties: { hour: { type: 'number', example: 8 }, minute: { type: 'number', example: 0 } },
          },
          safetyAcknowledged: { type: 'boolean' },
          onboardingComplete: { type: 'boolean' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
        },
      },
      UserUpdate: {
        type: 'object',
        description: 'Any subset of the profile fields. Other fields are ignored.',
        properties: {
          name: { type: 'string' },
          age: { type: 'number' },
          gender: { type: 'string' },
          country: { type: 'string', example: 'India' },
          heightCm: { type: 'number' },
          weightKg: { type: 'number' },
          lifestyle: { type: 'string' },
          sports: { type: 'array', items: { type: 'string' } },
          goals: { type: 'array', items: { type: 'string' } },
          painAreas: { type: 'array', items: { type: 'string' } },
          noKneel: { type: 'boolean' },
          noFloor: { type: 'boolean' },
          hadRecentSurgery: { type: 'boolean' },
          isPregnant: { type: 'boolean' },
          injurySeverity: { type: 'object', additionalProperties: { type: 'string' } },
          equipment: { type: 'array', items: { type: 'string' } },
          equipmentNone: { type: 'boolean' },
          flexAnswers: { $ref: '#/components/schemas/User/properties/flexAnswers' },
          flexibilityLevel: { type: 'number' },
          minutesPerDay: { type: 'number' },
          timeOfDay: { type: 'string' },
          reminderOn: { type: 'boolean' },
          reminderTime: { $ref: '#/components/schemas/User/properties/reminderTime' },
          safetyAcknowledged: { type: 'boolean' },
          onboardingComplete: { type: 'boolean' },
        },
      },
      StretchInput: {
        type: 'object',
        required: ['poseKey', 'name', 'position', 'feel'],
        properties: {
          poseKey: { type: 'string', example: 'standing_hamstring' },
          name: { type: 'string', example: 'Standing Hamstring Stretch' },
          position: { type: 'string', enum: ['standing', 'seated', 'floor'] },
          isEachSide: { type: 'boolean', default: false },
          isDynamic: { type: 'boolean', default: false },
          isKneeling: { type: 'boolean', default: false },
          level: { type: 'string', enum: ['beginner', 'intermediate', 'advanced'], default: 'beginner' },
          equipment: { type: 'array', items: { type: 'string' } },
          defaultHoldSeconds: { type: 'number', default: 30 },
          defaultRepCount: { type: 'number', default: 1 },
          setupCue: { type: 'string' },
          feelCue: { type: 'string', nullable: true },
          feel: { type: 'string', example: 'Back of the thigh' },
          steps: { type: 'array', items: { type: 'string' } },
          commonMistake: { type: 'string' },
          easier: { type: 'string' },
          harder: { type: 'string' },
          cautions: { type: 'string' },
          thumbnailUrl: { type: 'string' },
          videoUrl: { type: 'string' },
        },
      },
      Stretch: {
        allOf: [
          { $ref: '#/components/schemas/StretchInput' },
          {
            type: 'object',
            properties: {
              _id: { type: 'string' },
              createdAt: { type: 'string', format: 'date-time' },
              updatedAt: { type: 'string', format: 'date-time' },
            },
          },
        ],
      },
    },
  },
  paths: {
    '/health': {
      get: {
        tags: ['Health'],
        summary: 'Health check',
        responses: {
          200: okResponse('Server is up', { type: 'object', properties: { ok: { type: 'boolean', example: true } } }, 'Healthy'),
        },
      },
    },
    '/api/auth/signup': {
      post: {
        tags: ['Auth'],
        summary: 'Create an account and email a verification code',
        requestBody: jsonBody(
          { type: 'object', required: ['email', 'password'], properties: { email: emailProp, password: { type: 'string', minLength: 8 } } },
        ),
        responses: {
          200: okResponse('Verification code sent', nullData, 'Verification code sent'),
          400: err('Missing fields or password too short', 'Password must be at least 8 characters'),
          409: err('Email already registered and verified', 'Email already in use'),
          500: err('Server error', 'Signup failed: ...'),
        },
      },
    },
    '/api/auth/verify-email': {
      post: {
        tags: ['Auth'],
        summary: 'Verify email with the emailed code and sign in',
        requestBody: jsonBody(
          { type: 'object', required: ['email', 'code'], properties: { email: emailProp, code: { type: 'string', example: '123456' } } },
        ),
        responses: {
          200: okResponse('Verified, JWT returned', { $ref: '#/components/schemas/TokenData' }, 'Signed in'),
          400: err('Wrong code', "That code doesn't match"),
          500: err('Server error', 'Verification failed'),
        },
      },
    },
    '/api/auth/login': {
      post: {
        tags: ['Auth'],
        summary: 'Sign in with email and password',
        requestBody: jsonBody(
          { type: 'object', required: ['email', 'password'], properties: { email: emailProp, password: { type: 'string' } } },
        ),
        responses: {
          200: okResponse('JWT returned', { $ref: '#/components/schemas/TokenData' }, 'Signed in'),
          401: err('Bad credentials', 'Invalid email or password'),
          403: err('Email not verified', 'Please verify your email first'),
          500: err('Server error', 'Login failed'),
        },
      },
    },
    '/api/auth/forgot-password': {
      post: {
        tags: ['Auth'],
        summary: 'Email a password reset code',
        description: 'Always succeeds, whether or not the account exists.',
        requestBody: jsonBody({ type: 'object', required: ['email'], properties: { email: emailProp } }),
        responses: {
          200: okResponse('Request accepted', nullData, 'If that email exists, a code was sent'),
          500: err('Server error', 'Request failed'),
        },
      },
    },
    '/api/auth/resend-code': {
      post: {
        tags: ['Auth'],
        summary: 'Resend a verification or reset code (30s cooldown)',
        requestBody: jsonBody({
          type: 'object',
          required: ['email'],
          properties: { email: emailProp, purpose: { type: 'string', enum: ['verify', 'reset'], default: 'verify' } },
        }),
        responses: {
          200: okResponse('Code resent', nullData, 'Code resent'),
          429: {
            description: 'Cooldown active',
            content: {
              'application/json': {
                schema: { $ref: '#/components/schemas/Error' },
                example: { success: false, message: 'Please wait 20s before resending', data: { retryAfter: 20 } },
              },
            },
          },
          500: err('Server error', 'Could not resend code'),
        },
      },
    },
    '/api/auth/reset-password': {
      post: {
        tags: ['Auth'],
        summary: 'Set a new password using the reset code',
        requestBody: jsonBody({
          type: 'object',
          required: ['email', 'code', 'newPassword'],
          properties: { email: emailProp, code: { type: 'string', example: '123456' }, newPassword: { type: 'string', minLength: 8 } },
        }),
        responses: {
          200: okResponse('Password updated', nullData, 'Password updated'),
          400: err('Weak password, or invalid/expired code', 'Invalid or expired code'),
          500: err('Server error', 'Reset failed'),
        },
      },
    },
    '/api/users/me': {
      get: {
        tags: ['Users'],
        summary: 'Get the signed-in user profile',
        security: auth,
        responses: {
          200: okResponse('Profile', { $ref: '#/components/schemas/User' }, 'Profile fetched'),
          401: err('Missing or invalid token', 'No token provided'),
          404: err('User not found', 'User not found'),
        },
      },
      patch: {
        tags: ['Users'],
        summary: 'Update the signed-in user profile',
        security: auth,
        requestBody: jsonBody({ $ref: '#/components/schemas/UserUpdate' }, { country: 'India', minutesPerDay: 15 }),
        responses: {
          200: okResponse('Updated profile', { $ref: '#/components/schemas/User' }, 'Profile updated'),
          400: err('Validation error', 'Validation failed'),
          401: err('Missing or invalid token', 'Invalid or expired token'),
          404: err('User not found', 'User not found'),
        },
      },
    },
    '/api/stretches': {
      get: {
        tags: ['Stretches'],
        summary: 'List all stretches (sorted by name)',
        responses: {
          200: okResponse('Stretches', { type: 'array', items: { $ref: '#/components/schemas/Stretch' } }, 'Stretches fetched'),
        },
      },
      post: {
        tags: ['Stretches'],
        summary: 'Create a stretch (no auth yet, lock down before shipping)',
        requestBody: jsonBody({ $ref: '#/components/schemas/StretchInput' }),
        responses: {
          201: okResponse('Created', { $ref: '#/components/schemas/Stretch' }, 'Stretch created'),
          400: err('Validation error or duplicate poseKey', 'Path `name` is required.'),
        },
      },
    },
    '/api/stretches/{id}': {
      get: {
        tags: ['Stretches'],
        summary: 'Get one stretch',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: {
          200: okResponse('Stretch', { $ref: '#/components/schemas/Stretch' }, 'Stretch fetched'),
          400: err('Invalid id', 'Cast to ObjectId failed'),
          404: err('Not found', 'Stretch not found'),
        },
      },
      delete: {
        tags: ['Stretches'],
        summary: 'Delete a stretch permanently',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: {
          200: okResponse('Deleted', { type: 'object', nullable: true, example: null }, 'Stretch deleted'),
          400: err('Invalid id', 'Cast to ObjectId failed'),
          404: err('Not found', 'Stretch not found'),
        },
      },
    },
  },
};
