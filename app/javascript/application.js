// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Auto-dismiss flash messages after 5 seconds
function dismissFlashMessages() {
  const alerts = document.querySelectorAll('.alert');
  alerts.forEach(alert => {
    setTimeout(() => {
      if (alert && alert.parentNode) {
        alert.classList.remove('show');
        setTimeout(() => {
          if (alert.parentNode) {
            alert.parentNode.removeChild(alert);
          }
        }, 150);
      }
    }, 5000);
  });
}

// Initial page load
document.addEventListener('DOMContentLoaded', dismissFlashMessages);

// For Turbo navigation
document.addEventListener('turbo:frame-load', dismissFlashMessages);

// For Turbo Stream updates (like delete operations)
document.addEventListener('turbo:after-stream-render', function() {
  setTimeout(dismissFlashMessages, 100);
});