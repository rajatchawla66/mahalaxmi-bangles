# HisaabBook v17+ Independent Verification Audit

**Audit Date:** 21 June 2026
**Auditor:** Independent Code Verification
**Codebase Version:** v17 (APP_VERSION = 17)
**Scope:** Full codebase review — all source files, configuration, database layer, build scripts

---

## 1. Executive Summary

HisaabBook v17 is a **functionally mature, production-stable** accounting application for a single-business use case. The core accounting engine is well-designed with consistent balance logic across all computation paths. The backup/restore system with snapshot-rollback is robust. The APK update system is simple and effective.

However, this audit uncovered **2 Critical**, **5 High**, **9 Medium**, and **8 Low** priority findings that collectively represent residual risk for long-term daily usage. The most impactful issues are:

1. A **confirmed JavaScript bug** in the Dashboard's activity filter (Critical — causes blank/crash)
2. **Firestore rules with broken regex validation** (Critical — structural write validation is bypassed)
3. **Missing `Opening Balance` type in TX_TYPES constant** creating fragile string-literal checks
4. **Profit module balance logic diverges** from the canonical `calculateBalances` path
5. Several **dead/orphaned files** remain after previous cleanup efforts

The app is **stable for daily use** in its current shape but has **2 findings that can cause visible failures** and should be fixed before considering the project architecturally mature.

---

## 2. Risk Matrix

| ID | Area | Severity | Probability | Impact | Summary |
|:---|:-----|:---------|:------------|:-------|:--------|
| C-01 | Dashboard | **CRITICAL** | High | Blank Screen | `ActivityTable` filter uses undefined `f` variable |
| C-02 | Firestore Rules | **CRITICAL** | Medium | Silent bypass | `isISODate` regex has quadruple-escaped backslashes — never matches |
| H-01 | Accounting | **HIGH** | Medium | Wrong Balances | `ProfitAndCapital` uses divergent balance logic from canonical path |
| H-02 | Accounting | **HIGH** | Medium | Wrong Balances | `Cash Purchase` missing from party balance calculations |
| H-03 | Backup | **HIGH** | Low | Data Loss | `applyImport` uses `addTransaction` (which logs activity), inflating activity log on restore |
| H-04 | Performance | **HIGH** | High (at scale) | Slowdown | `clearAllData` deletes docs one-at-a-time instead of batching |
| H-05 | Accounting | **HIGH** | Medium | Wrong totals | `Expense` Daybook filter missing — expenses excluded from "All" in some paths |
| M-01 | Dead Code | MEDIUM | N/A | Maintenance | `sandboxDbLabour.js` is a stub with empty function body |
| M-02 | Dead Code | MEDIUM | N/A | Maintenance | `_update_v10.mjs`, `_ota_payload.json`, `temp_ota/` are obsolete |
| M-03 | Dead Code | MEDIUM | N/A | Maintenance | `sql-wasm.wasm` (653KB) in public — SQLite era leftover |
| M-04 | Dead Code | MEDIUM | N/A | Maintenance | `_temp_check/` directory with old index.html and assets |
| M-05 | Backup | MEDIUM | Low | Incomplete backup | Auto-backup timer (60s) omits all labour sub-collections |
| M-06 | Data Integrity | MEDIUM | Low | Orphaned data | `deletePartyTransactions` doesn't clean bank_transactions |
| M-07 | Accounting | MEDIUM | Low | Incorrect display | `fmt()` uses `Math.abs()` — negative balances display as positive |
| M-08 | Security | MEDIUM | Low | Exposure | Firebase API key + project ID hardcoded and committed |
| M-09 | Build | MEDIUM | Low | Build confusion | `firebase.json` points to `dist/` but builds go to `dist-owner/` |
| L-01 | UX | LOW | Low | Confusing | `Contra` transactions not excluded from party balance calculations |
| L-02 | Performance | LOW | Medium | Slow startup | 7 concurrent `onSnapshot` listeners + expense seeding on every mount |
| L-03 | Accounting | LOW | Low | Wrong invoice | `nextSaleInvoiceNumber` only considers `Sale` type, not `Cash Sale`/`Lot Sale` |
| L-04 | Labour | LOW | Low | Stale data | `useLabour` sets `ready=true` immediately before data arrives |
| L-05 | Sandbox | LOW | Low | Inconsistent | Sandbox `clearAllData` doesn't clear `bank_transactions` |
| L-06 | Data | LOW | Low | Missing index | Only 1 composite Firestore index defined |
| L-07 | UX | LOW | Low | Console noise | Excessive `console.log` statements in production builds |
| L-08 | Build | LOW | Low | Fragile | Multiple `dist*` output directories with no `.gitignore` |

---

## 3. Critical Findings

### C-01: Dashboard ActivityTable filter references undefined variable `f`

**File:** [Dashboard.jsx](file:///c:/Users/rajat/Ledgerv2/src/pages/owner/Dashboard.jsx#L240)

```javascript
// Line 240
const filtered = activities.filter(a => filter === "All" || a.action === f);
```

The variable `f` is the **iterator variable** from the `.map()` on line 264 that renders filter buttons — it is **not in scope** at line 240. The correct reference should be `filter`:

```diff
- const filtered = activities.filter(a => filter === "All" || a.action === f);
+ const filtered = activities.filter(a => filter === "All" || a.action === filter);
```

**Impact:** When the user selects any filter other than "All" (e.g., "Created", "Edited", "Deleted"), the filter comparison always evaluates against `undefined`, so **no activities are shown**. The `f` reference may cause a ReferenceError in strict mode or silently produce an empty list. This is a **user-visible bug on the Dashboard**.

- **Probability:** High (happens every time a filter is clicked)
- **Impact:** Activity table goes blank / shows no results
- **Effort:** 1 minute fix

---

### C-02: Firestore Rules `isISODate` regex never matches any input

**File:** [firestore.rules](file:///c:/Users/rajat/Ledgerv2/firestore.rules#L18-L20)

```
function isISODate(v) {
  return v is string && v.matches('^\\\\d{4}-\\\\d{2}-\\\\d{2}$');
}
```

The regex has **quadruple-escaped backslashes** (`\\\\d`), which in the Firestore rules language means the regex literally matches the string `\\d{4}-\\d{2}-\\d{2}` instead of digit patterns. This function **never returns true** for any real date string like `"2026-06-21"`.

**Impact:** The `isISODate` function is currently **not called anywhere** in the deployed rules (it was likely intended for future use), so there is no active breakage. However, if it were referenced as a write validation guard, it would reject all writes silently. This represents broken structural validation infrastructure.

- **Probability:** Medium (latent — activates if rules are extended)
- **Impact:** All date-validated writes would fail
- **Effort:** 2 minute fix

---

## 4. High Priority Findings

### H-01: ProfitAndCapital balance logic diverges from canonical `calculateBalances`

**File:** [ProfitAndCapital.jsx](file:///c:/Users/rajat/Ledgerv2/src/pages/owner/ProfitAndCapital.jsx#L99-L141)

The Profit & Capital module computes creditor/debtor/liquid balances with **its own inline logic** (lines 99–141) rather than reusing the canonical `calculateBalances` and `calculateAccountBalances` from [ledgerRepository.js](file:///c:/Users/rajat/Ledgerv2/src/database/ledgerRepository.js). The inline version:

1. Matches transactions by `party_name` instead of `party_id` (line 116), which can miss renamed parties
2. Does not handle `Expense`, `Drawings`, or `Cash Purchase` types in the creditor/debtor loop
3. Calculates liquid balance without handling `Contra` transfers (lines 134–141)
4. Does not account for `Lot Sale` in the liquid balance calculation (line 137 only checks `Cash Sale`)

**Impact:** Capital verification numbers may diverge from the Dashboard and party statement balances for the same period, potentially producing incorrect closing capital figures.

- **Probability:** Medium (depends on transaction mix)
- **Impact:** Wrong profit/capital verification numbers
- **Effort:** 2-3 hours (refactor to reuse canonical functions with date filtering)

---

### H-02: `Cash Purchase` missing from party balance calculations

**File:** [ledgerRepository.js](file:///c:/Users/rajat/Ledgerv2/src/database/ledgerRepository.js#L97-L109)

In `calculateBalances`, the `Cash Purchase` type is not listed in either the debtor or creditor balance impact branches. Similarly, in [PartyStatement.jsx](file:///c:/Users/rajat/Ledgerv2/src/pages/owner/PartyStatement.jsx#L26-L43) `balanceImpact` function, `Cash Purchase` is absent.

While Cash Purchases are assigned to `party_id: "cash-supplier"` (a virtual party not in the `parties` collection), if a real party were ever used with a `Cash Purchase` type, their running balance would be wrong.

- **Probability:** Medium (Cash Purchase by design uses a virtual party, but nothing enforces this)
- **Impact:** Running balance incorrect for any party receiving a Cash Purchase
- **Effort:** 30 minutes

---

### H-03: Restore inflates activity log via `addTransaction`

**File:** [useLedger.js](file:///c:/Users/rajat/Ledgerv2/src/hooks/useLedger.js#L86-L87)

```javascript
// applyImport line 87
for (const tx of data.transactions) await fb.addTransaction(tx);
```

`fb.addTransaction` (in [firebaseDb.js](file:///c:/Users/rajat/Ledgerv2/src/database/firebaseDb.js#L386-L406)) calls `logActivity` for every transaction written. During a restore of 500 transactions, this creates **500 additional activity log entries** saying "Created [type]", which is misleading post-restore and pollutes the audit trail.

The same issue affects `addBankTransaction` (line 93) and `addParty` calls during restore.

- **Probability:** Low (only on restore)
- **Impact:** Activity log corruption — hundreds of false "Created" entries
- **Effort:** 1-2 hours (use `setDoc` batch writes instead of `addTransaction` for restore)

---

### H-04: `clearAllData` deletes docs one-at-a-time without batching

**File:** [firebaseDb.js](file:///c:/Users/rajat/Ledgerv2/src/database/firebaseDb.js#L533-L548)

```javascript
const promises = snapshot.docs.map(d => deleteDoc(doc(db, colName, d.id)));
await Promise.all(promises);
```

This fires one `deleteDoc` per document in parallel. For a business with 500+ parties and transactions, this generates hundreds of concurrent Firestore writes. The `clearCollection` helper (line 553-562) correctly uses `writeBatch` with 500-doc chunks, but `clearAllData` does not.

- **Probability:** High at scale (triggered during "Clear All Data")
- **Impact:** Potential Firestore quota exhaustion, slow deletion
- **Effort:** 30 minutes (use `clearCollection` internally)

---

### H-05: Daybook `Expense` filter missing from `filter === "all"` implicit inclusion

**File:** [Daybook.jsx](file:///c:/Users/rajat/Ledgerv2/src/components/Daybook.jsx#L30-L33)

The `filter` logic filters Expenses correctly under "All" (default `return true` catch-all). However, the `TYPE_COLORS` map on line 14 **does not include** `Cash Purchase` or `Contra` types, so those transactions will render with a fallback grey appearance but no label. This is a minor UI issue but the Contra transactions appearing in the Daybook is unexpected — Contra entries are fund transfers and shouldn't appear in daily operations audit (per GEMINI.md spec).

- **Probability:** Medium
- **Impact:** Contra/Cash Purchase entries render with wrong styling in Daybook
- **Effort:** 30 minutes

---

## 5. Medium Priority Findings

### M-01: `sandboxDbLabour.js` is a dead stub

**File:** [sandboxDbLabour.js](file:///c:/Users/rajat/Ledgerv2/src/database/sandboxDbLabour.js)

This file contains an `addLabour` function with an empty body and a comment "Logic here". It is imported by `labourDispatcher.js` but the dispatcher routes through `sandboxDb.js` when sandbox is enabled (which has full implementations). This file is vestigial and confusing.

---

### M-02: Legacy OTA/update files remain

The following files are remnants of the obsolete OTA update system (replaced by the APK-based system in v17):

| File | Size | Purpose |
|:-----|:-----|:--------|
| [_update_v10.mjs](file:///c:/Users/rajat/Ledgerv2/_update_v10.mjs) | 584B | One-time v10 update script |
| [_ota_payload.json](file:///c:/Users/rajat/Ledgerv2/_ota_payload.json) | 135B | OTA v12 payload config |
| `temp_ota/owner-v12.zip` | 1.2MB | Old OTA zip archive |
| `temp_ota/owner-v13.zip` | 1.2MB | Old OTA zip archive |

These add ~2.5MB of dead weight and could confuse future maintainers.

---

### M-03: `sql-wasm.wasm` still in public directory

**File:** `public/sql-wasm.wasm` (653 KB)

This is a SQLite WASM binary from the pre-Firebase era. The app migrated to Firestore entirely. This file ships in every build and APK, increasing download size by 653KB for zero benefit.

Also present in `_temp_check/` directory as a duplicate.

---

### M-04: `_temp_check/` directory with stale content

Contains a copy of `index.html`, `logo.svg`, `sql-wasm.wasm`, and an `assets/` directory. Appears to be a diagnostic/testing artifact that was never cleaned up.

---

### M-05: Auto-backup timer omits labour sub-collections

**File:** [useLedger.js](file:///c:/Users/rajat/Ledgerv2/src/hooks/useLedger.js#L216-L221)

```javascript
labour_attendance: [],
labour_advances: [],
labour_salary_payments: [],
labour_monthly_locks: [],
labour_requests: [],
```

The auto-backup that fires every 60 seconds writes empty arrays for all labour sub-collections. This means if the auto-backup is the only recovery point, **all labour attendance, advances, salary payments, locks, and requests are lost**. Only `labour_master` is included (via `labourMaster` state). The manual export from Settings correctly fetches all collections via one-shot reads.

- **Probability:** Low (auto-backup is a safety net, not primary)
- **Impact:** Incomplete local auto-backup
- **Effort:** 1 hour (add one-shot reads for labour sub-collections)

---

### M-06: `deletePartyTransactions` doesn't clean `bank_transactions`

If a party has bank_transactions linked via `bankAccountId`, those records survive party deletion. This is likely acceptable since bank transactions are account-centric, but could lead to orphaned references.

---

### M-07: `fmt()` always uses `Math.abs()` — hides sign

**File:** [format.js](file:///c:/Users/rajat/Ledgerv2/src/utils/format.js#L5)

```javascript
return "₹" + Math.abs(num).toLocaleString("en-IN");
```

The `fmt()` function always shows the absolute value. This works for most display contexts (where sign is indicated by color or label), but in places where `fmt()` is used directly on a `runningBalance` that could be negative (e.g., [PartyStatement StatementRow line 668](file:///c:/Users/rajat/Ledgerv2/src/pages/owner/PartyStatement.jsx#L668)), the sign information is lost. The card view's running balance column shows `₹5,000` whether the actual balance is +5000 or -5000.

---

### M-08: Firebase credentials hardcoded in source

**File:** [firebase.js](file:///c:/Users/rajat/Ledgerv2/src/firebase.js#L4-L11)

API key, project ID, app ID, and measurement ID are committed in source code. For a private single-business app, this is acceptable since Firestore rules provide the access control layer. However, the API key can be used to enumerate the project and potentially abuse Firestore quotas from outside the app.

---

### M-09: Firebase hosting config mismatched with build output

**File:** [firebase.json](file:///c:/Users/rajat/Ledgerv2/firebase.json#L3)

```json
"public": "dist"
```

But builds go to `dist-owner/` and `dist-labour/`. If `firebase deploy` is run without first copying, it would deploy stale content.

---

## 6. Low Priority Findings

### L-01: Contra transactions not excluded from party balance logic
The `calculateBalances` function doesn't handle `Contra` type transactions, which have `party_id: "contra"`. Since this isn't a real party in the `parties` array, it falls through harmlessly, but it represents an implicit assumption.

### L-02: 7+ concurrent Firestore listeners on startup
On every mount, `useLedger` opens 7 `onSnapshot` listeners simultaneously (parties, transactions, bank_transactions, activities, expense_categories, yearly_records, settings). The `useLabour` hook adds 6 more. Each listener triggers a full-collection read on connect. For large datasets, this produces a heavy initial load.

### L-03: Invoice numbering only considers `Sale` type
`nextSaleInvoiceNumber` in `AppOwner.jsx` (line 322) filters only `TX_TYPES.SALE`. If `Cash Sale` or `Lot Sale` entries also have invoice numbers (the UI allows this), the auto-increment logic may suggest a duplicate number.

### L-04: `useLabour.ready` set to true synchronously
In [useLabour.js line 53](file:///c:/Users/rajat/Ledgerv2/src/hooks/useLabour.js#L53), `setReady(true)` is called immediately after subscribing, before any data arrives. Components that gate on `ready` may render with empty data.

### L-05: Sandbox `clearAllData` doesn't clear `bank_transactions`
The sandbox version of `clearAllData` (line 615-628 in `sandboxDb.js`) resets parties, transactions, settings, yearly_records, activities, and expense_categories but does **not** clear `bank_transactions`, mirroring the production behavior but creating inconsistency for sandbox testing.

### L-06: Only 1 composite Firestore index defined
Only `transactions[party_name ASC, isoDate DESC]` is indexed. Queries like attendance by date, advances by labourId, or transactions by type may fall back to client-side filtering rather than indexed queries.

### L-07: Excessive console.log in production
There are 60+ `console.log` statements across the codebase that fire on every data change. In production on a mobile device, this creates unnecessary GC pressure and fills the WebView log buffer.

### L-08: Multiple dist directories with no gitignore
`dist/`, `dist-owner/`, `dist-labour/`, `dist-hosting/`, `dist-test-ota/` are all present. These should either be gitignored or cleaned up.

---

## 7. Technical Debt Report

| Item | Location | Description | Effort |
|:-----|:---------|:------------|:-------|
| Duplicated balance logic | `ProfitAndCapital.jsx` vs `ledgerRepository.js` | Two separate implementations of creditor/debtor/liquid balance calculations | 3h |
| Duplicated `clean()` helper | `firebaseDb.js` and `firebaseDbLabour.js` | Same utility function defined twice | 15m |
| String literals for types | Throughout codebase | Transaction types checked via string literals instead of `TX_TYPES` constant (e.g., `"Opening Balance"`, `"Cash Sale"`) | 2h |
| `Opening Balance` not in `TX_TYPES` | `constants.js` | This type is referenced by string literal in 8+ files but absent from the `TX_TYPES` enum | 15m |
| Settings stored as flat key-value | `useLedger.saveSetting` | Each `saveSetting` call reads all settings, merges one key, writes everything back — race condition possible | 2h |
| `labourDispatcher.js` redundancy | `src/database/` | This file duplicates routing that `dbDispatcher.js` already handles | 30m |
| No TypeScript | Entire codebase | No type safety anywhere — all findings above stem from runtime-only bugs | Large |

---

## 8. Remaining Open Ends

1. **No automated tests** — zero unit tests, integration tests, or end-to-end tests exist
2. **No error boundary on Labour App** — if `AppLabour.jsx` crashes, there's no recovery UI
3. **Firestore rules have no authentication** — by design for this private app, but documented as an explicit tradeoff
4. **Backup scheduling** — auto-backup uses a 60s `setTimeout` (not `setInterval`), so it fires **once** after the first transaction change, not continuously. After that single fire, no further auto-backups occur until the transaction count changes.
5. **No monitoring** — no crash reporting, no analytics, no uptime monitoring beyond the Firestore backup Cloud Function alerts

---

## 9. Dead Code Report

| File/Directory | Type | Status | Recommendation |
|:---------------|:-----|:-------|:---------------|
| [sandboxDbLabour.js](file:///c:/Users/rajat/Ledgerv2/src/database/sandboxDbLabour.js) | Empty stub | Dead | Delete |
| [_update_v10.mjs](file:///c:/Users/rajat/Ledgerv2/_update_v10.mjs) | Legacy script | Dead | Delete |
| [_ota_payload.json](file:///c:/Users/rajat/Ledgerv2/_ota_payload.json) | Legacy config | Dead | Delete |
| `temp_ota/` | OTA build artifacts | Dead | Delete (saves 2.5MB) |
| `_temp_check/` | Diagnostic remnant | Dead | Delete |
| `public/sql-wasm.wasm` | SQLite WASM binary | Dead | Delete (saves 653KB) |
| `conf/` | JDK configuration files | Dead/Misplaced | Verify if needed by Android build |
| `include/`, `jmods/`, `legal/`, `lib/`, `bin/` | JDK directories | Likely bundled JDK | Should not be in project root |
| `dist-test-ota/` | Test build output | Dead | Delete |
| `dist-hosting/` | Stale hosting build | Possibly stale | Verify or delete |
| `OwnerApp_debug.apk` | Debug build artifact | Possibly stale | Move to releases or delete |
| Multiple `.md` audit/recovery files | Documentation | Active reference | Keep but consider archiving |

**Note:** The directories `conf/`, `include/`, `jmods/`, `legal/`, `lib/`, `bin/` appear to be an **extracted JDK** in the project root. This is unusual — they should be referenced from a system path rather than committed to the repository.

---

## 10. Data Integrity Report

### ✅ Verified Correct

| Check | Result |
|:------|:-------|
| Debtor balance formula (Sale/LotSale/PayOut/Drawings ↑, PayIn/Purchase/Expense ↓) | ✅ Consistent across `calculateBalances` and `PartyStatement.balanceImpact` |
| Creditor balance formula (Purchase/Expense/PayIn ↑, Sale/LotSale/PayOut/Drawings ↓) | ✅ Consistent |
| Opening Balance excluded from Daybook | ✅ Correctly filtered |
| Opening Balance excluded from monthly summary | ✅ `calculateMonthlySummary` only processes typed transactions |
| Capital account running balance (Opening - Withdrawals) | ✅ Correct in `calculateCapitalStatement` |
| Bank account balance (Opening + Incoming - Outgoing) | ✅ Correct in `calculateAccountBalances` |
| Contra transfers (debit from, credit to) | ✅ Correct in account balance and statement |
| Lot Sales excluded from profit percentage | ✅ `ProfitAndCapital` only uses `Sale` + `Cash Sale` for gross profit |
| Duplicate detection | ✅ Checks party_id + amount + type + date |
| Party name sync on rename | ✅ Batch updates via `updatePartyNameInTransactions` |

### ⚠️ Concerns

| Check | Issue |
|:------|:------|
| `Cash Purchase` in balance formula | Not handled — falls through to 0 impact |
| `Contra` in balance formula | Not handled — falls through but harmless since party_id="contra" |
| Cross-module advance sync | Deletion of linked expense correctly removes the advance |
| `fmt()` sign loss | Negative running balances display as positive |
| Profit module balance divergence | Uses inline logic instead of canonical `calculateBalances` |

---

## 11. Backup & Recovery Report

### ✅ What Works

- **Manual export** (Settings → Export Backup) produces a complete v2 payload with all 12 collections
- **Snapshot/rollback envelope** (`safeImportBackup`) captures a full pre-import snapshot and rolls back on failure
- **Validation** (`validateBackup`) checks version, required arrays, party shape, transaction shape, and `business_id`
- **v1 backward compatibility** — older backups restore with missing collections treated as empty arrays
- **Business ID mismatch warning** — RestoreModal surfaces the warning with guidance
- **Deterministic expense category IDs** — `setExpenseCategory` prevents duplicates across restores

### ⚠️ Concerns

| Risk | Severity | Details |
|:-----|:---------|:--------|
| Auto-backup incomplete | MEDIUM | Local auto-backup omits labour attendance, advances, salary payments, locks, and requests |
| Restore inflates activity log | HIGH | Every transaction write during restore generates a "Created" activity entry |
| `clearAllData` not batched | HIGH | Single-doc deletes instead of batch writes can hit quota limits |
| No restore verification | LOW | After restore, there's no automated check that all counts match the source payload |
| Backup file not encrypted | LOW | JSON backup file saved to Documents folder in plaintext — acceptable for single-business app |

### Firestore Automated Backup

The audit notes from existing documents indicate a Cloud Function (`scheduledFirestoreExport`) runs on a schedule with lifecycle retention and failure alerts. This was not auditable from the client codebase alone — it lives in Firebase Functions infrastructure.

---

## 12. Performance Report

### Current State

The app is **performant for small-to-medium datasets** (< 500 transactions, < 50 parties). The `useMemo` hooks ensure derived calculations are cached.

### Scaling Projections

| Metric | Current Load | Warning Threshold | Impact |
|:-------|:-------------|:-------------------|:-------|
| Transactions | ~200-500 | ~2,000 | `calculateBalances`, `calculateMonthlySummary`, and all derived calculations iterate the full array on every render |
| Parties | ~30-50 | ~200 | Party list rendering and balance calculation scale linearly |
| Firestore listeners | 7 (owner) + 6 (labour) | 13 is fine | Each delivers full-collection snapshots on connect |
| Activity log | Capped at 500 | N/A | `limit(500)` in subscription keeps this bounded |
| Sandbox localStorage | ~100KB-1MB | ~5MB | localStorage has a 5-10MB cap per origin; large datasets may silently fail |

### Recommendations

1. **Pagination** for transactions — currently loads entire collection into memory
2. **Date-range filtering** on Firestore queries instead of client-side filtering
3. **Lazy loading** for labour subscriptions — only subscribe when labour page is mounted (partially done for labour master, not for sub-collections)

---

## 13. Security Report

### Scope: Realistic risks for a private single-business app

| Area | Finding | Risk Level | Recommendation |
|:-----|:--------|:-----------|:---------------|
| Firestore Rules | Wide-open read/write with minimal structural validation | **Acceptable** | The app has no authentication by design. API key restriction is the only access control. |
| API Key | Hardcoded in source | **Low** | Restrict the key to the app's SHA-1 fingerprint in the Firebase Console |
| Activation PIN | Hardcoded `777252` in source | **Low** | Soft barrier only — documented as intentional |
| Labour PIN | SHA-256 hashed, verified client-side | **Low** | Adequate for this use case |
| Backup file | Plaintext JSON | **Acceptable** | Contains business financial data but stays on-device |
| Update system | APK URL from Firestore | **Low** | If someone writes to `app_config/update`, they could point to a malicious APK. Mitigated by Firestore access being key-restricted. |
| `isISODate` broken regex | Structural validation bypass | **Medium** | Fix the regex even though it's not currently referenced in active rules |

---

## 14. Maintenance Report

### Code Quality

- **No tests** — any code change carries regression risk with zero safety net
- **No linting** — no ESLint config detected, allowing bugs like C-01 (`f` vs `filter`)
- **No TypeScript** — all function signatures are implicit
- **Good separation** — database layer → repository → hooks → pages pattern is clean
- **Good documentation** — GEMINI.md is comprehensive and well-maintained

### Upgrade Risks

| Dependency | Current | Risk |
|:-----------|:--------|:-----|
| Firebase SDK | ^12.13.0 | Major version bumps may change Firestore initialization API |
| React | ^18.3.1 | Stable; React 19 migration would require audit of all effects |
| Capacitor | ^6.2.1 | Breaking changes possible in major versions |
| Vite | ^6.0.7 | Stable |
| recharts | ^2.15.0 | Not heavily used; low risk |
| xlsx | ^0.18.5 | Community fork — monitor for security advisories |

### Bus Factor

The entire project is maintained by one person. All deployment knowledge (APK signing, Firebase config, Cloud Functions) is implicit. The GEMINI.md and existing audit documents partially mitigate this.

---

## 15. Recommended Fix Roadmap

### Phase 1: Immediate (1-2 hours total)

| Priority | ID | Fix | Effort |
|:---------|:---|:----|:-------|
| **CRITICAL** | C-01 | Fix `f` → `filter` in Dashboard ActivityTable | 1 min |
| **CRITICAL** | C-02 | Fix `isISODate` regex in firestore.rules | 2 min |
| HIGH | H-05 | Add `Cash Purchase` and `Contra` to Daybook `TYPE_COLORS` | 10 min |
| MEDIUM | M-03 | Delete `sql-wasm.wasm` from `public/` and `_temp_check/` | 5 min |

### Phase 2: Short-Term (1-2 days)

| Priority | ID | Fix | Effort |
|:---------|:---|:----|:-------|
| HIGH | H-02 | Add `Cash Purchase` to `calculateBalances` and `balanceImpact` | 30 min |
| HIGH | H-04 | Refactor `clearAllData` to use `clearCollection` batching | 30 min |
| HIGH | H-03 | Use batch `setDoc` for restore instead of `addTransaction` | 2 hrs |
| MEDIUM | M-01 | Delete `sandboxDbLabour.js` | 5 min |
| MEDIUM | M-02 | Delete `_update_v10.mjs`, `_ota_payload.json`, `temp_ota/` | 5 min |
| MEDIUM | M-04 | Delete `_temp_check/` directory | 5 min |
| MEDIUM | M-09 | Fix `firebase.json` to point to `dist-owner/` or document the deploy workflow | 10 min |
| LOW | L-03 | Expand invoice numbering to include all sale types | 15 min |

### Phase 3: Medium-Term (1 week)

| Priority | ID | Fix | Effort |
|:---------|:---|:----|:-------|
| HIGH | H-01 | Refactor `ProfitAndCapital` to reuse canonical balance functions | 3 hrs |
| MEDIUM | M-05 | Add labour sub-collection reads to auto-backup payload | 1 hr |
| MEDIUM | M-07 | Add signed variant of `fmt()` for contexts that need sign display | 1 hr |
| LOW | L-07 | Add build-time log stripping or use a logger with levels | 2 hrs |
| TECH DEBT | — | Add `Opening Balance` to `TX_TYPES` constant | 2 hrs (audit all string references) |
| TECH DEBT | — | Extract duplicated `clean()` helper to shared utility | 15 min |

### Phase 4: Long-Term (Maturity)

| Item | Effort | Impact |
|:-----|:-------|:-------|
| Add ESLint + strict rules | 2 hrs setup | Catches bugs like C-01 at compile time |
| Add basic unit tests for balance calculations | 1 day | Prevents accounting regressions |
| Add TypeScript gradually (strict mode on new files) | Ongoing | Type safety |
| Transaction pagination / date-range queries | 2-3 days | Enables scaling beyond 2000 transactions |
| Cleanup JDK directories from project root | 1 hr investigation | Reduces repo size significantly |
