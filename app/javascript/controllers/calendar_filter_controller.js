import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form", "status"]

  reset() {
    this.submitting = false
    this.statusTarget.hidden = true
    this.formTarget.removeAttribute("aria-busy")
  }

  submit() {
    if (this.submitting) return

    this.submitting = true
    this.formTarget.setAttribute("aria-busy", "true")
    this.element.querySelectorAll(".dashboard-calendar-view-toggle label").forEach((label) => {
      const selected = label.querySelector("input").checked
      label.classList.toggle("is-selected", selected)
    })
    this.statusTarget.hidden = false
    this.formTarget.requestSubmit()
  }

  connect() {
    this.reset()
  }
}
