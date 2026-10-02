# KittyCircle — Security Rules Documentation

> **KittyCircle — Plan. Play. Celebrate.**

This document details the authorization matrix, validation policies, Firestore security rules, and Storage security rules for **KittyCircle**.

---

## 1. Security Architecture Overview

KittyCircle enforces multi-tenant privacy by scoping all group resources (`events`, `members`, `contributions`, `expenses`, `memories`, `game_sessions`) strictly inside their corresponding `/groups/{groupId}` hierarchy.

### Authorization Principles:
1. **Authenticated Users Only**: All reads/writes require valid Firebase Auth credentials (`request.auth != null`).
2. **Group Scoped Isolation**: A user can only access a group document or subcollection item if their UID exists in `/groups/{groupId}/members/{userId}` or if they created the group (`createdBy == request.auth.uid`).
3. **Role Enforcement**:
   - `owner`: Full administrative rights, group deletion, host rotation resets, member role assignment.
   - `admin`: Event creation, host schedule management, expense tracking.
   - `member`: View dashboard, RSVP, mark own attendance, join game sessions, post photos to photo gallery.
4. **Data Validation**: Image uploads strictly restricted to valid MIME types (`image/*`) and files under 10 MB.

---

## 2. Authorization Matrix

| Resource | Unauthenticated | Authenticated Non-Member | Group Member | Group Admin/Owner |
|---|---|---|---|---|
| User Profile | ❌ | Read | Read / Write (Self) | Read / Write (Self) |
| Group Overview | ❌ | ❌ | Read | Read / Write / Delete |
| Members List | ❌ | ❌ | Read | Read / Add / Edit / Remove |
| Host Schedule | ❌ | ❌ | Read | Read / Edit Schedule |
| Events & RSVP | ❌ | ❌ | Read / RSVP | Read / Create / Edit |
| Game Sessions | ❌ | ❌ | Join / Play | Host / End / Declare Winner |
| Contributions | ❌ | ❌ | Read / Mark Paid (Self) | Read / Manage All |
| Expenses | ❌ | ❌ | Read | Read / Add / Edit |
| Photo Memories | ❌ | ❌ | Read / Upload | Read / Upload / Delete |

---

## 3. Security Rules Deploy Command

To deploy Firestore and Cloud Storage rules to your Firebase project:

```bash
firebase deploy --only firestore:rules,storage
```
