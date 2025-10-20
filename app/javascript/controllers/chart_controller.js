import { Controller } from "@hotwired/stimulus"
import { Chart, registerables } from "chart.js"

Chart.register(...registerables)

export default class extends Controller {
  static values = {
    type: String,
    data: Object,
    options: Object
  }

  connect() {
    const canvas = this.element.querySelector('canvas')
    if (!canvas) return

    // Clone options to avoid mutating the original
    const options = JSON.parse(JSON.stringify(this.optionsValue))

    // Add custom tooltip for bar charts with completedDays data
    if (this.typeValue === 'bar' && this.dataValue.datasets[0].completedDays) {
      const completedDays = this.dataValue.datasets[0].completedDays
      options.plugins = options.plugins || {}
      options.plugins.tooltip = options.plugins.tooltip || {}
      options.plugins.tooltip.callbacks = {
        label: function(context) {
          const value = context.parsed.y
          const days = completedDays[context.dataIndex]
          return [
            `達成率: ${value}%`,
            `完了日数: ${days}/30日`
          ]
        }
      }
    } else {
      // For line charts, add simple percentage tooltip
      options.plugins = options.plugins || {}
      options.plugins.tooltip = options.plugins.tooltip || {}
      options.plugins.tooltip.callbacks = {
        label: function(context) {
          return `達成率: ${context.parsed.y}%`
        }
      }
    }

    this.chart = new Chart(canvas, {
      type: this.typeValue,
      data: this.dataValue,
      options: options
    })
  }

  disconnect() {
    if (this.chart) {
      this.chart.destroy()
    }
  }
}
