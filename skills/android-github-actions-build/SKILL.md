---
name: Android APK Build & Stable Signing
description: Build, sign, version, and release Android apps through GitHub Actions while keeping one permanent signing key so every future build installs as an update. Use for any Kotlin/Compose/Gradle Android project in this GitHub account.
---

# Android APK Build & Stable Signing

This is the house style for Android projects in this account. Follow it exactly
unless the user explicitly says otherwise.

## Non-negotiables (read first)

1. **Never generate a new signing key for an existing app.** A new key means
   users must uninstall before updating. Reuse the same keystore forever.
2. **Never commit** `*.jks`, `*.keystore`, `key.properties`, or decoded secrets.
   The keystore lives only in the `RELEASE_KEYSTORE_BASE64` repository secret.
3. **Never change `applicationId`** once the app is published. It is the identity
   that lets Android treat a new build as an update.
4. **`versionCode` must strictly increase** on every build that users install.
5. **Never print secret values** in logs. Echo only a redacted confirmation.

## Canonical project shape

```
<repo>/
├─ app/
│  ├─ build.gradle.kts
│  └─ src/main/...
├─ gradle/libs.versions.toml
├─ gradlew, gradlew.bat, gradle/wrapper/
└─ .github/workflows/
   ├─ android-main-build.yml     # push to main -> unsigned/signed debug-ish APK artifact
   └─ android-release.yml        # tag v* -> signed APK + GitHub Release
```

Gradle setup that this account uses:

| Item | Value |
| --- | --- |
| JDK | Temurin **17** |
| compileSdk / targetSdk | **36** |
| build-tools | **36.0.0** |
| minSdk | 24 (unless the app needs otherwise) |
| Gradle wrapper | regenerated with **9.3.1**, `--distribution-type bin` |
| Version inputs | `-PversionName=... -PversionCode=...` |

Always regenerate the wrapper on CI; the checked-in wrapper JAR has failed
checksum validation before:

```yaml
- uses: gradle/actions/setup-gradle@v4
  with:
    validate-wrappers: false
- run: gradle wrapper --gradle-version 9.3.1 --distribution-type bin
```

## Signing contract

`app/build.gradle.kts` must read signing data from the environment and build an
unsigned APK when it is absent (so forks and PRs still build):

```kotlin
val requestedVersionCode = providers.gradleProperty("versionCode").orNull?.toIntOrNull() ?: 1
val requestedVersionName = providers.gradleProperty("versionName").orNull ?: "1.0.0"

val keyStorePath = System.getenv("KEYSTORE_PATH")
val releaseStorePassword = System.getenv("STORE_PASSWORD")
val releaseKeyAlias = System.getenv("KEY_ALIAS")
val releaseKeyPassword = System.getenv("KEY_PASSWORD")
val hasReleaseKey = listOf(keyStorePath, releaseStorePassword, releaseKeyAlias, releaseKeyPassword)
    .all { !it.isNullOrBlank() }

android {
    defaultConfig {
        // Keep this value forever: changing it breaks in-place updates.
        applicationId = "com.example.app"
        versionCode = requestedVersionCode
        versionName = requestedVersionName
    }

    if (hasReleaseKey) {
        signingConfigs {
            create("release") {
                storeFile = file(keyStorePath!!)
                this.storePassword = releaseStorePassword
                this.keyAlias = releaseKeyAlias
                this.keyPassword = releaseKeyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
            isMinifyEnabled = false
        }
    }
}
```

Workflow environment mapping (names are fixed across this account):

| Secret | Workflow env | Purpose |
| --- | --- | --- |
| `RELEASE_KEYSTORE_BASE64` | `RELEASE_KEYSTORE_BASE64` | base64 of the `.jks` |
| `RELEASE_STORE_PASSWORD` | `STORE_PASSWORD` | keystore password |
| `RELEASE_KEY_ALIAS` | `KEY_ALIAS` | key alias |
| `RELEASE_KEY_PASSWORD` | `KEY_PASSWORD` | key password |
| — | `KEYSTORE_PATH` | `$RUNNER_TEMP/<name>-release.jks` |

Restore step:

```yaml
- name: Restore stable signing key
  if: env.RELEASE_KEYSTORE_BASE64 != ''
  run: printf '%s' "$RELEASE_KEYSTORE_BASE64" | base64 --decode > "$RUNNER_TEMP/app-release.jks"
```

Use `printf`, not `echo`, and strip whitespace — `echo` adds a newline that
corrupts some decoders.

## One-time key creation (only for a brand new app)

```bash
keytool -genkeypair -v \
  -keystore release.jks -alias release \
  -keyalg RSA -keysize 4096 -validity 10000 \
  -storepass "$STORE_PASS" -keypass "$KEY_PASS" \
  -dname "CN=<App>, OU=Mobile, O=<Org>, L=, S=, C=IR"

base64 -w0 release.jks > release.jks.b64      # upload contents as RELEASE_KEYSTORE_BASE64
sha256sum release.jks                          # record this fingerprint
```

Store `release.jks` and both passwords offline (password manager + encrypted
backup). If the key is lost, existing users can never receive updates signed by
the same identity.

## Updating an existing app (the common case)

1. Confirm you are using the **same** keystore: compare fingerprints.

   ```bash
   apksigner verify --print-certs app-release.apk | grep -i sha-256
   keytool -list -v -keystore "$RUNNER_TEMP/app-release.jks" -storepass "$STORE_PASSWORD" | grep -i sha256
   ```

   They must match the previously shipped APK. If they differ, **stop** and tell
   the user — do not ship.

2. Bump `versionCode`, update `versionName`.
3. Build, sign, verify, publish.
4. Attach the APK to a tag-based GitHub Release.

## Build commands

```bash
./gradlew compileReleaseKotlin --no-daemon --stacktrace --console=plain \
  -PversionName="$VERSION_NAME" -PversionCode="$VERSION_CODE"

./gradlew assembleRelease --no-daemon --stacktrace --console=plain \
  -PversionName="$VERSION_NAME" -PversionCode="$VERSION_CODE"

mv app/build/outputs/apk/release/app-release.apk \
   "app/build/outputs/apk/release/<App>-$VERSION_NAME-Universal.apk"
```

On failure, upload the Gradle log as an artifact so the cause is visible in the
Actions UI instead of buried in the console.

## Verification before release

```bash
# signature + signing identity
apksigner verify --verbose --print-certs app-release.apk

# alignment (Play requirement, harmless elsewhere)
zipalign -c -v 4 app-release.apk

# manifest facts that break updates or installs
aapt2 dump badging app-release.apk | grep -E 'package:|sdkVersion|targetSdkVersion'
```

Required checks:

- `apksigner` reports `Verified using v2/v3 scheme: true`.
- Certificate SHA-256 matches the previous release.
- `versionCode` is greater than the last published build.
- `applicationId` is unchanged.

## Failure playbook

| Symptom | Cause | Fix |
| --- | --- | --- |
| `App not installed` / `INSTALL_FAILED_UPDATE_INCOMPATIBLE` | different signing key or applicationId | restore the original keystore; never re-key |
| `INSTALL_FAILED_VERSION_DOWNGRADE` | versionCode not increased | raise `versionCode` |
| Wrapper checksum error | stale checked-in wrapper JAR | `validate-wrappers: false` + `gradle wrapper` |
| `base64: invalid input` | newline/space in secret | `printf '%s'`, re-upload with `-w0` |
| `Keystore was tampered with` | wrong store password | re-check `RELEASE_STORE_PASSWORD` |
| `Cannot recover key` | alias/key password mismatch | verify `RELEASE_KEY_ALIAS` + `RELEASE_KEY_PASSWORD` |
| Release unsigned | secrets missing | the workflow must fail loudly, never publish unsigned |
| Kotlin `e: file:` errors hidden | console truncation | `tee` the log + grep `e: file:` and exit 1 |
| OOM during build | default Gradle heap | `org.gradle.jvmargs=-Xmx4g` in `gradle.properties` |

## When asked to add a new Android app here

Follow this order:

1. Create the Gradle project with `applicationId` chosen once and recorded.
2. Add `app/build.gradle.kts` signing block exactly as above.
3. Add `.github/workflows/android-main-build.yml` (artifact on push).
4. Add `.github/workflows/android-release.yml` (tag `v*` → release asset).
5. If this is a **new** app, generate the keystore once, upload the four
   secrets, and tell the user to back up the keystore + passwords.
6. If this is an **existing** app, reuse the existing secrets; do not touch them.
7. Push, trigger the workflow, and report the artifact/release URL.

Templates: `references/main-build.yml` and `references/release.yml` are ready to
copy, with `<APP>` / `<PACKAGE>` placeholders.

## Output style for reports

When the build finishes, report only:

- version name / code
- signing fingerprint match: yes/no
- artifact name and link
- anything that required a decision
