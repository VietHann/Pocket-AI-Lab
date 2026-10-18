# 🌷 Pocket AI Lab

**A cute, offline-first AI model collection for iPhone 11 and newer.** Built by VietHannn.

Native SwiftUI • iOS 17+ • pastel lavender/rose • animated mascot • no account • no cloud inference.

## Functional tools

| Tool | Runtime | Offline |
|---|---|---|
| Text Scanner | Apple Vision OCR | Yes |
| Image Labels | Apple Vision classification | Yes |
| Language ID | Apple NaturalLanguage | Yes |
| Voice Studio | AVSpeechSynthesizer | Yes |
| Dictation | Apple Speech, conditional local recognition | Yes, or disabled |
| Tiny Chat | llama.cpp / SwiftLlama, optional SmolLM2-135M GGUF | Yes after download |

SmolLM2 Q4_K_M is approximately 110 MB on disk (RAM use is higher). Text quality, especially Vietnamese, is limited.
Offline Vietnamese dictation is only available when Apple explicitly reports on-device support. No online fallback.

## Build on macOS

1. Install Xcode 16+ and XcodeGen: brew install xcodegen
2. Generate icon: swift scripts/generate_icon.swift
3. Generate project: xcodegen generate
4. Open PocketAILab.xcodeproj; choose your Apple Development Team and connected iPhone (iOS 17+).

## GitHub Actions IPA

The [Build iPhone IPA](.github/workflows/ios-ipa.yml) workflow builds an iOS **device** app on macOS and uploads Pocket-AI-Lab-iPhone11plus-unsigned-IPA in the run's Artifacts.
**The CI IPA is unsigned and is not directly installable.** Re-sign it with a valid iOS certificate/profile or build and sign using Xcode. GitHub Actions -> Build iPhone IPA -> latest successful run -> Artifacts.

## Source organization

- PocketAILab/PocketAILabApp.swift — app shell, mascot, Home, navigation
- PocketAILab/LibraryAndSettings.swift — model library/downloads and settings
- PocketAILab/Studios.swift — six working AI tools
- PocketAILab/Models.swift — model metadata and downloader
- PocketAILab/LocalAI.swift — Vision / NaturalLanguage / Speech / AVFoundation / llama.cpp
- scripts/generate_icon.swift — procedural pastel app icon
- project.yml — XcodeGen spec

## Privacy, safeguards & limits

All inference occurs on the iPhone. The app accesses Internet only on explicit GGUF download. Files are stored in Application Support and excluded from iCloud backup.
Download validation currently checks HTTP 200, approximate file size and GGUF magic; SHA-256 pinning remains TODO.
No prepackaged model weights. Device compatibility and peak RAM have **not yet been tested** on a physical iPhone 11; verify on device before distribution.
Building an app is not the same as obtaining an installable signed IPA.

Sources: Apple Vision, NaturalLanguage, Speech, AVFoundation; https://github.com/ggml-org/llama.cpp ; https://github.com/pgorzelany/swift-llama-cpp ; https://huggingface.co/bartowski/SmolLM2-135M-Instruct-GGUF
