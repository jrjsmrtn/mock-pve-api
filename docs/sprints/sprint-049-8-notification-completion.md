# Sprint 4.9.8 — Notification System Completion

**Date:** 2026-03-03
**Version:** 0.4.13 → 0.4.14

## Summary

Completed the notification system implementation (PVE 8.1+). The coverage catalog
previously had zero notification entries — all 15 existing routes were missing from
every `Coverage.*` module. This sprint adds the missing SMTP and webhook endpoint
types, ancillary notification endpoints, and a new `Coverage.Notifications` module
covering all 17 notification paths.

## Changes

### New Functionality

| Path | Methods | Since |
|------|---------|-------|
| `GET /cluster/notifications` | GET | 8.1 |
| `/cluster/notifications/endpoints/smtp` | GET, POST | 8.1 |
| `/cluster/notifications/endpoints/smtp/{name}` | GET, PUT, DELETE | 8.1 |
| `/cluster/notifications/endpoints/webhook` | GET, POST | 8.2 |
| `/cluster/notifications/endpoints/webhook/{name}` | GET, PUT, DELETE | 8.2 |
| `/cluster/notifications/targets` | GET | 8.1 |
| `/cluster/notifications/targets/{name}/test` | POST | 8.1 |
| `/cluster/notifications/matcher-fields` | GET | 8.2 |
| `/cluster/notifications/matcher-field-values` | GET | 8.2 |

### Coverage Catalog

All 17 notification paths are now documented in `MockPveApi.Coverage.Notifications`,
including gotify/sendmail/smtp/webhook endpoint CRUD, matchers CRUD, targets, and
ancillary discovery endpoints.

### Fixed

- `GET /cluster/notifications/endpoints` was returning `[]` inline; now delegates to
  `Notifications.list_endpoint_types/1` and returns the four endpoint type names.

## Files Modified

| File | Change |
|------|--------|
| `lib/mock_pve_api/state.ex` | Added `notification_smtp: %{}`, `notification_webhook: %{}` initial state; added `:smtp`/`:webhook` clauses to `notification_key/1` |
| `lib/mock_pve_api/handlers/notifications.ex` | Added 17 new functions: SMTP (5), webhook (5), ancillary (7) |
| `lib/mock_pve_api/router.ex` | Added 15+ new routes; fixed endpoints inline stub |
| `lib/mock_pve_api/coverage.ex` | Added `:notifications` to `@type endpoint_category`; added `Coverage.Notifications` to `@category_modules` |
| `mix.exs` | Bumped version 0.4.13 → 0.4.14 |

## Files Created

| File | Purpose |
|------|---------|
| `lib/mock_pve_api/coverage/notifications.ex` | New Category module for all 17 notification paths |
| `test/mock_pve_api/handlers/notifications_completion_test.exs` | 25 new tests |

## Test Coverage

25 new tests added:
- SMTP list/CRUD/404/duplicate/version gating (5 tests)
- Webhook list/CRUD/404/duplicate/version gating (5 tests)
- Targets aggregate/test POST (3 tests)
- Matcher fields list/field values (2 tests)
- Notifications index (1 test)
- Endpoint types list (1 test)

## Version Gating

- SMTP: available 8.1+; returns 501 on 7.x
- Webhook: available 8.2+; returns 501 on 8.1 and earlier
- matcher-fields, matcher-field-values: available 8.2+
