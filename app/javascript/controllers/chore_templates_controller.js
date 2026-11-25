import { Controller } from "@hotwired/stimulus"

// Prefills the "Add a chore" form from a predefined chore. Each template is a
// link (?template=key) so it also works without JavaScript.
export default class extends Controller {
  static targets = ["template", "saveOption"]

  apply(event) {
    event.preventDefault()
    const { title, description, category, frequency } = event.currentTarget.dataset
    this.setField("chore_title", title)
    this.setField("chore_description", description)
    this.setField("chore_category", category)
    this.setField("chore_frequency", frequency)
    this.markSelected(event.currentTarget)
    this.toggleSaveOption(false)
    this.focusForm("chore_due_at")
  }

  custom(event) {
    event.preventDefault()
    this.setField("chore_title", "")
    this.setField("chore_description", "")
    this.setField("chore_frequency", "NONE")
    this.markSelected(event.currentTarget)
    this.toggleSaveOption(true)
    this.focusForm("chore_title")
  }

  // Typing a name that isn't already a common chore makes it a custom chore.
  titleChanged(event) {
    const title = event.currentTarget.value.trim().toLowerCase()
    const known = this.templateTargets.some((item) => (item.dataset.title || "").toLowerCase() === title)
    this.toggleSaveOption(title.length > 0 && !known)
  }

  // "Save as a common chore" only makes sense for chores the user writes themselves.
  toggleSaveOption(show) {
    if (!this.hasSaveOptionTarget) return
    this.saveOptionTarget.hidden = !show
    const checkbox = this.saveOptionTarget.querySelector("input[type=checkbox]")
    if (checkbox && !show) checkbox.checked = false
  }

  setField(id, value) {
    const field = document.getElementById(id)
    if (field && value !== undefined) field.value = value
  }

  markSelected(selected) {
    this.templateTargets.forEach((item) => {
      const isSelected = item === selected
      item.classList.toggle("is-selected", isSelected)
      item.setAttribute("aria-current", isSelected ? "true" : "false")
    })
  }

  focusForm(id) {
    const field = document.getElementById(id)
    if (!field) return
    field.scrollIntoView({ behavior: "smooth", block: "center" })
    window.setTimeout(() => field.focus({ preventScroll: true }), 250)
  }
}
