// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

function initSidebarEvents() {
  const sidebar = document.getElementById("dashboard-sidebar");
  const collapseBtn = document.getElementById("sidebar-collapse-btn");
  const menuToggle = document.getElementById("header-menu-toggle");
  const backdrop = document.getElementById("dashboard-sidebar-backdrop");

  function toggle() {
    if (!sidebar) return;
    const isMin = sidebar.classList.contains("is-minimized");
    if (isMin) {
      sidebar.classList.remove("is-minimized");
      sidebar.classList.add("is-open");
      if (backdrop) backdrop.classList.add("is-open");
    } else {
      sidebar.classList.add("is-minimized");
      sidebar.classList.remove("is-open");
      if (backdrop) backdrop.classList.remove("is-open");
    }
  }

  if (collapseBtn) collapseBtn.onclick = toggle;
  if (menuToggle) menuToggle.onclick = toggle;
  if (backdrop) backdrop.onclick = () => {
    if (sidebar) {
      sidebar.classList.add("is-minimized");
      sidebar.classList.remove("is-open");
    }
    backdrop.classList.remove("is-open");
  };

  // Close household dropdown when clicking outside
  document.addEventListener("click", (e) => {
    const dropdown = document.getElementById("household-dropdown");
    if (dropdown && dropdown.hasAttribute("open") && !dropdown.contains(e.target)) {
      dropdown.removeAttribute("open");
    }
  });
}

document.addEventListener("turbo:load", initSidebarEvents);
document.addEventListener("DOMContentLoaded", initSidebarEvents);

