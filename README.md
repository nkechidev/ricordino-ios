# Ricordino 📸

**Snap a photo of anything — Ricordino turns it into a searchable note.**

Whiteboards, business cards, receipts, book pages, product labels — just take a photo, and Ricordino automatically extracts the text, categorizes it, and makes it instantly searchable. No manual typing, no cloud dependency required.

This is the native iOS app — see the [Android version](https://github.com/nkechidev/ricordino) for that platform.

---

## ✨ Features

- **Snap & extract** — Take a photo (or pick one from your library) and Ricordino pulls out the text automatically using on-device OCR
- **Auto-categorization** — Notes are automatically tagged (Receipt, Contact, Recipe, Note, etc.) using lightweight rules or an optional AI call
- **Smart entity detection** — Dates, phone numbers, and addresses found in your notes are surfaced for future reminders
- **Full-text search** — Find any note by searching the text extracted from the photo, not just a filename
- **Private by default** — Everything is stored locally on your device; no account, no login, no data leaves your phone unless you choose to export or share

## 🧠 How it works

```
Camera / Photo Library
      ↓
Vision Text Recognition (on-device OCR)
      ↓
Category classifier (rules-based, or optional LLM call)
      ↓
Entity detection (dates, phone numbers, addresses)
      ↓
Review & edit screen
      ↓
SwiftData database (local storage)
```

## 🛠️ Tech stack

| Layer | Technology |
|---|---|
| UI | SwiftUI |
| Camera | `UIImagePickerController` (system camera sheet; falls back to the photo library when no camera is available, e.g. in Simulator) |
| OCR | [Apple Vision — `VNRecognizeTextRequest`](https://developer.apple.com/documentation/vision) (free, on-device) |
| Entity detection | `NSDataDetector` (built-in, free, offline) |
| Categorization (optional) | LLM API call (text-only, low cost) — falls back to keyword rules if no API key is set |
| Local storage | SwiftData |
| Photo storage | App-private storage (Documents directory) — no photo library permission required to store notes, only to pick from your library |

## 📋 Requirements

- Xcode (latest stable)
- iOS 18+
- No API keys required for core OCR functionality — everything works fully offline out of the box
- A free Apple ID is enough to build and run on your own device (no paid Apple Developer Program membership needed for local testing)

## 🚀 Getting started

```bash
git clone https://github.com/nkechidev/ricordino-ios.git
cd ricordino-ios
```

Open `Ricordino.xcodeproj` in Xcode and run it on the Simulator or a physical device. No configuration needed for the core OCR + notes flow.

To run on a physical device, sign in with your Apple ID under Xcode → Settings → Accounts, then select your team in the target's **Signing & Capabilities** tab.

### Optional: enable AI-powered categorization

If you want smarter categorization beyond the built-in keyword rules, add your API key via an Xcode build setting or `.xcconfig` file (not committed to source control):

```
LLM_API_KEY = your_key_here
```

This is entirely optional — the app is fully functional without it.

## 🗺️ Roadmap

- [x] Camera capture + on-device OCR
- [x] Local notes database + search
- [x] Keyword-based auto-categorization
- [x] Note editing
- [ ] LLM-based smart categorization
- [ ] Reminders from detected dates
- [ ] Export notes to PDF/CSV
- [ ] Multi-language OCR support

## 📄 License

MIT — see [LICENSE](LICENSE) for details.

## 🤝 Contributing

Issues and pull requests are welcome! If you have ideas for new categories, better entity detection, or UI improvements, feel free to open an issue.
