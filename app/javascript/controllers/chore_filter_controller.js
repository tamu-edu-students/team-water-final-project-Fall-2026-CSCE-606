import { Controller } from "@hotwired/stimulus"

// Filters the "All chores" grid by category chip and free-text search.
// Chips are real links (?category=X) so filtering also works without JavaScript.
export default class extends Controller {
  static targets = ["chip", "card", "search", "empty"]

  connect() {
    const active = this.chipTargets.find((chip) => chip.classList.contains("is-active"))
    this.category = active ? active.dataset.category : ""
    this.query = ""
  }

  filter(event) {
    event.preventDefault()
    this.setCategory(event.currentTarget.dataset.category || "")
  }

  search() {
    this.query = this.searchTarget.value.trim().toLowerCase()
    this.apply()
  }

  // From the Pending/Upcoming lists: show the chore's card and draw attention to it.
  reveal(event) {
    const card = document.querySelector(event.currentTarget.getAttribute("href"))
    if (!card) return

    event.preventDefault()
    if (this.hasSearchTarget) this.searchTarget.value = ""
    this.query = ""
    this.setCategory("")
    card.scrollIntoView({ behavior: "smooth", block: "center" })
    card.classList.add("is-highlighted")
    window.setTimeout(() => card.classList.remove("is-highlighted"), 1600)
  }

  setCategory(category) {
    this.category = category
    this.chipTargets.forEach((chip) => {
      const isActive = (chip.dataset.category || "") === category
      chip.classList.toggle("is-active", isActive)
      if (isActive) chip.setAttribute("aria-current", "true")
      else chip.removeAttribute("aria-current")
    })
    this.apply()

    try {
      const url = new URL(window.location.href)
      if (category) url.searchParams.set("category", category)
      else url.searchParams.delete("category")
      window.history.replaceState(window.history.state, "", url)
    } catch (e) {}
  }

  apply() {
    let visible = 0
    this.cardTargets.forEach((card) => {
      const matchesCategory = !this.category || card.dataset.category === this.category
      const matchesQuery = !this.query || card.dataset.search.includes(this.query)
      card.hidden = !(matchesCategory && matchesQuery)
      if (!card.hidden) visible += 1
    })
    if (this.hasEmptyTarget) this.emptyTarget.hidden = visible > 0
  }
}
