// Entry point for the build script in your package.json
import "@hotwired/turbo-rails"
import "./controllers"

// Auto-dismiss flash messages after 5 seconds
document.addEventListener('DOMContentLoaded', function() {
  const alerts = document.querySelectorAll('.alert');
  alerts.forEach(alert => {
    setTimeout(() => {
      if (alert) {
        alert.classList.remove('show');
        setTimeout(() => {
          if (alert.parentNode) {
            alert.parentNode.removeChild(alert);
          }
        }, 150);
      }
    }, 5000);
  });
});

// Auto-dismiss flash messages for Turbo Stream updates
document.addEventListener('turbo:frame-load', function() {
  const alerts = document.querySelectorAll('.alert');
  alerts.forEach(alert => {
    setTimeout(() => {
      if (alert) {
        alert.classList.remove('show');
        setTimeout(() => {
          if (alert.parentNode) {
            alert.parentNode.removeChild(alert);
          }
        }, 150);
      }
    }, 5000);
  });
});