// OpenAPI 3 spec, served at /api/docs (UI) and /api/docs.json (raw).
// Keep in sync with routes/*.js. All responses use the { success, message, data } envelope.

const { POSE_KEYS, AREAS } = require('../models/Stretch');
const routineExample = require('./routineExample');

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

const nullData = { type: 'object', nullable: true, example: null };

// Swagger UI ignores `example: null` inside a schema and shows `data: {}`, so
// responses with no data get an explicit example on the media type instead.
const okResponse = (description, dataSchema, message) => ({
  description,
  content: {
    'application/json': {
      schema: envelope(dataSchema, message),
      ...(dataSchema === nullData && { example: { success: true, message, data: null } }),
    },
  },
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

const emailProp = { type: 'string', format: 'email', example: 'user@example.com' };
const auth = [{ bearerAuth: [] }];
const serverErr = err('Unhandled server error', 'Internal server error');

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
  tags: [{ name: 'Health' }, { name: 'Auth' }, { name: 'Users' }, { name: 'Stretches' }, { name: 'Routines' }, { name: 'Custom Routines' }, { name: 'Active Routines' }, { name: 'Plans' }],
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
        required: ['poseKey', 'name', 'position', 'areas', 'feel'],
        properties: {
          poseKey: {
            type: 'string',
            enum: POSE_KEYS,
            example: 'quad',
            description: 'Unique. Must match a StretchPoses constant in the app, since the figure is drawn from it.',
          },
          name: { type: 'string', example: 'Standing Quad Stretch' },
          position: { type: 'string', enum: ['standing', 'seated', 'floor'] },
          areas: {
            type: 'array',
            minItems: 1,
            items: { type: 'string', enum: AREAS },
            example: ['quads'],
          },
          isEachSide: { type: 'boolean', default: false },
          isDynamic: { type: 'boolean', default: false },
          isKneeling: { type: 'boolean', default: false },
          level: { type: 'string', enum: ['beginner', 'intermediate', 'advanced'], default: 'beginner' },
          equipment: { type: 'array', items: { type: 'string' } },
          defaultHoldSeconds: { type: 'integer', minimum: 10, maximum: 90, default: 30, description: 'Per side, in seconds.' },
          defaultRepCount: { type: 'integer', minimum: 1, maximum: 5, default: 1 },
          setupCue: { type: 'string' },
          feelCue: { type: 'string', nullable: true },
          feel: { type: 'string', example: 'Along the front of your thigh.' },
          steps: { type: 'array', items: { type: 'string' } },
          commonMistake: { type: 'string' },
          easier: { type: 'string' },
          harder: { type: 'string' },
          cautions: { type: 'string' },
          thumbnailUrl: { type: 'string', default: '', example: 'https://example.com/quad.jpg' },
          videoUrl: { type: 'string', default: '', example: 'https://example.com/quad.mp4' },
          isActive: { type: 'boolean', default: true, description: 'Inactive stretches are hidden from the list.' },
        },
      },
      Stretch: {
        allOf: [
          { $ref: '#/components/schemas/StretchInput' },
          {
            type: 'object',
            properties: {
              _id: { type: 'string' },
              totalHoldSeconds: {
                type: 'integer',
                readOnly: true,
                description: 'Computed by the server: hold seconds x reps x (2 if isEachSide). Never taken from the client.',
              },
              createdAt: { type: 'string', format: 'date-time' },
              updatedAt: { type: 'string', format: 'date-time' },
              __v: { type: 'integer' },
            },
          },
        ],
      },

      RoutineItemInput: {
        type: 'object',
        description: 'One stretch in a routine. Send `stretch` (Stretch _id), `poseKey`, or both (they must match). Both are stored and returned.',
        properties: {
          stretch: { type: 'string', description: 'Stretch _id.' },
          poseKey: { type: 'string', enum: POSE_KEYS, example: 'reach', description: 'Alternative to `stretch`. If both are sent they must refer to the same stretch.' },
          holdSeconds: { type: 'integer', minimum: 10, maximum: 90, default: 30, description: 'Per side, in seconds.' },
          repCount: { type: 'integer', minimum: 1, maximum: 5, default: 1 },
        },
      },
      RoutineInput: {
        type: 'object',
        required: ['name', 'stretches'],
        properties: {
          name: { type: 'string', example: 'Morning', description: 'Unique.' },
          description: { type: 'string', example: 'A quick wake-up for a stiff neck and shoulders.' },
          level: { type: 'string', enum: ['beginner', 'intermediate', 'advanced'], default: 'beginner' },
          tags: { type: 'array', items: { type: 'string' }, example: ['For your shoulders'] },
          transitionSeconds: { type: 'integer', nullable: true, minimum: 0, default: null, description: 'Seconds to get into each stretch. null = Auto.' },
          stretches: {
            type: 'array',
            minItems: 1,
            description: 'In play order.',
            items: { $ref: '#/components/schemas/RoutineItemInput' },
          },
          isActive: { type: 'boolean', default: true, description: 'Inactive routines are hidden from the list.' },
        },
      },
      Routine: {
        type: 'object',
        example: routineExample,
        properties: {
          _id: { type: 'string' },
          name: { type: 'string', example: 'Morning' },
          description: { type: 'string' },
          level: { type: 'string', enum: ['beginner', 'intermediate', 'advanced'] },
          tags: { type: 'array', items: { type: 'string' } },
          transitionSeconds: { type: 'integer', nullable: true },
          stretches: {
            type: 'array',
            description: 'In play order. `stretch` is the full Stretch document.',
            items: {
              type: 'object',
              properties: {
                stretch: { allOf: [{ $ref: '#/components/schemas/Stretch' }], nullable: true, description: 'Full Stretch document; null if that stretch was deleted.' },
                holdSeconds: { type: 'integer' },
                repCount: { type: 'integer' },
              },
            },
          },
          areas: { type: 'array', readOnly: true, items: { type: 'string', enum: AREAS }, description: 'Computed: union of the stretches\' areas.' },
          equipment: { type: 'array', readOnly: true, items: { type: 'string' }, description: 'Computed: union of the stretches\' equipment. Empty means none.' },
          stretchCount: { type: 'integer', readOnly: true },
          totalSeconds: { type: 'integer', readOnly: true, description: 'Computed: sum of hold x reps x (2 if the stretch is each side).' },
          minutes: { type: 'integer', readOnly: true, description: 'totalSeconds in minutes, rounded, at least 1.' },
          sequence: { type: 'string', readOnly: true, example: 'Standing → Floor', description: 'Computed: positions in order, consecutive duplicates collapsed.' },
          isActive: { type: 'boolean' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
          __v: { type: 'integer' },
        },
      },
      CustomRoutineInput: {
        type: 'object',
        required: ['name', 'stretches'],
        description: 'The owner is taken from the token. `areas`, `equipment`, `stretchCount`, `totalSeconds` and `sequence` are computed by the server.',
        properties: {
          name: { type: 'string', example: 'My desk reset', description: 'Unique per user.' },
          description: { type: 'string', example: 'Quick stretches between meetings.' },
          level: { type: 'string', enum: ['beginner', 'intermediate', 'advanced'], default: 'beginner' },
          tags: { type: 'array', items: { type: 'string' }, example: ['Desk'] },
          transitionSeconds: { type: 'integer', nullable: true, minimum: 0, default: null, description: 'Seconds to get into each stretch. null = Auto.' },
          stretches: {
            type: 'array',
            minItems: 1,
            description: 'In play order.',
            items: { $ref: '#/components/schemas/RoutineItemInput' },
          },
        },
      },
      CustomRoutine: {
        type: 'object',
        properties: {
          _id: { type: 'string' },
          user: { type: 'string', description: 'Owner (User _id).' },
          name: { type: 'string', example: 'My desk reset' },
          description: { type: 'string' },
          level: { type: 'string', enum: ['beginner', 'intermediate', 'advanced'] },
          tags: { type: 'array', items: { type: 'string' } },
          transitionSeconds: { type: 'integer', nullable: true },
          stretches: { $ref: '#/components/schemas/Routine/properties/stretches' },
          areas: { $ref: '#/components/schemas/Routine/properties/areas' },
          equipment: { $ref: '#/components/schemas/Routine/properties/equipment' },
          stretchCount: { type: 'integer', readOnly: true },
          totalSeconds: { type: 'integer', readOnly: true },
          minutes: { type: 'integer', readOnly: true },
          sequence: { type: 'string', readOnly: true, example: 'Standing → Floor' },
          createdAt: { type: 'string', format: 'date-time' },
          updatedAt: { type: 'string', format: 'date-time' },
          __v: { type: 'integer' },
        },
      },
      ActiveRoutine: {
        type: 'object',
        properties: {
          _id: { type: 'string' },
          user: { type: 'string', description: 'Owner (User _id).' },
          routineType: { type: 'string', enum: ['system', 'custom'], description: 'system = Routine collection, custom = CustomRoutine collection.' },
          routineId: { type: 'string', description: 'The source routine\'s _id.' },
          source: { type: 'string', enum: ['plan', 'user'], description: 'plan = started from today\'s plan card, user = picked by the user.' },
          routineName: { type: 'string', description: 'Copied when the routine begins.', example: 'Morning Stretch' },
          stretches: {
            type: 'array',
            description: 'Snapshot taken at Begin, in play order. `stretch` is the full stretch on Current and History.',
            items: { $ref: '#/components/schemas/Routine/properties/stretches/items' },
          },
          totalStretch: { type: 'integer', example: 5 },
          completedStretch: { type: 'integer', description: 'Resume position: 2 means the next stretch is the third one.', example: 2 },
          status: { type: 'string', enum: ['inProgress', 'completed'] },
          startedAt: { type: 'string', format: 'date-time' },
          completedAt: { type: 'string', format: 'date-time', nullable: true },
          updatedAt: { type: 'string', format: 'date-time' },
          __v: { type: 'integer' },
        },
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
          500: serverErr,
        },
      },
      patch: {
        tags: ['Users'],
        summary: 'Update the signed-in user profile',
        security: auth,
        requestBody: jsonBody({ $ref: '#/components/schemas/UserUpdate' }, { country: 'India', minutesPerDay: 15 }),
        responses: {
          200: okResponse('Updated profile', { $ref: '#/components/schemas/User' }, 'Profile updated'),
          400: err('Validation error', 'Cast to Number failed for value "abc" (type string) at path "age"'),
          401: err('Missing or invalid token', 'Invalid or expired token'),
          404: err('User not found', 'User not found'),
          500: serverErr,
        },
      },
    },
    '/api/stretches': {
      get: {
        tags: ['Stretches'],
        summary: 'List active stretches (sorted by name; inactive ones are hidden)',
        responses: {
          200: okResponse('Stretches', { type: 'array', items: { $ref: '#/components/schemas/Stretch' } }, 'Stretches fetched'),
          500: serverErr,
        },
      },
      post: {
        tags: ['Stretches'],
        summary: 'Create a stretch (no auth yet, lock down before shipping)',
        requestBody: jsonBody({ $ref: '#/components/schemas/StretchInput' }, {
          poseKey: 'child',
          name: "Child's Pose",
          position: 'floor',
          areas: ['lowerback', 'shoulders', 'hips'],
          level: 'beginner',
          equipment: ['mat'],
          isEachSide: false,
          isDynamic: false,
          isKneeling: true,
          defaultHoldSeconds: 45,
          defaultRepCount: 1,
          setupCue: 'Kneel on a mat with your big toes touching.',
          feelCue: 'Feel your back widen with each breath.',
          feel: 'Across your lower back and shoulders.',
          steps: [
            'Sit back onto your heels.',
            'Walk your hands forward and lower your chest.',
            'Rest your forehead down and breathe slowly.',
          ],
          commonMistake: 'Lifting the hips away from the heels.',
          easier: 'Place a cushion under your hips or chest.',
          harder: 'Walk your hands to one side to stretch the opposite flank.',
          cautions: 'Knee pain: place a folded towel behind the knees.',
          thumbnailUrl: 'https://picsum.photos/seed/quad/640/360.jpg',
          videoUrl: 'https://flutter.github.io/assets-for-api-docs/assets/videos/bee.mp4',
          isActive: true,
        }),
        responses: {
          201: okResponse('Created. The record is saved; nothing is returned in data.', nullData, 'Stretch created'),
          400: err('Validation error', 'Stretch validation failed: name: Path `name` is required.'),
          409: err('A stretch with this poseKey already exists', 'A stretch with this poseKey already exists'),
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
          500: serverErr,
        },
      },
      delete: {
        tags: ['Stretches'],
        summary: 'Delete a stretch permanently',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: {
          200: okResponse('Deleted', nullData, 'Stretch deleted'),
          400: err('Invalid id', 'Cast to ObjectId failed'),
          404: err('Not found', 'Stretch not found'),
          500: serverErr,
        },
      },
    },
    '/api/routines': {
      get: {
        tags: ['Routines'],
        summary: 'List active routines shown to every user (sorted by name; inactive ones are hidden)',
        responses: {
          200: okResponse('Routines', { type: 'array', items: { $ref: '#/components/schemas/Routine' } }, 'Routines fetched'),
          500: serverErr,
        },
      },
      post: {
        tags: ['Routines'],
        summary: 'Create a routine (no auth yet, lock down before shipping)',
        requestBody: jsonBody({ $ref: '#/components/schemas/RoutineInput' }, {
          name: 'Morning',
          description: 'A quick wake-up for a stiff neck and shoulders.',
          level: 'beginner',
          tags: [],
          stretches: [
            { poseKey: 'reach', holdSeconds: 30, repCount: 1 },
            { poseKey: 'fold', holdSeconds: 30, repCount: 1 },
          ],
        }),
        responses: {
          201: okResponse('Created. The record is saved; nothing is returned in data.', nullData, 'Routine created'),
          400: err('Validation error, or an unknown poseKey / stretch id', 'Unknown poseKey: reach'),
          409: err('A routine with this name already exists', 'A routine with this name already exists'),
        },
      },
    },
    '/api/routines/{id}': {
      get: {
        tags: ['Routines'],
        summary: 'Get one routine',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: {
          200: okResponse('Routine', { $ref: '#/components/schemas/Routine' }, 'Routine fetched'),
          400: err('Invalid id', 'Cast to ObjectId failed'),
          404: err('Not found', 'Routine not found'),
          500: serverErr,
        },
      },
      delete: {
        tags: ['Routines'],
        summary: 'Delete a routine permanently',
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: {
          200: okResponse('Deleted', nullData, 'Routine deleted'),
          400: err('Invalid id', 'Cast to ObjectId failed'),
          404: err('Not found', 'Routine not found'),
          500: serverErr,
        },
      },
    },
    '/api/custom-routines': {
      get: {
        tags: ['Custom Routines'],
        summary: 'List the signed-in user\'s own routines (newest first)',
        security: auth,
        responses: {
          200: okResponse('Custom routines', { type: 'array', items: { $ref: '#/components/schemas/CustomRoutine' } }, 'Custom routines fetched'),
          401: err('Missing or invalid token', 'No token provided'),
          500: serverErr,
        },
      },
      post: {
        tags: ['Custom Routines'],
        summary: 'Create a routine for the signed-in user',
        security: auth,
        requestBody: jsonBody({ $ref: '#/components/schemas/CustomRoutineInput' }, {
          name: 'My desk reset',
          description: 'Quick stretches between meetings.',
          level: 'beginner',
          tags: ['Desk'],
          transitionSeconds: 5,
          stretches: [
            { poseKey: 'reach', holdSeconds: 30, repCount: 1 },
            { poseKey: 'fold', holdSeconds: 40, repCount: 2 },
          ],
        }),
        responses: {
          201: okResponse('Created. The record is saved; nothing is returned in data.', nullData, 'Custom routine created'),
          400: err('Validation error, or an unknown poseKey / stretch id', 'Unknown poseKey: reach'),
          401: err('Missing or invalid token', 'Invalid or expired token'),
          409: err('This user already has a routine with this name', 'You already have a routine with this name'),
        },
      },
    },
    '/api/custom-routines/{id}': {
      get: {
        tags: ['Custom Routines'],
        summary: 'Get one of the signed-in user\'s routines',
        security: auth,
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: {
          200: okResponse('Custom routine', { $ref: '#/components/schemas/CustomRoutine' }, 'Custom routine fetched'),
          400: err('Invalid id', 'Cast to ObjectId failed'),
          401: err('Missing or invalid token', 'No token provided'),
          404: err('Not found, or it belongs to another user', 'Custom routine not found'),
          500: serverErr,
        },
      },
      delete: {
        tags: ['Custom Routines'],
        summary: 'Delete one of the signed-in user\'s routines permanently',
        security: auth,
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        responses: {
          200: okResponse('Deleted', nullData, 'Custom routine deleted'),
          400: err('Invalid id', 'Cast to ObjectId failed'),
          401: err('Missing or invalid token', 'No token provided'),
          404: err('Not found, or it belongs to another user', 'Custom routine not found'),
          500: serverErr,
        },
      },
    },
    '/api/plans/today': {
      get: {
        tags: ['Plans'],
        summary: 'Today\'s routine for the signed-in user',
        description: 'From the user\'s saved plan, built from their onboarding answers: the routines that match the user\'s body areas or goals become days of the plan, ordered best match first. Safety rules (no floor / no kneeling, moderate or serious injuries, pregnancy, recent surgery) are never bypassed, and if nothing fits equipment, level and time those are relaxed. The plan is saved and rebuilt when the answers or the matching routines change; day 1 is the day it was built.',
        security: auth,
        parameters: [
          { name: 'date', in: 'query', required: false, description: 'The user\'s local date. Defaults to today at tzOffset.', schema: { type: 'string', example: '2026-10-01' } },
          { name: 'tzOffset', in: 'query', required: false, description: 'Minutes from UTC (IST = 330). Defaults to 0.', schema: { type: 'integer', example: 330 } },
        ],
        responses: {
          200: okResponse('Today\'s routine, in the same shape as GET /api/routines/{id}, plus completedToday', {
            allOf: [
              { $ref: '#/components/schemas/Routine' },
              { type: 'object', properties: { reason: { type: 'string', description: 'Why this routine is on the user\'s plan.' }, planDays: { type: 'integer' }, todayDay: { type: 'integer' }, completedToday: { type: 'boolean', description: 'The user completed a routine started from today\'s plan (source plan) on this date.' } } },
            ],
          }, 'Today\'s plan fetched'),
          400: err('Bad date or tzOffset', 'date must be a real date as YYYY-MM-DD'),
          401: err('Missing or invalid token', 'No token provided'),
          404: err('No routine is safe for this profile', 'No routine fits your profile yet'),
          500: serverErr,
        },
      },
    },
    '/api/plans/overview': {
      get: {
        tags: ['Plans'],
        summary: 'The user\'s whole plan: how many days, and the routine for each',
        description: 'The rotation behind GET /api/plans/today. `planDays` routines, one per day, repeating in order; `todayDay` says which day today is. Same rules, date and tzOffset as /today.',
        security: auth,
        parameters: [
          { name: 'date', in: 'query', required: false, description: 'The user\'s local date. Defaults to today at tzOffset.', schema: { type: 'string', example: '2026-10-01' } },
          { name: 'tzOffset', in: 'query', required: false, description: 'Minutes from UTC (IST = 330). Defaults to 0.', schema: { type: 'integer', example: 330 } },
        ],
        responses: {
          200: okResponse('The plan', {
            type: 'object',
            properties: {
              planDays: { type: 'integer', example: 4 },
              todayDay: { type: 'integer', description: '1-based day of the plan that today is.', example: 2 },
              summary: { type: 'string', description: 'One or two sentences on what the plan is for (AI plans only).' },
              source: { type: 'string', enum: ['rules'], description: 'How the plan was built.' },
              days: {
                type: 'array',
                items: {
                  type: 'object',
                  properties: {
                    day: { type: 'integer', example: 1 },
                    isToday: { type: 'boolean' },
                    reason: { type: 'string', description: 'Why this routine is on the plan.' },
                    routine: { $ref: '#/components/schemas/Routine' },
                  },
                },
              },
            },
          }, 'Plan overview fetched'),
          400: err('Bad date or tzOffset', 'date must be a real date as YYYY-MM-DD'),
          401: err('Missing or invalid token', 'No token provided'),
          404: err('No routine is safe for this profile', 'No routine fits your profile yet'),
          500: serverErr,
        },
      },
    },
    '/api/active-routines': {
      post: {
        tags: ['Active Routines'],
        summary: 'Begin a routine (or get the one already in progress)',
        description: 'Several routines can be in progress at once, each with its own progress. If this routine is already in progress nothing changes (200); otherwise a new record is saved (201). Fetch it with GET /current.',
        security: auth,
        requestBody: jsonBody({
          type: 'object',
          required: ['routineId', 'routineType'],
          properties: {
            routineId: { type: 'string', example: '6abb8c45bce3ed8ed19eb011' },
            routineType: { type: 'string', enum: ['system', 'custom'] },
            source: { type: 'string', enum: ['plan', 'user'], default: 'user', description: 'Send plan when started from today\'s plan card (system routines only). Starting an already in-progress routine as plan marks it as the plan\'s.' },
          },
        }, { routineId: '6abb8c45bce3ed8ed19eb011', routineType: 'system', source: 'plan' }),
        responses: {
          200: okResponse('This routine was already in progress; nothing is returned in data', nullData, 'Routine already in progress'),
          201: okResponse('Started. The record is saved; read it with GET /current.', nullData, 'Routine started'),
          400: err('Missing routineId, routineType is not system / custom, or source is invalid', "routineType must be 'system' or 'custom'"),
          401: err('Missing or invalid token', 'No token provided'),
          404: err('Routine not found (custom routines must belong to the user)', 'Routine not found'),
          500: serverErr,
        },
      },
    },
    '/api/active-routines/current': {
      get: {
        tags: ['Active Routines'],
        summary: 'Resume check: every routine in progress (latest activity first)',
        security: auth,
        responses: {
          200: okResponse('Routines in progress; an empty array when there are none. Match a tapped routine by routineType + routineId.', { type: 'array', items: { $ref: '#/components/schemas/ActiveRoutine' } }, 'Current routines fetched'),
          401: err('Missing or invalid token', 'No token provided'),
          500: serverErr,
        },
      },
    },
    '/api/active-routines/history': {
      get: {
        tags: ['Active Routines'],
        summary: 'Completed routines, newest first (stretches omitted)',
        security: auth,
        responses: {
          200: okResponse('Completed routines', { type: 'array', items: { $ref: '#/components/schemas/ActiveRoutine' } }, 'History fetched'),
          401: err('Missing or invalid token', 'No token provided'),
          500: serverErr,
        },
      },
    },
    '/api/active-routines/{id}/progress': {
      patch: {
        tags: ['Active Routines'],
        summary: 'Set how many stretches are done',
        description: 'Sets an absolute position from 0 to totalStretch, so a retried request cannot double count. Reaching totalStretch completes the routine. 0 starts it over and resets startedAt.',
        security: auth,
        parameters: [{ name: 'id', in: 'path', required: true, schema: { type: 'string' } }],
        requestBody: jsonBody({
          type: 'object',
          required: ['completedStretch'],
          properties: { completedStretch: { type: 'integer', minimum: 0, example: 3 } },
        }, { completedStretch: 3 }),
        responses: {
          200: okResponse('Saved (the routine completes when the total is reached); nothing is returned in data', nullData, 'Progress saved'),
          400: err('Not a whole number from 0 to totalStretch, or invalid id', 'completedStretch must be a whole number from 0 to 5'),
          401: err('Missing or invalid token', 'No token provided'),
          404: err('Not found, or it belongs to another user', 'Active routine not found'),
          409: err('The routine is already completed', 'Routine is already completed'),
          500: serverErr,
        },
      },
    },
  },
};
