import { Controller } from "@hotwired/stimulus"
import consumer from "../channels/consumer"

export default class extends Controller {
  static targets = ["noticeList", "noticeCount"]
  
  connect() {
    this.setupNoticeChannel()
    this.loadNotices()
  }
  
  disconnect() {
    this.unsubscribeFromNoticeChannel()
  }
  
  setupNoticeChannel() {
    this.noticeChannel = consumer.subscriptions.create("NoticeChannel", {
      received: (data) => this.handleNoticeUpdate(data)
    })
  }
  
  unsubscribeFromNoticeChannel() {
    if (this.noticeChannel) {
      consumer.subscriptions.remove(this.noticeChannel)
    }
  }
  
  handleNoticeUpdate(data) {
    switch(data.action) {
      case "create":
        this.prependNotice(data.notice)
        break
      case "update":
        this.updateNotice(data.notice)
        break
      case "destroy":
        this.removeNotice(data.notice_id)
        break
    }
    
    // Update notice count
    this.updateNoticeCount()
  }
  
  prependNotice(noticeData) {
    // Convert timestamp strings back to Date objects for display
    const noticeElement = this.createNoticeElement(noticeData)
    this.noticeListTarget.prepend(noticeElement)
    
    // Show a temporary highlight effect
    noticeElement.classList.add("border-b-2", "border-primary")
    setTimeout(() => {
      noticeElement.classList.remove("border-b-2", "border-primary")
    }, 3000)
  }
  
  updateNotice(noticeData) {
    const noticeElement = this.noticeListTarget.querySelector(`[data-notice-id="${noticeData.id}"]`)
    if (noticeElement) {
      noticeElement.outerHTML = this.createNoticeElement(noticeData).outerHTML
    }
  }
  
  removeNotice(noticeId) {
    const noticeElement = this.noticeListTarget.querySelector(`[data-notice-id="${noticeId}"]`)
    if (noticeElement) {
      noticeElement.remove()
    }
  }
  
  createNoticeElement(noticeData) {
    // Format dates for display
    const publishedAt = noticeData.published_at ? new Date(noticeData.published_at).toLocaleString() : ''
    const expiresAt = noticeData.expires_at ? new Date(noticeData.expires_at).toLocaleString() : ''
    
    // Determine badge variants based on priority
    let priorityVariant = 'secondary'
    if (noticeData.priority === 'urgent') priorityVariant = 'error'
    else if (noticeData.priority === 'normal') priorityVariant = 'warning'
    
    return `
      <div data-notice-id="${noticeData.id}" class="card bg-base-100 shadow-xl mb-4">
        <div class="card-body">
          <div class="flex justify-between items-start mb-2">
            <h3 class="card-title text-lg font-semibold">${noticeData.title}</h3>
            <div class="flex items-center space-x-2">
              <span class="badge badge-${priorityVariant}">${noticeData.priority.charAt(0).toUpperCase() + noticeData.priority.slice(1)}</span>
              <span class="badge badge-info">${noticeData.notice_type.charAt(0).toUpperCase() + noticeData.notice_type.slice(1)}</span>
            </div>
          </div>
          
          <p class="text-preline mb-4">${this.escapeHtml(noticeData.content)}</p>
          
          <div class="flex justify-between items-center text-sm text-muted-foreground">
            <div>
              <span>By: ${noticeData.author ? noticeData.author.first_name + ' ' + noticeData.author.last_name : 'Unknown'}</span>
              ${publishedAt ? '<span class="mx-2">•</span><span>' + publishedAt + '</span>' : ''}
            </div>
            
            ${expiresAt ? `
              <span class="badge ${new Date(expiresAt) < new Date() ? 'badge-error' : 'badge-outline'}">
                ${expiresAt}
              </span>
            ` : ''}
          </div>
        </div>
      </div>
    `
  }
  
  escapeHtml(text) {
    const map = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#039;'
    }
    
    return text.replace(/[&<>"']/g, m => map[m])
  }
  
  updateNoticeCount() {
    const count = this.noticeListTarget.children.length
    if (this.noticeCountTarget) {
      this.noticeCountTarget.textContent = count
    }
  }
  
  loadNotices() {
    // Load initial notices via HTTP (will be replaced with streaming data over time)
    // This is just for initial page load
    fetch(`/notices?format=html`)
      .then(response => response.text())
      .then(html => {
        // Extract just the notice cards from the response
        const parser = new DOMParser()
        const doc = parser.parseFromString(html, 'text/html')
        const noticeCards = doc.querySelectorAll('.notice-card')
        
        if (noticeCards.length > 0) {
          this.noticeListTarget.innerHTML = ''
          noticeCards.forEach(card => {
            this.noticeListTarget.appendChild(card)
          })
          this.updateNoticeCount()
        }
      })
      .catch(err => console.error('Failed to load notices:', err))
  }
}