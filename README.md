# 📸 What is Foto?

**Foto** is a Rails-based photo book application designed for sharing and displaying large numbers of photos by organizing them into albums. You can easily upload and browse your photos in a clean and familiar interface.f

This platform was built to meet a few specific needs and principles:

- Avoid storing personal images on cloud or Big Tech (GAFAM) services like Instagram
- Display as many photos as I want, without arbitrary limits
- Keep the application lightweight and optimized for user experience
- Recreate the feeling of browsing a family photo album

# 🛠️ Tech Stack

**Foto** is developed using:

- **Rails 8** (with default configuration)
- **SQLite** as the database in development
- **Stimulus** (via Hotwire) to handle JavaScript with minimal overhead
- **ActiveStorage** for managing image uploads and storage (locally)
- **ActiveJob** for background processing, following Rails conventions
- **ActiveAdmin** to manage photos and albums, offering better integration with Rails 8 asset management
- **Kamal 2** for deployment, currently hosted on an **OVH VPS**

# 📚 More

- [How to Install Foto →](INSTALL.md)
- [How to Contribute →](CONTRIBUTING.md)

## 📄 License

Foto is licensed under the [GNU Affero General Public License v3.0](https://www.gnu.org/licenses/agpl-3.0.html).

This means that if you run Foto as a service or modify it, you must make your modified version's source code available to users.
