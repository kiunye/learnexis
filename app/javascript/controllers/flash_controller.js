import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  static targets = ["message"]
  static values = {
    autoDismiss: { type: Number, default: 5000 }
  }

  connect() {
    // Auto-dismiss flash messages after specified time
    if (this.autoDismissValue > 0) {
      this.timeout = setTimeout(() => {
        this.dismissAll()
      }, this.autoDismissValue)
    }

    // Listen for Turbo events to dismiss on navigation
    this.boundHandleTurboBeforeVisit = this.handleTurboBeforeVisit.bind(this)
    document.addEventListener("turbo:before-visit", this.boundHandleTurboBeforeVisit)
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
    document.removeEventListener("turbo:before-visit", this.boundHandleTurboBeforeVisit)
  }

  dismiss(event) {
    event.preventDefault()
    const message = event.currentTarget.closest("[data-flash-target='message']")
    if (message) {
      this.animateOut(message)
    }
  }

  dismissAll() {
    this.messageTargets.forEach(message => {
      this.animateOut(message)
    })
  }

  animateOut(message) {
    // Add fade-out animation
    message.style.transition = "opacity 0.3s ease-out, transform 0.3s ease-out"
    message.style.opacity = "0"
    message.style.transform = "translateX(100%)"
    
    setTimeout(() => {
      message.remove()
      
      // Remove the entire flash container if no messages remain
      if (this.messageTargets.length === 0) {
        this.element.remove()
      }
    }, 300)
  }

  handleTurboBeforeVisit() {
    // Dismiss all messages when navigating away
    this.dismissAll()
  }
}
