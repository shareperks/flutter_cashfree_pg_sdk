# application

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Work Description (What was done)

### Email Coupons / Gmail link-account integration

Built the SharePerks app flow against `https://link-account.shareperks.in`:

- **Connect / disconnect Gmail** — OAuth connect via `/auth/google?accountId=…`; list linked accounts; disconnect with `DELETE /api/accounts/{id}` (confirm dialog + token revoke / cleanup on API).
- **Coupon list** — `GET /api/accounts/by-account/{accountId}/coupons` with search, infinite scroll, and All / Unused / Used filters.
- **Mark used / unused** — `PATCH /api/coupons/{id}/used`; status syncs between list and detail.
- **Rich coupon fields** — model + UI for name, description, image, price, max discount, valid from/till, notes, PIN, `redeem_url`, used/used_at.
- **List + detail UI** — white/border cards and solid brand CTAs aligned with SharePerks theme; detail page with offer info, notes card, redeem code/PIN copy, email source, email images gallery.
- **Redeem link** — “Open redeem link” on list card and detail; opens in external browser.
- **Image loading** — timed HTTP fetch for coupon/email images; timeouts / dead hosts show empty-coupon placeholder (no stuck spinner / NetworkImage crash spam).
- **Coupon code display** — single-line code with ellipsis overflow.
- **Home section** — Email Coupons `BorderCard` block (same wash/border pattern as home welcome cards) with linked Gmail accounts, unused count, and CTAs.
- **Theme** — email coupon list, detail, filters, and home section use SharePerks primary/accent/surface tokens (no purple→pink promo gradients).
- **Navigation** — Menu “My Email Coupons”, home section, manage Google accounts screen, coupon detail route.

### Remaining / next

- check is it shareholder coupon
- pick logo and image and generate a batter version of the app listing.
- on search page list email coupons.
- In Admin panel need to add option max percent wallet amount allow used.
- Admin manage in payout amount or max payout amount.
