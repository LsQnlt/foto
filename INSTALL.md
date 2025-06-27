# ⚙️ Installation Guide for Foto

Welcome! Follow these steps to get **Foto** running locally.

## 1 — Prerequisites

| Tool             | Minimum Version | Notes                                        |
| ---------------- | --------------- | -------------------------------------------- |
| **Ruby**         | 3.3             | Use a version manager (rbenv, asdf, rvm)     |
| **Rails**        | 8.x             | Gem will be installed via Bundler            |
| **Node.js**      | 18+             | Needed for JS runtime & bundling             |
| **SQLite3**      | 3.35+           | Default dev database (PostgreSQL optional)   |
| **Yarn**/**Bun** | latest          | JS package manager (pick one)                |
| **ImageMagick**  | 7+              | Required by ActiveStorage for image variants |

## 2 — Clone the Repository

```bash
git clone <https://github.com/YOUR_USERNAME/foto.git>
cd foto
```

## 3 — Install Dependencies

```bash
# Ruby gems
bundle install

# JavaScript packages
yarn install   # or: bun install
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

Foto is designed to deploy with **Kamal 2**. A minimal `deploy.yml` sample is included in `config/deploy/`. You’ll need:

- A Linux host (e.g. OVH VPS)
- Docker & Kamal installed on the server
- A valid SSH key

_Read the comments in that file and adjust according to your environment._
