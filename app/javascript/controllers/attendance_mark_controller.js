import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["statusSelect", "row"]

  markAllPresent() {
    this.setAllStatus("present")
  }

  markAllAbsent() {
    this.setAllStatus("absent")
  }

  markAllLate() {
    this.setAllStatus("late")
  }

  setAllStatus(status) {
    if (this.hasStatusSelectTarget) {
      this.statusSelectTargets.forEach((select) => {
        select.value = status
      })
    }
  }
}
