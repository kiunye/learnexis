import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="search"
export default class extends Controller {
  static targets = ["input", "results"]

  connect() {
    // Debounce search input
    this.timeout = null
  }

  disconnect() {
    if (this.timeout) {
      clearTimeout(this.timeout)
    }
  }

  handleInput(event) {
    const query = event.target.value.trim()

    // Clear previous timeout
    if (this.timeout) {
      clearTimeout(this.timeout)
    }

    // Debounce search (wait 300ms after user stops typing)
    this.timeout = setTimeout(() => {
      if (query.length > 0) {
        this.performSearch(query)
      } else {
        this.clearResults()
      }
    }, 300)
  }

  performSearch(query) {
    // Placeholder for search functionality
    // This will be implemented when search features are added
    console.log("Searching for:", query)
    
    // TODO: Implement actual search via Turbo or fetch
    // Example:
    // fetch(`/search?q=${encodeURIComponent(query)}`)
    //   .then(response => response.text())
    //   .then(html => {
    //     if (this.hasResultsTarget) {
    //       this.resultsTarget.innerHTML = html
    //     }
    //   })
  }

  clearResults() {
    if (this.hasResultsTarget) {
      this.resultsTarget.innerHTML = ""
    }
  }
}
