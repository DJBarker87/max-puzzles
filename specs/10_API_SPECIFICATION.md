# Max's Puzzles - API Specification

**Version:** 1.1  
**Last Updated:** January 2025  
**Author:** Dom Barker

---

## Overview

This document specifies the API endpoints for Max's Puzzles. The API uses a hybrid approach:

1. **Supabase Direct** - For simple CRUD operations with Row Level Security
2. **Custom REST Endpoints** - For complex business logic (purchases, sync, sessions)

---

## Authentication

### Supabase Auth (Parents)

Parents authenticate via Supabase Auth:
- `POST /auth/v1/signup` - Create account
- `POST /auth/v1/token?grant_type=password` - Login
- `POST /auth/v1/logout` - Logout

Returns JWT token for subsequent requests.

### Child Sub-Sessions

Children don't have Supabase Auth accounts. Instead:

1. Parent logs in (gets JWT)
2. Parent's session includes `family_id`
3. Child PIN verification happens via custom endpoint
4. Child session is a "sub-session" tracked client-side

---

## Custom REST Endpoints

Base URL: `/api/v1`

All endpoints require `Authorization: Bearer <jwt>` header (parent's token).

---

### Authentication & Family

#### POST /api/v1/auth/child-login

Verify child PIN and create sub-session.

**Request:**
```json
{
  "childId": "uuid",
  "pin": "1234"
}
```

**Response:**
```json
{
  "success": true,
  "child": {
    "id": "uuid",
    "displayName": "Max",
    "coins": 1234,
    "avatarConfig": { ... }
  }
}
```

**Errors:**
- `401` - Invalid PIN
- `404` - Child not found
- `403` - Child not in caller's family

---

#### POST /api/v1/auth/transfer-guest

Transfer guest progress to new account.

**Request:**
```json
{
  "guestData": {
    "coins": 500,
    "moduleProgress": {
      "circuit-challenge": { ... }
    },
    "avatarPurchases": ["item1", "item2"]
  }
}
```

**Response:**
```json
{
  "success": true,
  "transferred": {
    "coins": 500,
    "levels": 15,
    "items": 2
  }
}
```

---

#### POST /api/v1/family/children

Add a child to the family.

**Request:**
```json
{
  "displayName": "Max",
  "pin": "1234"
}
```

**Response:**
```json
{
  "success": true,
  "child": {
    "id": "uuid",
    "displayName": "Max"
  }
}
```

---

#### PATCH /api/v1/family/children/:id

Update child details.

**Request:**
```json
{
  "displayName": "Maxwell",
  "pin": "5678"
}
```

**Response:**
```json
{
  "success": true
}
```

---

#### DELETE /api/v1/family/children/:id

Soft-delete a child (sets `is_active = false`).

**Response:**
```json
{
  "success": true
}
```

---

### Coins & Purchases

#### POST /api/v1/coins/earn

Record coins earned from gameplay. Server validates and updates balance.

**Request:**
```json
{
  "userId": "uuid",
  "amount": 100,
  "moduleId": "circuit-challenge",
  "puzzleId": "puzzle-abc123"
}
```

**Response:**
```json
{
  "success": true,
  "newBalance": 1334,
  "actualAmount": 100
}
```

**Notes:**
- `actualAmount` may differ if per-puzzle minimum (0) was applied
- Server enforces minimum 0 per puzzle

---

#### POST /api/v1/avatar/purchase/:itemId

Purchase an avatar item.

**Request:**
```json
{
  "userId": "uuid"
}
```

**Response (success):**
```json
{
  "success": true,
  "newBalance": 1234,
  "item": {
    "id": "eyes_sparkle",
    "name": "Sparkle Eyes"
  }
}
```

**Response (failure):**
```json
{
  "success": false,
  "error": "insufficient_coins",
  "required": 200,
  "current": 150
}
```

**Errors:**
- `400` - `insufficient_coins`, `already_owned`, `item_not_found`

---

### Progress & Activity

#### POST /api/v1/progress/:moduleId/levels/:levelId

Record level completion.

**Request:**
```json
{
  "userId": "uuid",
  "completed": true,
  "stars": 3,
  "timeMs": 45000
}
```

**Response:**
```json
{
  "success": true,
  "level": {
    "levelId": "1-A",
    "stars": 3,
    "bestTimeMs": 45000,
    "isNewBest": true
  },
  "unlockedNext": "1-B"
}
```

**Notes:**
- Server merges with existing data (higher stars, lower time wins)
- Returns `unlockedNext` if this completion unlocks next level

---

#### POST /api/v1/activity/session

Log a play session.

**Request:**
```json
{
  "userId": "uuid",
  "moduleId": "circuit-challenge",
  "startedAt": "2025-01-18T14:30:00Z",
  "endedAt": "2025-01-18T14:45:00Z",
  "coinsEarned": 80,
  "starsEarned": 2,
  "gamesPlayed": 3,
  "correctAnswers": 25,
  "mistakes": 4
}
```

**Response:**
```json
{
  "success": true,
  "sessionId": "uuid"
}
```

---

### Sync

#### POST /api/v1/sync

Bulk sync for offline changes. Uses merge strategy (best outcome for player).

**Request:**
```json
{
  "userId": "uuid",
  "lastSyncAt": "2025-01-18T12:00:00Z",
  "changes": {
    "coins": {
      "balance": 1500,
      "updatedAt": "2025-01-18T14:00:00Z"
    },
    "progressionLevels": [
      {
        "levelId": "3-A",
        "stars": 2,
        "bestTimeMs": 52000,
        "completed": true,
        "updatedAt": "2025-01-18T14:30:00Z"
      }
    ],
    "quickPlayStats": {
      "gamesPlayed": 50,
      "totalCorrect": 530,
      "updatedAt": "2025-01-18T14:45:00Z"
    },
    "avatarConfig": {
      "head": "head_square",
      "updatedAt": "2025-01-18T13:00:00Z"
    },
    "avatarPurchases": [
      { "itemId": "head_square", "purchasedAt": "2025-01-18T13:00:00Z" }
    ]
  }
}
```

**Response:**
```json
{
  "success": true,
  "syncedAt": "2025-01-18T15:00:00Z",
  "merged": {
    "coins": {
      "balance": 1500,
      "source": "client"
    },
    "progressionLevels": [
      {
        "levelId": "3-A",
        "stars": 3,
        "bestTimeMs": 48000,
        "source": "server"
      }
    ],
    "quickPlayStats": {
      "gamesPlayed": 52,
      "source": "server"
    },
    "avatarConfig": {
      "head": "head_square",
      "source": "client"
    }
  },
  "conflicts": [
    {
      "field": "progressionLevels.3-A.stars",
      "clientValue": 2,
      "serverValue": 3,
      "resolvedValue": 3,
      "rule": "higher_wins"
    }
  ]
}
```

**Merge Rules Applied:**
| Field | Rule |
|-------|------|
| coins.balance | Higher wins |
| progressionLevels.stars | Higher wins |
| progressionLevels.bestTimeMs | Lower wins |
| progressionLevels.completed | True wins |
| quickPlayStats.* | Higher wins |
| avatarConfig | Last-write-wins |
| avatarPurchases | Union |

---

### Parent Dashboard

#### GET /api/v1/parent/children

Get all children with summary stats.

**Response:**
```json
{
  "children": [
    {
      "id": "uuid",
      "displayName": "Max",
      "coins": 1234,
      "totalStars": 38,
      "lastPlayedAt": "2025-01-18T14:45:00Z",
      "playTimeThisWeek": 135,
      "avatarConfig": { ... }
    }
  ]
}
```

---

#### GET /api/v1/parent/children/:id/stats

Get detailed stats for one child.

**Response:**
```json
{
  "child": {
    "id": "uuid",
    "displayName": "Max"
  },
  "summary": {
    "totalCoins": 1234,
    "totalStars": 38,
    "totalPlayTime": 1250,
    "playTimeThisWeek": 135,
    "currentStreak": 5,
    "lastPlayedAt": "2025-01-18T14:45:00Z"
  },
  "modules": {
    "circuit-challenge": {
      "levelsCompleted": 15,
      "totalLevels": 30,
      "starsEarned": 38,
      "totalStars": 90,
      "gamesPlayed": 47,
      "correctAnswers": 523,
      "mistakes": 87,
      "accuracy": 86
    }
  }
}
```

---

#### GET /api/v1/parent/children/:id/activity

Get activity history.

**Query params:**
- `limit` (default: 20)
- `offset` (default: 0)

**Response:**
```json
{
  "activities": [
    {
      "id": "uuid",
      "moduleId": "circuit-challenge",
      "moduleName": "Circuit Challenge",
      "startedAt": "2025-01-18T14:30:00Z",
      "duration": 15,
      "coinsEarned": 80,
      "starsEarned": 2
    }
  ],
  "total": 47
}
```

---

## Supabase Direct Access

For simpler operations, clients can query Supabase directly with RLS:

### Tables accessible directly:

| Table | Read | Write | Notes |
|-------|------|-------|-------|
| users | Own + children | Own only | Via RLS |
| avatar_items | All | None | Reference data |
| avatar_configs | Own + children | Own only | Via RLS |
| avatar_purchases | Own + children | None | Use purchase endpoint |
| progression_levels | Own + children | None | Use progress endpoint |
| module_progress | Own + children | Own only | Via RLS |
| user_settings | Own only | Own only | Via RLS |
| activity_log | Own + children | None | Use session endpoint |
| coin_transactions | Own + children | None | Read-only audit trail |

### Example: Load avatar items

```javascript
const { data: items } = await supabase
  .from('avatar_items')
  .select('*')
  .order('slot', 'price');
```

### Example: Update avatar config

```javascript
const { error } = await supabase
  .from('avatar_configs')
  .update({ head: 'head_square' })
  .eq('user_id', userId);
```

### Example: Get progression levels

```javascript
const { data: levels } = await supabase
  .from('progression_levels')
  .select('*')
  .eq('user_id', userId)
  .eq('module_id', 'circuit-challenge');
```

---

## Error Responses

All endpoints return consistent error format:

```json
{
  "success": false,
  "error": {
    "code": "ERROR_CODE",
    "message": "Human readable message",
    "details": { }
  }
}
```

### Common Error Codes

| Code | HTTP Status | Description |
|------|-------------|-------------|
| `UNAUTHORIZED` | 401 | Missing or invalid token |
| `FORBIDDEN` | 403 | Not allowed to access resource |
| `NOT_FOUND` | 404 | Resource doesn't exist |
| `INVALID_PIN` | 401 | Wrong child PIN |
| `INSUFFICIENT_COINS` | 400 | Can't afford purchase |
| `ALREADY_OWNED` | 400 | Item already purchased |
| `VALIDATION_ERROR` | 400 | Invalid request data |
| `SYNC_CONFLICT` | 409 | Unresolvable sync conflict |
| `SERVER_ERROR` | 500 | Internal error |

---

## Rate Limiting

| Endpoint | Limit |
|----------|-------|
| Auth endpoints | 10/minute |
| Sync | 30/minute |
| Other | 60/minute |

Rate limit headers:
- `X-RateLimit-Limit`
- `X-RateLimit-Remaining`
- `X-RateLimit-Reset`

---

## Versioning

API version is in the URL path: `/api/v1/...`

Breaking changes will increment the version. Old versions supported for 6 months.

---

*End of Document 10*
