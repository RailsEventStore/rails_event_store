import { Application, Controller } from "./stimulus-3.2.2.js"

const application = Application.start()

application.register(
  "search",
  class extends Controller {
    static targets = ["dialog", "input"]
    static values = { base: String }

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

application.register(
  "swimlane",
  class extends Controller {
    static targets = ["tbody", "time"]
    static values = { moreUrl: String }

    get storageKey() {
      return "ruby_event_store_browser.timezone"
    }

    connect() {
      this.onScroll = () => this.catchUp()
      window.addEventListener("scroll", this.onScroll, { passive: true })
      this.onZoneChange = (event) => {
        if (event.target.matches('[data-timezone-target="select"]')) this.renderTimes(event.target.value)
      }
      document.addEventListener("change", this.onZoneChange)
      this.renderTimes(this.zone())
      this.catchUp()
    }

    disconnect() {
      window.removeEventListener("scroll", this.onScroll)
      document.removeEventListener("change", this.onZoneChange)
    }

    catchUp() {
      if (!this.moreUrlValue) return
      if (document.body.scrollHeight - (window.scrollY + window.innerHeight) > 200) return
      this.loadMore()
    }

    loadMore() {
      const url = this.moreUrlValue
      if (!url) return
      this.moreUrlValue = ""

      fetch(url, { headers: { Accept: "application/json" } })
        .then((response) => response.json())
        .then(({ html, more_url }) => {
          this.tbodyTarget.insertAdjacentHTML("beforeend", html)
          this.moreUrlValue = more_url || ""
          this.renderTimes(this.zone())
          this.catchUp()
        })
    }

    zone() {
      const stored = localStorage.getItem(this.storageKey)
      const detected = Intl.DateTimeFormat().resolvedOptions().timeZone
      try {
        Intl.DateTimeFormat("en-US", { timeZone: stored })
        return stored || detected
      } catch (_) {
        return detected
      }
    }

    renderTimes(tz) {
      this.timeTargets.forEach((el) => {
        el.textContent = this.format(el.dataset.iso, tz)
        el.setAttribute("title", tz)
      })
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
  "swimlane-add",
  class extends Controller {
    static targets = ["dialog", "input"]

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
      if (!name) return
      const url = new URL(window.location.href)
      url.searchParams.append("streams[]", name)
      window.location = url.toString()
    }
  },
)
