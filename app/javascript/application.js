// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Flash message functionality
function initializeFlashMessages() {
  const alerts = document.querySelectorAll('.alert:not([data-initialized])');
  
  alerts.forEach(alert => {
    alert.setAttribute('data-initialized', 'true');
    
    // Add close button functionality with event delegation to prevent conflicts
    const closeButton = alert.querySelector('.btn-close');
    if (closeButton && !closeButton.hasAttribute('data-listener-added')) {
      closeButton.setAttribute('data-listener-added', 'true');
      closeButton.addEventListener('click', function(e) {
        e.preventDefault();
        e.stopPropagation();
        closeAlert(alert);
      });
    }
    
    // Auto-dismiss after 5 seconds
    setTimeout(() => {
      if (alert && alert.parentNode && alert.getAttribute('data-initialized') === 'true') {
        closeAlert(alert);
      }
    }, 5000);
  });
}

function closeAlert(alert) {
  if (!alert || !alert.parentNode) return;
  
  // Mark as closing to prevent duplicate operations
  if (alert.getAttribute('data-closing') === 'true') return;
  alert.setAttribute('data-closing', 'true');
  
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

// Global function for manual flash message creation (used by destroy.js.erb)
window.createFlashMessage = function(message, type = 'success') {
  const flashContainer = document.getElementById('flash-messages');
  if (!flashContainer) return;
  
  const alertDiv = document.createElement('div');
  alertDiv.className = `alert alert-${type} alert-dismissible fade show`;
  alertDiv.setAttribute('role', 'alert');
  alertDiv.innerHTML = `
    ${message}
    <button type="button" class="btn-close" aria-label="Close">×</button>
  `;
  
  flashContainer.appendChild(alertDiv);
  
  // Use the standard initialization function to ensure consistency
  initializeFlashMessages();
};

// Initialize on page load
document.addEventListener('DOMContentLoaded', initializeFlashMessages);

// Initialize after Turbo navigation
document.addEventListener('turbo:load', initializeFlashMessages);

// Initialize after Turbo Stream updates (like delete operations)
document.addEventListener('turbo:after-stream-render', function() {
  setTimeout(initializeFlashMessages, 100);
});