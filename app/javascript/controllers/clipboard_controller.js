import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { text: String }

  async copy() {
    try {
      await navigator.clipboard.writeText(this.textValue)

      const originalText = this.element.textContent.trim()
      this.element.textContent = "Copied!"

      setTimeout(() => {
        this.element.textContent = originalText
      }, 2000)
    } catch (error) {
      this.element.textContent = "Unable to copy"
    }
  }
}
