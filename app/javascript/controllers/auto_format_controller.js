import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

  formatCommaSeparated() {
    const input = this.inputTarget
    let value = input.value

    // Remove any non-digit or non-comma characters
    value = value.replace(/[^\d,]/g, '')

    // Ensure proper comma spacing
    const parts = value.split(',').map(part => part.trim()).filter(part => part.length > 0)
    input.value = parts.join(', ')

    // Dispatch event for other components to react
    input.dispatchEvent(new Event('change', { bubbles: true }))
  }
}