// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import Alpine from 'alpinejs'

// Initialize Alpine.js
window.Alpine = Alpine

// Start Alpine when DOM is ready
document.addEventListener('DOMContentLoaded', () => {
  Alpine.start()
})

// Ensure Alpine reinitializes after Turbo navigation
document.addEventListener('turbo:load', () => {
  // Alpine automatically handles new DOM elements
})

// Handle Turbo frame updates
document.addEventListener('turbo:frame-load', () => {
  // Alpine will detect new x-data elements automatically
})