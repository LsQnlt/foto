# 🤝 Contributing to Foto

First off, thanks for taking the time to contribute! Every bit of help — from typo fixes to major features — makes Foto better.

---

## 1 — How to Contribute

### 1.1 Fork & Clone

```bash
# Fork via GitHub UI, then:
git clone <https://github.com/YOUR_USERNAME/foto.git>
cd foto
```

### 1.2 Create a Branch

```bash
git checkout -b feature/short-descriptor
```

### 1.3 Make Changes

- Keep commits focused and descriptive.
- Follow the code style (see below).
- Add or update tests when relevant.

### 1.4 Run the Test Suite

```bash
bin/rails test
```

### 1.5 Push & Open a Pull Request

```bash
git push --set-upstream origin feature/short-descriptor
```

## 2 — Code Style Guidelines

| Area        | Convention                                                           |
| ----------- | -------------------------------------------------------------------- |
| **Ruby**    | Follow the default RuboCop rules (`bundle exec rubocop`)             |
| **JS/CSS**  | Use Stimulus/Hotwire patterns; keep CSS minimal (Tailwind preferred) |
| **Commits** | Present-tense imperatives (e.g. `Fix photo upload bug`)              |
| **Tests**   | Minitest (default); add tests for new functionality                  |

## 3 — Issue Reporting

1. **Search** existing issues first.
2. Provide a clear, concise description.
3. Include reproduction steps, stack traces, or screenshots where useful.

## 4 — Security Vulnerabilities

If you discover a security issue, **do not** open a public issue. Instead, please email **security@foto-project.org**. We follow responsible-disclosure guidelines.

## 5 — Community Standards

- Be respectful and inclusive. Foto adopts the [Contributor Covenant v2.1](https://www.contributor-covenant.org/).
- Violations may result in PR/issue removal or further action.

## 6 — Releasing

Project maintainers will:

1. Merge PRs that meet the guidelines.
2. Bump version numbers following [SemVer](https://semver.org/).
3. Tag releases and update the changelog.

Thank you for helping make Foto awesome!
