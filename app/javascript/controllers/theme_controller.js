import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.syncState()
    this.boundSync = () => this.syncState()
    window.addEventListener("theme-change", this.boundSync)
  }

  disconnect() {
    if (this.boundSync) {
      window.removeEventListener("theme-change", this.boundSync)
    }
  }

  toggle() {
    const current = document.documentElement.getAttribute("data-theme") || "light"
    const next = current === "dark" ? "light" : "dark"
    document.documentElement.setAttribute("data-theme", next)
    try {
      localStorage.setItem("roommate_theme", next)
    } catch (e) {
      console.warn("Could not save theme preference to localStorage", e)
    }
    this.syncState()
    window.dispatchEvent(new CustomEvent("theme-change", { detail: { theme: next } }))
  }

  syncState() {
    const isDark = document.documentElement.getAttribute("data-theme") === "dark"
    document.querySelectorAll(".theme-toggle-btn").forEach((btn) => {
      btn.setAttribute("aria-label", isDark ? "Switch to light mode" : "Switch to dark mode")
      btn.setAttribute("title", isDark ? "Switch to light mode" : "Switch to dark mode")
      btn.setAttribute("aria-pressed", isDark ? "true" : "false")
    })
  }
}
