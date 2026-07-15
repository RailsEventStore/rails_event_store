import { Application, Controller } from "./stimulus-3.2.2.js"

const application = Application.start()

application.register(
  "search",
  class extends Controller {
    static targets = ["dialog", "input", "list"]
    static values = { base: String, minChars: { type: Number, default: 3 }, debounce: { type: Number, default: 300 } }

    open(event) {
      event?.preventDefault()
      this.dialogTarget.showModal()
      this.inputTarget.focus()
    }

    close() {
      this.dialogTarget.close()
    }

    go(event) {
      event.preventDefault()
      const name = this.inputTarget.value
      if (name) window.location = `${this.baseValue}/streams/${encodeURIComponent(name)}`
    }

    type() {
      clearTimeout(this.debounceTimer)
      const query = this.inputTarget.value
      if (query.length < this.minCharsValue) {
        this.render([])
        return
      }
      this.debounceTimer = setTimeout(() => this.suggest(query), this.debounceValue)
    }

    async suggest(query) {
      let streams = []
      try {
        const response = await fetch(`${this.baseValue}/search_streams/${encodeURIComponent(query)}`)
        if (response.ok) streams = (await response.json()).streams
      } catch (_) {}
      if (this.inputTarget.value !== query) return // superseded by a newer keystroke
      this.render(streams)
    }

    render(streams) {
      this.listTarget.replaceChildren(
        ...streams.map((name) => {
          const item = document.createElement("li")
          const link = document.createElement("a")
          link.href = `${this.baseValue}/streams/${encodeURIComponent(name)}`
          link.textContent = name
          link.className = "p-3 block rounded hover:bg-red-200 w-full bg-gray-100 break-words text-xs font-bold font-mono"
          item.appendChild(link)
          return item
        }),
      )
    }
  },
)

application.register(
  "timezone",
  class extends Controller {
    static targets = ["time", "zone", "select"]

    get storageKey() {
      return "ruby_event_store_browser.timezone"
    }

    connect() {
      const detected = Intl.DateTimeFormat().resolvedOptions().timeZone
      const stored = localStorage.getItem(this.storageKey)
      const selected = this.supported(stored) ? stored : detected
      const zones = [...new Set(["UTC", detected, selected])]
      this.selectTarget.innerHTML = zones.map((z) => `<option value="${z}">${z}</option>`).join("")
      this.selectTarget.value = selected
      this.render()
    }

    supported(timeZone) {
      if (!timeZone) return false
      try {
        Intl.DateTimeFormat("en-US", { timeZone: timeZone })
        return true
      } catch (_) {
        return false
      }
    }

    change() {
      localStorage.setItem(this.storageKey, this.selectTarget.value)
      this.render()
    }

    render() {
      const tz = this.selectTarget.value
      this.timeTargets.forEach((el) => {
        el.textContent = this.format(el.dataset.iso, tz)
        if (el.hasAttribute("title")) el.setAttribute("title", tz)
      })
      this.zoneTargets.forEach((el) => el.setAttribute("title", tz))
    }

    format(iso, tz) {
      const parts = Object.fromEntries(
        new Intl.DateTimeFormat("en-US", {
          timeZone: tz, year: "numeric", month: "2-digit", day: "2-digit",
          hour: "2-digit", minute: "2-digit", second: "2-digit",
          fractionalSecondDigits: 3, hour12: false,
        }).formatToParts(new Date(iso)).map((p) => [p.type, p.value])
      )
      return `${parts.year}-${parts.month}-${parts.day}T${parts.hour}:${parts.minute}:${parts.second}.${parts.fractionalSecond}`
    }
  },
)

application.register(
  "clipboard",
  class extends Controller {
    static values = { text: String }

    copy() {
      navigator.clipboard.writeText(this.textValue)
    }
  },
)
