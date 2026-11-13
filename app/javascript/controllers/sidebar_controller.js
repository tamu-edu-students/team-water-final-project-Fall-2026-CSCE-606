import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar", "backdrop"]

  connect() {
    this.restoreState()
  }

  toggle() {
    const sidebar = document.getElementById("dashboard-sidebar")
    const backdrop = document.getElementById("dashboard-sidebar-backdrop")
    if (!sidebar) return

    if (sidebar.classList.contains("is-minimized")) {
      sidebar.classList.remove("is-minimized")
      sidebar.classList.add("is-open")
      if (backdrop) backdrop.classList.add("is-open")
      this.saveState(false)
    } else {
      sidebar.classList.add("is-minimized")
      sidebar.classList.remove("is-open")
      if (backdrop) backdrop.classList.remove("is-open")
      this.saveState(true)
    }
  }

  close() {
    const sidebar = document.getElementById("dashboard-sidebar")
    const backdrop = document.getElementById("dashboard-sidebar-backdrop")
    if (sidebar) {
      sidebar.classList.add("is-minimized")
      sidebar.classList.remove("is-open")
    }
    if (backdrop) {
      backdrop.classList.remove("is-open")
    }
    this.saveState(true)
  }

  saveState(minimized) {
    try {
      localStorage.setItem("roommate_os_sidebar_minimized", minimized ? "true" : "false")
    } catch (e) {}
  }

  restoreState() {
    try {
      const saved = localStorage.getItem("roommate_os_sidebar_minimized")
      const sidebar = document.getElementById("dashboard-sidebar")
      if (sidebar && saved === "false" && window.innerWidth > 900) {
        sidebar.classList.remove("is-minimized")
      }
    } catch (e) {}
  }
}
