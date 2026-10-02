# KittyCircle — Firestore Database Schema Specification

> **KittyCircle — Plan. Play. Celebrate.**

This document details the exact Cloud Firestore data model, document paths, JSON schemas, data types, and indexing recommendations for **KittyCircle**.

---

## 1. Schema Overview

```text
users/{userId}
game_definitions/{gameId}

groups/{groupId}
  ├── members/{memberId}
  ├── host_schedules/{scheduleId}
  ├── events/{eventId}
  │     ├── rsvps/{rsvpId}
  │     ├── attendance/{attendanceId}
  │     ├── food_items/{itemId}
  │     └── timeline/{itemId}
  ├── game_sessions/{sessionId}
  │     ├── participants/{participantId}
  │     └── winners/{winnerId}
  ├── contributions/{contributionId}
  ├── expenses/{expenseId}
  └── memories/{memoryId}
```

---

## 2. Collection Specs

### 2.1 Users Collection (`users/{userId}`)

Stores user profile information.

```json
{
  "id": "user_12345",
  "displayName": "Priya Sharma",
  "phoneNumber": "+919876543210",
  "email": "priya@example.com",
  "photoUrl": "https://firebasestorage.googleapis.com/...",
  "city": "Bengaluru",
  "language": "en",
  "createdAt": "2026-10-01T12:00:00.000Z",
  "updatedAt": "2026-10-01T12:00:00.000Z",
  "isActive": true
}
```

| Field | Type | Description |
|---|---|---|
| `id` | String | Firebase Auth UID |
| `displayName` | String | User's full name |
| `phoneNumber` | String? | Optional phone number |
| `email` | String? | Optional email address |
| `photoUrl` | String? | Profile photo URL |
| `city` | String | User's city |
| `language` | String | Preferred ISO language code (`en`, `hi`, etc.) |
| `createdAt` | ISO String | Registration timestamp |
| `updatedAt` | ISO String | Last profile update timestamp |
| `isActive` | Boolean | Active status flag |

---

### 2.2 Groups Collection (`groups/{groupId}`)

Stores Kitty Group configurations and metadata.

```json
{
  "id": "group_sunshine_99",
  "name": "🌸 Sunshine Ladies Kitty",
  "description": "Monthly weekend fun & high tea kitty group!",
  "imageUrl": "https://firebasestorage.googleapis.com/...",
  "contributionAmount": 2000.0,
  "currency": "INR",
  "meetingFrequency": "monthly",
  "meetingDay": "Third Saturday",
  "createdBy": "user_12345",
  "createdAt": "2026-01-01T10:00:00.000Z",
  "nextMeetingDate": "2026-10-18T16:00:00.000Z",
  "currentHostId": "user_12345",
  "currentHostName": "Priya Sharma",
  "membersCount": 12,
  "isActive": true
}
```

---

### 2.3 Members Subcollection (`groups/{groupId}/members/{memberId}`)

Stores membership roster for each kitty group.

```json
{
  "id": "user_12345",
  "groupId": "group_sunshine_99",
  "name": "Priya Sharma",
  "phoneNumber": "+919876543210",
  "role": "owner",
  "joinedAt": "2026-01-01T10:00:00.000Z",
  "hasHosted": true,
  "lastHostedDate": "2026-06-15T16:00:00.000Z",
  "avatarUrl": "https://..."
}
```

Roles: `owner`, `admin`, `member`.

---

### 2.4 Host Schedule Subcollection (`groups/{groupId}/host_schedules/{scheduleId}`)

Tracks rotation order of hosts across rounds.

```json
{
  "id": "sched_rot_1",
  "groupId": "group_sunshine_99",
  "memberId": "user_12345",
  "memberName": "Priya Sharma",
  "rotationOrder": 1,
  "scheduledDate": "2026-10-18T16:00:00.000Z",
  "isCompleted": false,
  "completedEventId": null
}
```

---

### 2.5 Events Collection (`groups/{groupId}/events/{eventId}`)

Stores scheduled kitty party sessions.

```json
{
  "id": "evt_diwali_2026",
  "groupId": "group_sunshine_99",
  "groupName": "🌸 Sunshine Ladies Kitty",
  "title": "✨ Royal Diwali Dhamaka Kitty",
  "description": "Traditional wear, festive games, and royal dinner!",
  "eventDate": "2026-10-18T16:00:00.000Z",
  "hostUserId": "user_12345",
  "hostName": "Priya Sharma",
  "venue": "Priya's Residence, Indiranagar",
  "theme": "Royal Ethnic Diwali",
  "dressCode": "Silk Saree / Heavy Anarkali",
  "status": "scheduled",
  "createdAt": "2026-09-20T10:00:00.000Z"
}
```

Event Statuses: `draft`, `scheduled`, `inProgress`, `completed`, `cancelled`.

---

### 2.6 RSVP Subcollection (`groups/{groupId}/events/{eventId}/rsvps/{rsvpId}`)

```json
{
  "id": "user_neha_202",
  "eventId": "evt_diwali_2026",
  "userId": "user_neha_202",
  "userName": "Neha Gupta",
  "status": "going",
  "guestCount": 1,
  "updatedAt": "2026-10-05T14:30:00.000Z"
}
```

---

### 2.7 Attendance Subcollection (`groups/{groupId}/events/{eventId}/attendance/{attendanceId}`)

```json
{
  "id": "user_neha_202",
  "eventId": "evt_diwali_2026",
  "userId": "user_neha_202",
  "userName": "Neha Gupta",
  "status": "present",
  "markedAt": "2026-10-18T16:15:00.000Z"
}
```

---

### 2.8 Game Sessions & Subcollections

#### Session (`groups/{groupId}/game_sessions/{sessionId}`)

```json
{
  "id": "session_game_001",
  "eventId": "evt_diwali_2026",
  "groupId": "group_sunshine_99",
  "gameId": "game_bollywood_quiz",
  "gameTitle": "🎬 Bollywood Dhamaka Quiz",
  "status": "completed",
  "currentRound": 3,
  "startedAt": "2026-10-18T17:00:00.000Z",
  "completedAt": "2026-10-18T17:30:00.000Z"
}
```

#### Winners (`groups/{groupId}/game_sessions/{sessionId}/winners/{winnerId}`)

```json
{
  "id": "win_1",
  "sessionId": "session_game_001",
  "participantId": "user_neha_202",
  "playerName": "Neha Gupta",
  "rank": 1,
  "prizeName": "👑 Kitty Queen Trophy & Gift Card",
  "score": 450.0
}
```

---

### 2.9 Contributions Collection (`groups/{groupId}/contributions/{contributionId}`)

```json
{
  "id": "contrib_oct_123",
  "groupId": "group_sunshine_99",
  "eventId": "evt_diwali_2026",
  "memberId": "user_neha_202",
  "memberName": "Neha Gupta",
  "amount": 2000.0,
  "status": "paid",
  "paidAt": "2026-10-15T10:00:00.000Z",
  "paymentMethod": "UPI / GPay",
  "notes": "Paid directly to Priya"
}
```

---

### 2.10 Expenses Collection (`groups/{groupId}/expenses/{expenseId}`)

```json
{
  "id": "exp_catering_99",
  "groupId": "group_sunshine_99",
  "eventId": "evt_diwali_2026",
  "title": "Catering & Snacks",
  "amount": 8500.0,
  "category": "Food & Catering",
  "paidByMemberId": "user_12345",
  "paidByMemberName": "Priya Sharma",
  "receiptUrl": "https://firebasestorage.googleapis.com/...",
  "date": "2026-10-18T18:00:00.000Z"
}
```

---

### 2.11 Memories Gallery (`groups/{groupId}/memories/{memoryId}`)

```json
{
  "id": "mem_photo_888",
  "groupId": "group_sunshine_99",
  "eventId": "evt_diwali_2026",
  "photoUrl": "https://firebasestorage.googleapis.com/...",
  "caption": "Diwali Kitty Group Photo! ✨",
  "uploadedByUserId": "user_12345",
  "uploadedByUserName": "Priya Sharma",
  "createdAt": "2026-10-18T20:00:00.000Z"
}
```

---

## 3. Recommended Firestore Composite Indexes

To ensure fast query performance, define the following composite indexes in `firestore.indexes.json`:

```json
{
  "indexes": [
    {
      "collectionGroup": "events",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "eventDate", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "contributions",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "eventId", "order": "ASCENDING" }
      ]
    },
    {
      "collectionGroup": "expenses",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "date", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "memories",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "groupId", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    }
  ]
}
```
