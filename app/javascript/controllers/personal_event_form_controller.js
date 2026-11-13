import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["visibility", "sharing", "household", "memberGroup"]

  connect() {
    this.updateVisibility()
  }

  updateVisibility() {
    const sharing = this.visibilityTarget.value === "shared"
    this.sharingTarget.hidden = !sharing
    this.householdTarget.required = sharing
    this.updateHousehold()
  }

  updateHousehold() {
    const householdId = this.householdTarget.value
    this.memberGroupTargets.forEach((group) => {
      const selected = this.visibilityTarget.value === "shared" &&
        group.dataset.householdId === householdId
      group.hidden = !selected
      group.querySelectorAll("input").forEach((input) => {
        input.disabled = !selected
      })
    })
  }
}
