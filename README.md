# Interview Copilot — Android

Live on-device transcription for interviews, on your phone. Same design
language as the Windows overlay: dark glass, grouped bubbles, live preview.

**Everything runs on the phone. No server, no account, no audio leaves the
device.**

---

## What it does

- **Live transcript** — tap Start, put the call on **speakerphone**, and the
  interviewer's words appear as text within a few seconds.
- **My Notes** — a scratchpad for your battle card. Saved on the device only.
- **Line / word counter** — glanceable progress in the footer.

---

## The one hard Android rule (read this)

Android **does not allow** one app to capture another app's audio when that
audio is a phone call. Calls use the `USAGE_VOICE_COMMUNICATION` stream, and
Android blocks it from playback capture by design. Zoom, Teams, Meet, and
WhatsApp calls are all in this category.

So the phone cannot silently tap the Zoom audio. What it *can* do:

**Put the call on speakerphone.** The phone's microphone then hears both
sides of the conversation, and Interview Copilot transcribes it. That is what
this app is built for.

| Setup | Works? |
|---|---|
| Speakerphone on, phone on the desk | yes — mic hears both voices |
| Headphones / earbuds | mic hears only you, not the interviewer |
| Want a clean digital capture of the call | Android forbids it |

**Best setup:** laptop for the call, phone on the desk on speakerphone next to
it running Interview Copilot. Two screens, one glance away.

---

## Install

1. Copy `interview-copilot.apk` to the phone (USB, Drive, Telegram — anything).
2. Open it. Android will ask to allow install from this source — allow it.
3. Launch **Interview Copilot**. Grant the microphone permission when asked.

Requires **Android 7.0 (API 24)** or newer. Built for arm64 phones (basically
every phone from the last several years).

---

## First run

The first time you tap **Start listening**, the app downloads the Whisper
speech model (~142 MB) once. **Do this on Wi-Fi before the interview**, not
during it. After that it is fully offline.

---

## Before the interview — 60-second check

1. Open the app. Tap **Start listening**. Say a sentence out loud.
2. Confirm text appears in a few seconds. Tap **Stop**.
3. If it works: you're ready. Put the phone on the desk, speakerphone on, and
   paste your battle card into **My Notes**.

---

## What it is not

This app is a **transcript**, not an answer machine. It writes down what was
said so you can glance at it. It does not feed you answers to read out.

That is deliberate: a spoken answer with a 2–4 second delay is an obvious
tell, and follow-up questions expose a script immediately. A transcript keeps
you present in the conversation. Your preparation is what wins the room.

---

## Build it yourself

```bash
flutter pub get
python make_icon.py                       # regenerate the launcher icon
flutter build apk --release --target-platform android-arm64
# -> build/app/outputs/flutter-apk/app-release.apk
```

Requires Flutter 3.x, Android SDK, JDK 17.

**Build notes learned the hard way on Windows:**

- `whisper_ggml` compiles whisper.cpp from C source, so a full **NDK** is
  required. Its own `build.gradle` pins `ndkVersion 29.0.13113456` (a beta);
  if that download is unreliable, install a stable NDK and pin it in
  `android/app/build.gradle.kts` **and** override it for all subprojects in
  `android/build.gradle.kts`.
- Build only the ABI you need (`--target-platform android-arm64`) — the
  plugin otherwise builds whisper.cpp four times.
- If Gradle reports `Failed connecting to the daemon in 4 retries`, the Kotlin
  compiler daemon could not start; `android/gradle.properties` already sets
  `kotlin.compiler.execution.strategy=in-process` to avoid it.
- The APK here is **debug-signed**, which is fine for installing on your own
  device. A Play Store release needs your own keystore.

---

## Privacy

- Audio is processed on-device by whisper.cpp. It is never uploaded.
- Notes are stored in local app storage only.
- The app has no analytics, no accounts, no network calls except the
  one-time model download from Hugging Face.
