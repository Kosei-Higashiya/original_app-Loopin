// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Flash message functionality
function initializeFlashMessages() {
  const alerts = document.querySelectorAll('.alert:not([data-initialized])');
  
  alerts.forEach(alert => {
    alert.setAttribute('data-initialized', 'true');
    
    // Add close button functionality
    const closeButton = alert.querySelector('.btn-close');
    if (closeButton) {
      closeButton.addEventListener('click', function() {
        closeAlert(alert);
      });
    }
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      if (alert && alert.parentNode) {
        closeAlert(alert);
      }
    }, 5000);
  });
}

function closeAlert(alert) {
  if (!alert || !alert.parentNode) return;
  
  // Add fade-out effect
  alert.classList.remove('show');
  alert.style.transition = 'opacity 0.15s linear';
  alert.style.opacity = '0';
  
  // Remove from DOM after animation
  setTimeout(() => {
    if (alert.parentNode) {
      alert.parentNode.removeChild(alert);
    }
  }, 150);
}

// Initialize on page load
document.addEventListener('DOMContentLoaded', initializeFlashMessages);

// Initialize after Turbo navigation
document.addEventListener('turbo:load', initializeFlashMessages);

// Initialize after Turbo Stream updates (like delete operations)
document.addEventListener('turbo:after-stream-render', function() {
  setTimeout(initializeFlashMessages, 100);
});