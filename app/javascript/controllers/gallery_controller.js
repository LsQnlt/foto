import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["modal"];

  connect() {
    this.photos = Array.from(this.element.querySelectorAll(".gallery-photo"));
    this.currentIndex = null;
    this.preloaded = {};
    this.alreadyTracked = new Set();
    this.likedPhotoIds = new Set(
      this.photos // on parcourt les vignettes
        .filter((p) => p.dataset.liked === "true")
        .map((p) => p.dataset.photoId)
    );

    this.boundHandleKey = this.handleKey.bind(this);
    window.addEventListener("keydown", this.boundHandleKey);
    // Précharge les 3 premières grandes images
    [0, 1, 2].forEach((i) => this.preload(i));
  }

  disconnect() {
    window.removeEventListener("keydown", this.boundHandleKey);
  }

  hoverPreload(event) {
    const index = parseInt(event.target.dataset.photoIndex, 10);
    this.preload(index);
  }

  preload(index) {
    if (index < 0 || index >= this.photos.length) return;
    const url = this.photos[index].dataset.fullUrl;
    if (this.preloaded[url]) return;

    const img = new Image();
    img.src = url;
    this.preloaded[url] = img;

    img.onerror = () => console.warn(`❌ Erreur chargement: [${index}] ${url}`);
  }

  open(event) {
    const photo = event.target;
    this.currentIndex = this.photos.indexOf(photo);
    this.showModal();
  }

  showModal() {
    const photo = this.photos[this.currentIndex];
    const { fullUrl, photoId } = photo.dataset;
    let img = this.preloaded[fullUrl];

    if (!img) {
      img = new Image();
      img.src = fullUrl;
      this.preloaded[fullUrl] = img;
    }

    const display = () => this.renderImage(img, photoId);

    this.preload(this.currentIndex + 1);
    this.preload(this.currentIndex - 1);
    this.preload(this.currentIndex + 2);
    this.preload(this.currentIndex - 2);

    this.modalTarget.innerHTML = this.spinnerTemplate();
    this.modalTarget.classList.remove("hidden");

    img.complete
      ? display()
      : img.addEventListener("load", display, { once: true });
  }

  close(event) {
    // Ferme si on clique le backdrop ou la croix
    if (
      event.target.dataset.action?.includes("gallery#close") ||
      event.target.classList.contains("bg-black/90")
    ) {
      this.modalTarget.classList.add("hidden");
      this.modalTarget.innerHTML = "";
    }
  }

  stop(event) {
    event.stopPropagation();
  }

  previous() {
    if (this.currentIndex > 0) {
      this.currentIndex--;
      this.showModal();
    }
  }

  next() {
    if (this.currentIndex < this.photos.length - 1) {
      this.currentIndex++;
      this.showModal();
    }
  }

  handleKey(event) {
    if (!this.modalTarget.classList.contains("hidden")) {
      if (event.key === "Escape") {
        console.log(event, "escape");
        console.log(this.modalTarget);
        this.modalTarget.classList.add("hidden");
        this.modalTarget.innerHTML = "";
      } else if (event.key === "ArrowLeft") {
        this.previous();
      } else if (event.key === "ArrowRight") {
        this.next();
      }
    }
  }

  isLiked(photoId) {
    return this.likedPhotoIds.has(photoId);
  }

  async like(event) {
    event.stopPropagation();
    const btn = event.currentTarget;
    const svg = btn.querySelector("svg");
    const photoId = btn.dataset.photoId;
    const gridCounter = document
      .querySelector(`.gallery-photo[data-photo-id="${photoId}"]`)
      ?.parentElement.querySelector(".like-count");

    const res = await fetch(`/photos/${photoId}/like`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
        Accept: "application/json",
      },
    });
    if (res.ok) {
      const data = await res.json();
      // Grille :
      // Cherche le compteur correspondant à la photo
      if (gridCounter) {
        gridCounter.textContent = data.likes_count;
      } else {
        this.addLikeCounter(photoId, data.likes_count);
      }

      // ➜ état global
      this.likedPhotoIds.add(photoId);

      // Désactive et grise le bouton immédiatement
      btn.classList.add("text-main");
      btn.classList.remove("text-main-lighter", "hover:text-main");
      svg.classList.add("fill-current");
      svg.classList.remove("group-hover:fill-current");
      btn.setAttribute("title", "J'ai déjà aimé");
      btn.setAttribute("aria-label", "J'ai déjà aimé");
      btn.setAttribute("disabled", "disabled");

      // Ajoute un effet
      btn.classList.add("scale-125");
      setTimeout(() => btn.classList.remove("scale-125"), 150);
    } else if (res.status === 422) {
      // Déjà liké => désactive visuellement aussi
      btn.classList.add("opacity-60", "pointer-events-none");
      btn.setAttribute("disabled", "disabled");
    } else {
      console.log("Erreur non prise en compte:", res);
      btn.classList.add("opacity-60", "pointer-events-none");
      btn.setAttribute("disabled", "disabled");
    }
  }

  trackView(photoId) {
    if (this.alreadyTracked.has(photoId)) return;
    this.alreadyTracked.add(photoId);
    fetch(`/photos/${photoId}/track_view`, {
      method: "POST",
      headers: {
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]')
          .content,
      },
    }).catch(console.error);
  }

  arrowClass(disabled) {
    return disabled
      ? "opacity-30 pointer-events-none cursor-not-allowed"
      : "hover:bg-black/60";
  }

  renderImage(img, photoId) {
    const alreadyLiked = this.isLiked(photoId);
    this.modalTarget.innerHTML = `
    <div class="fixed inset-0 bg-black/90 flex items-center justify-center z-50" data-action="click->gallery#close">
      <button class="absolute top-8 right-10 text-white/80 hover:text-white text-4xl z-60" data-action="click->gallery#close" aria-label="Fermer">&times;</button>
      <button class="absolute left-8 top-1/2 -translate-y-1/2 p-2 bg-black/40 rounded-full z-60 ${this.arrowClass(this.currentIndex === 0)}"
              data-action="click->gallery#previous"
              ${this.currentIndex === 0 ? "disabled" : ""}
              aria-label="Photo précédente">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="white"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
      </button>
      <div class="flex flex-col">
        <img
          src="${img.src}"
          class="max-w-[90vw] max-h-[90vh] object-contain rounded-2xl shadow-xl transition-all duration-200"
          alt="Photo"
          style="margin: 0 auto; display: block;"
        />
        <div class="flex justify-center items-center gap-2 px-3 py-2 rounded-full shadow z-60">
          <button
            class="like-btn relative group ${alreadyLiked ? "text-main" : "text-main-lighter hover:text-main transition hover:scale-110"}"
            title="${alreadyLiked ? "Déjà aimé" : "Ajouter un J’aime"}"
            data-photo-id="${photoId}"
            data-action="click->gallery#like"
            aria-label="${alreadyLiked ? "Déjà aimé" : "Ajouter un J’aime"}"
            ${alreadyLiked ? "disabled" : ""}>

            <svg xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 30 30"
                stroke-width="1.5"
                stroke="currentColor"
                class="z-0 w-12 h-12 transition-all duration-200
                  ${alreadyLiked ? "fill-current" : "group-hover:fill-current"}"
                fill="none">
              <path stroke-linecap="round" stroke-linejoin="round"
                    d="M21 8.25c0-2.485-2.099-4.5-4.688-4.5-1.935 0-3.597 1.126-4.312 2.733-.715-1.607-2.377-2.733-4.313-2.733C5.1 3.75 3 5.765 3 8.25c0 7.22 9 12 9 12s9-4.78 9-12Z" />
            </svg>
          </button>
        </div>
      </div>
      <button class="absolute right-8 top-1/2 -translate-y-1/2 p-2 bg-black/40 rounded-full z-60 ${this.arrowClass(this.currentIndex === this.photos.length - 1)}"
              data-action="click->gallery#next"
              ${this.currentIndex === this.photos.length - 1 ? "disabled" : ""}
              aria-label="Photo suivante">
        <svg xmlns="http://www.w3.org/2000/svg" class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="white"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" /></svg>
      </button>
    </div>
  `;
    this.trackView(photoId);
  }

  addLikeCounter(photoId, count) {
    const photoCard = document.querySelector(
      `.gallery-photo[data-photo-id="${photoId}"]`
    )?.parentElement;
    if (photoCard) {
      const likeDiv = document.createElement("div");
      likeDiv.className =
        "absolute bottom-4 right-4 flex items-center gap-1 bg-white/80 px-2 py-1 rounded-full shadow z-10";
      likeDiv.innerHTML = `
        <svg class="w-5 h-5 text-pink-500" fill="currentColor" viewBox="0 0 24 24">
          <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5
            2 5.42 4.42 3 7.5 3c1.74 0 3.41 0.81 4.5 2.09C13.09
            3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4
            6.86-8.55 11.54L12 21.35z"/>
        </svg>
        <span class="like-count text-xs font-bold text-pink-500">${count}</span>
      `;
      photoCard.appendChild(likeDiv);
    }
  }

  spinnerTemplate() {
    return `
      <div class="fixed inset-0 bg-black/90 flex items-center justify-center z-50" data-action="click->gallery#close">
        <div id="spinner" class="flex justify-center items-center">
          <svg class="text-gray-300 animate-spin" viewBox="0 0 64 64" fill="none" xmlns="http://www.w3.org/2000/svg"
            width="24" height="24">
            <path d="M32 3C35.8 3 39.6 3.8 43.1 5.2c3.5 1.4 6.7 3.5 9.4 6.2 2.7 2.7 4.8 5.9 6.2 9.4 1.4 3.5 2.3 7.3 2.3 11s-.8 7.5-2.3 11c-1.4 3.5-3.5 6.7-6.2 9.4-2.7 2.7-5.9 4.8-9.4 6.2-3.5 1.4-7.3 2.3-11 2.3s-7.5-.8-11-2.3c-3.5-1.4-6.7-3.5-9.4-6.2-2.7-2.7-4.8-5.9-6.2-9.4C3.8 39.6 3 35.8 3 32s.8-7.5 2.3-11c1.4-3.5 3.5-6.7 6.2-9.4 2.7-2.7 5.9-4.8 9.4-6.2C24.5 3.8 28.2 3 32 3Z"
              stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M32 3c4.6 0 9.1 1 13.3 3 4.2 2 8 5.2 10.6 9.2"
              stroke="currentColor" stroke-width="5" stroke-linecap="round" stroke-linejoin="round" class="text-main"/>
          </svg>
        </div>
      </div>
    `;
  }
}
