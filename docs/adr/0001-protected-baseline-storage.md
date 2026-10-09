# ADR 0001: protected Android baseline snapshot

**Status:** accepted by owner on 2026-10-09; native guarantees verified on Android API 33.
**Date:** 2026-10-07.
**Scope:** [Sprint 1 technical sketch](../specs/tspm-sprint-1-technical-plan.md),
criteria 8, 9, 11 and 12.

## Context

One person's profile, starting observation, goal and draft must work offline,
remain encrypted at rest, survive process death after acknowledged saves and
never be reset because a read failed. Android is the only implemented platform.
The current app has no persisted product data.

Installed `flutter_secure_storage` 11.2.0 is available, but inspection of its
`lib/options/android_options.dart` found `resetOnError = true`, and its Android
`FlutterSecureStorage.java` ordinary `writeUnsafe` calls `editor.apply()` before
reporting success. Disabling reset is possible; awaiting its write is insufficient
to report disk errors. Android documents `apply()` as asynchronous disk persistence
without failure notification. [Editor reference](https://developer.android.com/reference/android/content/SharedPreferences.Editor#apply()).

## Alternatives

| Option | Assessment |
|---|---|
| Existing plugin, one encrypted JSON value | Least Dart work; save acknowledgment does not establish durable success. Reject for Sprint 1's save/recovery contract. |
| Local plugin patch/fork using checked `commit()` | Adds package maintenance. SharedPreferences XML corruption can still become an empty map, making protected data look absent. |
| Platform AtomicFile | Reject at API 24: a failed backup rename can still be followed by base-file truncation; first writes also use the base directly. |
| Encrypted temporary file plus checked platform rename through one MethodChannel | Choose: explicit bytes, authenticated decryption, old base preserved until replacement, no new package or plugin fork. |
| Encrypted database / DataStore | Adds database/dependency/migration work for a single small snapshot. Revisit for actual logging/history volume. |

The SharedPreferences corruption concern follows inspection of Android's parser:
an unsuccessful XML load can leave a new empty map. It is an inference about the
absence contract, not a claim that every read error is swallowed.
[Platform source](https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/app/SharedPreferencesImpl.java).

## Decision

Use one encrypted binary container at
`context.noBackupFilesDir/tspm-baseline.bin`. Platform AES/GCM provides authenticated
encryption; an AndroidKeyStore key stays outside the file. Use a fresh IV, authenticate
the container header/store identity, validate container lengths/version and never
log plaintext. No biometric enrollment or claim of universal hardware backing.
[Keystore documentation](https://developer.android.com/privacy-and-security/keystore).

A concrete Dart adapter and one Kotlin store own only `read` and expected-value
`replace`; one background executor serializes access. Write a same-directory
`.pending` encrypted file, check stream sync/close, use checked `Os.rename` to
replace the base, sync its directory and verify ciphertext before acknowledgment.
These platform primitives report errors; never truncate the base while writing.
[Android OS operations](https://developer.android.com/reference/android/system/Os).

This avoids the API 24 AtomicFile implementation, which logs a failed backup
rename and then opens the base for writing. Later readback cannot undo that loss.
[API 24 platform source](https://raw.githubusercontent.com/aosp-mirror/platform_frameworks_base/android-7.0.0_r1/core/java/android/util/AtomicFile.java).

Failure before replacement is known not committed. Failure after replacement or
response loss is uncertain: retain the frozen candidate and retry it, reconciling
the persisted state before allowing correction. Never declare success just from
an in-process comparison.

Absence requires a readable parent and no committed base file. Existing data
with missing key, failed authentication or an invalid container remains untouched.
Do not regenerate its key or provide automatic reset. A leftover pending file
is unacknowledged work and is never promoted on read. It is not a backup/restore
capability; the old committed base remains authoritative until replacement.

The no-backup directory is excluded from Android backup/transfer mechanisms;
app uninstall or device loss therefore does not provide recovery in Sprint 1.
Do not advertise backups. This avoids copying ciphertext without its device key.
[Android backup documentation](https://developer.android.com/identity/data/autobackup).

## Costs and verification gate

We own a small Android adapter and native failure tests. The existing secure-storage
package stays installed/exported, but is not the health-snapshot write path; no
dependency cleanup or unrelated persistence is part of this ADR. This is not a
portable store and does not promise survival of sudden device power loss.

Before onboarding UI, prove real encrypted round-trip, acknowledged-save/restart,
old-or-new complete snapshots across interrupted writes, sync/rename verification
failure, missing-key/corrupt-file preservation and expected-value conflicts on a
disposable Android emulator. Cover the app minimum API 24 and the existing Android
13 verification surface when available. A failing guarantee requires revising
this ADR, not claiming completion from a mocked channel test.

Later daily logs/history or measured snapshot-write costs can justify a database;
that replacement needs an explicit migration for real records.
