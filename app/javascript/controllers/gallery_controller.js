import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.photos = Array.from(document.querySelectorAll(".gallery-photo"));
    this.modal = document.getElementById("gallery-modal");
    this.currentIndex = null;

    // Fermer avec Esc
    window.addEventListener("keydown", this.handleKey.bind(this));
  }

  disconnect() {
    window.removeEventListener("keydown", this.handleKey.bind(this));
  }

  open(event) {
    const photo = event.target;
    this.currentIndex = this.photos.indexOf(photo);
    this.showModal();
  }

  showModal() {
    const photo = this.photos[this.currentIndex];
    const photoId = this.photos[this.currentIndex].dataset.photoId;
    const alreadyLiked = photo.dataset.liked === "true";

    this.modal.innerHTML = `
        <div class="fixed inset-0 bg-black/90 flex items-center justify-center z-50" data-action="click->gallery#close">
        <button class="absolute top-8 right-10 text-white/80 hover:text-white text-4xl z-60" data-action="click->gallery#close" aria-label="Fermer">&times;</button>
        <button
          class="absolute left-8 top-1/2 -translate-y-1/2 p-2 bg-black/40 hover:bg-black/60 rounded-full z-60"
          data-action="click->gallery#previous"
          ${this.currentIndex === 0 ? "disabled" : ""}
          aria-label="Photo précédente"
        >
          <!-- Chevron Left SVG -->
          <svg xmlns="http://www.w3.org/2000/svg" class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="white"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" /></svg>
        </button>
        <div class="flex flex-col">
          <img
            src="${photo.src}"
            class="max-w-[90vw] max-h-[90vh] object-contain rounded-2xl shadow-xl transition-all duration-200"
            alt="Photo"
            style="margin: 0 auto; display: block;"
          />
          <div class="flex justify-center items-center gap-2 px-3 py-2 rounded-full shadow z-60">
            <button
              class="like-btn text-pink-500 hover:scale-110 transition ${
                alreadyLiked ? " opacity-60 pointer-events-none" : ""
              }"
              data-photo-id="${photoId}"
              data-action="click->gallery#like"
              aria-label="Like"
              ${alreadyLiked ? "disabled" : ""}
            >
              <svg class="w-7 h-7" fill="currentColor" viewBox="0 0 24 24">
                <path d="M12 21.35l-1.45-1.32C5.4 15.36 2 12.28 2 8.5 2 5.42 4.42 3 7.5 3c1.74 0 3.41 0.81 4.5 2.09C13.09 3.81 14.76 3 16.5 3 19.58 3 22 5.42 22 8.5c0 3.78-3.4 6.86-8.55 11.54L12 21.35z"/>
              </svg>
            </button>
          </div>
        </div>
        <button
          class="absolute right-8 top-1/2 -translate-y-1/2 p-2 bg-black/40 hover:bg-black/60 rounded-full z-60"
          data-action="click->gallery#next"
          ${this.currentIndex === this.photos.length - 1 ? "disabled" : ""}
          aria-label="Photo suivante"
        >
          <!-- Chevron Right SVG -->
          <svg xmlns="http://www.w3.org/2000/svg" class="w-10 h-10" fill="none" viewBox="0 0 24 24" stroke="white"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" /></svg>
        </button>
  </div>
    `;
    this.modal.classList.remove("hidden");
  }

  close(event) {
    // Ferme si on clique le backdrop ou la croix
    if (
      event.target.dataset.action?.includes("gallery#close") ||
      event.target.classList.contains("bg-black/80")
    ) {
      this.modal.classList.add("hidden");
      this.modal.innerHTML = "";
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
    if (!this.modal.classList.contains("hidden")) {
      if (event.key === "Escape") {
        this.modal.classList.add("hidden");
        this.modal.innerHTML = "";
      } else if (event.key === "ArrowLeft") {
        this.previous();
      } else if (event.key === "ArrowRight") {
        this.next();
      }
    }
  }

  async like(event) {
    event.stopPropagation();
    const btn = event.currentTarget;
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
      console.log(data);
      console.log(data.likes_count);
      if (gridCounter) {
        gridCounter.textContent = data.likes_count;
      } else {
        this.addLikeCounter(photoId, data.likes_count);
      }

      // Désactive et grise le bouton immédiatement
      btn.classList.add("opacity-60", "pointer-events-none");
      btn.setAttribute("disabled", "disabled");

      // Ajoute un effet
      btn.classList.add("scale-125");
      setTimeout(() => btn.classList.remove("scale-125"), 150);
    } else if (res.status === 422) {
      // Déjà liké => désactive visuellement aussi
      btn.classList.add("opacity-60", "pointer-events-none");
      btn.setAttribute("disabled", "disabled");
    }
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
  r;
}
