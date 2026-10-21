# ⚙️ Installation Guide for Foto

Welcome! Follow these steps to get **Foto** running locally.

## 1 — Prerequisites

| Tool             | Minimum Version | Notes                                        |
| ---------------- | --------------- | -------------------------------------------- |
| **Ruby**         | 3.3             | Use a version manager (rbenv, asdf, rvm)     |
| **Rails**        | 8.x             | Gem will be installed via Bundler            |
| **Node.js**      | 18+             | Needed for JS runtime & bundling             |
| **SQLite3**      | 3.35+           | Default dev database (PostgreSQL optional)   |
| **libvips**      | 8.x             | Image processing (variants, WebP conversion) |

## 2 — Clone the Repository

```bash
git clone <https://github.com/YOUR_USERNAME/foto.git>
cd foto
```

## 3 — Install Dependencies

```bash
# Ruby gems
bundle install
```

## 4 — Database Setup

```bash
# Creates, migrates and seeds the database
rails db:setup
```

### Switching to PostgreSQL (optional)

1. Add the `pg` gem in `Gemfile`.
2. Update `config/database.yml`.
3. Run `rails db:create db:migrate`.

## 5 — Start the Application

For an all-in-one **Hotwire** dev experience:

```bash
bin/dev          # runs foreman: Rails, JS bundler & CSS watcher
```

Then visit [**http://localhost:3000**](http://localhost:3000/).

## 6 — Admin Dashboard (ActiveAdmin)

```bash
# In a Rails console
AdminUser.create!(
  email: 'admin@example.com',
  password: 'password',
  password_confirmation: 'password'
)
```

Access the dashboard at [**http://localhost:3000/admin**](http://localhost:3000/admin).

## 7 — Storing Images

- Images are saved locally under `storage/`.
- Ensure the directory is writable (`chmod -R 755 storage` on Unix-like systems).

## 8 — Running the Test Suite

```bash
bin/rails test
```

## 9 — Deployment (Production)

Foto is deployed with **Coolify** on an OVH VPS: every push to `main` triggers a build of the `Dockerfile` and a redeploy.
The app needs:

- a persistent volume mounted on `/rails/storage` (SQLite databases + uploaded images)
- the `RAILS_MASTER_KEY`, `SMTP_USERNAME` and `SMTP_PASSWORD` environment variables

The migration from Kamal and the full Coolify setup are documented in [`docs/migration-runbook-complet.md`](docs/migration-runbook-complet.md).
