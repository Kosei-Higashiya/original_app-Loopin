import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="navbar"
export default class extends Controller {
  static targets = ["menu", "toggler"]

  connect() {
    // Controller is connected
  }

  toggle() {
    this.menuTarget.classList.toggle("active")
    this.togglerTarget.classList.toggle("active")
  }
}
