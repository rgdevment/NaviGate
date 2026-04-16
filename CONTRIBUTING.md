# Contributing to LinkUnbound

Thank you for considering contributing to **LinkUnbound**. Whether it's your first open source contribution or you're experienced — everyone is welcome.

---

## Philosophy

**LinkUnbound** is a personal project shared with the community. It was created by a single developer ([@rgdevment](https://github.com/rgdevment)) to solve a daily frustration: choosing which browser opens a link shouldn't require a computer science degree.

This is not a commercial product. There is no premium version, no monetization, no business plan. It's free software, built for and shared with the community.

We believe in:

- **Simplicity** — Features that matter, no bloat.
- **Privacy first** — Your data stays local, always.
- **Performance** — Lightweight and fast. The picker should feel instant.
- **Collaboration** — We build together.

---

## How Can I Contribute?

### Share Feedback

- **Use the app** — The most valuable feedback comes from real users.
- **Report issues** — If something doesn't work, [let us know](https://github.com/rgdevment/LinkUnbound/issues).
- **Suggest improvements** — Have an idea? [Open an issue](https://github.com/rgdevment/LinkUnbound/issues/new).

### Report Bugs

1. Search [existing issues](https://github.com/rgdevment/LinkUnbound/issues) first.
2. If it's new, open an issue with:
   - Clear description of the problem
   - Steps to reproduce
   - LinkUnbound version and Windows version
   - Screenshots if applicable

### Contribute Code

1. **Fork** the repository.
2. **Create a branch** from `main` (`git checkout -b feature/my-improvement`).
3. **Make your changes** following the style guide below.
4. **Run checks:**
   ```sh
   melos run format
   melos run analyze
   melos run test
   ```
5. **Open a Pull Request** to `main`.

### Translate

LinkUnbound supports English and Spanish. Help bring it to more languages — see the [localization section](#adding-a-translation) below.

### Improve Documentation

Found something confusing? Missing information? PRs welcome.

---

## Project Structure

LinkUnbound is a Dart/Flutter monorepo managed with [Melos](https://melos.invertase.dev/):

```
linkunbound_workspace/
  packages/
    core/               # Pure Dart — models, services, platform interfaces
      lib/src/
        models/         # Browser, BrowserConfig, Rule
        services/       # BrowserService, RuleService, LaunchService, etc.
        platform/       # Abstract platform interfaces
      test/             # Unit tests
  apps/
    linkunbound/        # Flutter app — UI, platform implementations, providers
      lib/
        platform/       # Windows-specific implementations
        ui/             # Picker, Settings, shared widgets
        providers.dart  # Riverpod providers
        main.dart       # Entry point
```

**Key conventions:**

- Business logic lives in `packages/core` (pure Dart, no Flutter dependency).
- UI and platform implementations live in `apps/linkunbound`.
- State management uses Riverpod with `NotifierProvider` pattern.
- Tests go in `packages/core/test/`.

---

## Development Setup

### Requirements

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- [Melos](https://melos.invertase.dev/) (`dart pub global activate melos`)
- Windows 10 or 11 (for running the app)

### Getting Started

```sh
git clone https://github.com/rgdevment/LinkUnbound.git
cd LinkUnbound
melos bootstrap
```

### Running

```sh
cd apps/linkunbound
flutter run -d windows
```

### Common Commands

| Command              | What it does                     |
| :------------------- | :------------------------------- |
| `melos run format`   | Format all packages              |
| `melos run analyze`  | Run `dart analyze` everywhere    |
| `melos run test`     | Run tests in all packages        |
| `melos bootstrap`    | Install dependencies + link      |

---

## Style Guide

- **Modern Dart** — Use latest language features.
- **Descriptive names** — Code should read like prose.
- **Minimal comments** — Only when clarifying non-obvious logic. Comments in English.
- **No comment prefixes** — No `TODO`, `NOTE`, `FIX`, etc.
- **KISS** — Keep it simple.

---

## Adding a Translation

LinkUnbound uses Flutter's standard ARB-based localization.

1. Copy `apps/linkunbound/lib/l10n/app_en.arb` as your base.
2. Name your file with the language code: `app_de.arb`, `app_fr.arb`, etc.
3. Translate the values (keep the keys in English).
4. Run `flutter gen-l10n` to regenerate localization classes.
5. Test by changing the language in Settings.
6. Submit a Pull Request.

**Guidelines:**

- Keep translations concise — UI space is limited.
- Use formal or neutral tone.
- Preserve placeholders like `{name}` or `{count}`.
- Don't translate brand names (LinkUnbound, Windows, etc.).

---

## License and Rights

By contributing to LinkUnbound, you agree that your contributions will be licensed under the **GNU General Public License v3.0 (GPLv3)**.

### Contributor License Agreement

To protect the project long-term, by submitting a Pull Request:

> **You grant Mario Hidalgo G. (rgdevment) a perpetual, worldwide, non-exclusive, royalty-free, irrevocable license to use, modify, sublicense, and distribute your contribution.**

**What this means:**

- You keep the copyright of your code — you are always recognized as the author.
- Your contribution stays open source in this repository under GPLv3 forever.
- The community version will never disappear.

**What we will NOT do:**

- Close the current or future community version.
- Remove your contributions from the open source project.
- Stop giving credit to contributors.

If you don't agree, you can still use LinkUnbound, report bugs, suggest features, fork under GPLv3, and contribute in other ways.

---

## Questions?

- **GitHub Discussions** — For general questions and conversations.
- **Issues** — For specific bugs and suggestions.
- **Email** — [github@apirest.cl](mailto:github@apirest.cl) for sensitive matters.

There are no stupid questions. If you have doubts, ask.
