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
    static targets = ["drawer", "drawerList"]
    static values = { streams: Array, baseUrl: String }
    connect() {
      this.onStorage = this.onStorage.bind(this)
      window.addEventListener("storage", this.onStorage)
      this.load()
      this.list()
    }

    disconnect() {
      window.removeEventListener("storage", this.onStorage)
    }

    load() {
      const raw = localStorage.getItem("ruby_event_store_browser.swimlane_streams")
      this.streamsValue = raw ? JSON.parse(raw) : []
    }

    onStorage(event) {
      if (event.key !== "ruby_event_store_browser.swimlane_streams") return
      this.streamsValue = event.newValue ? JSON.parse(event.newValue) : []
      this.list()
    }

    async add(event) {
      event.preventDefault()
      const streamName = event.target.dataset.streamName
      if (!streamName) return
      if (!this.streamsValue.includes(streamName)) {
        this.streamsValue = [...this.streamsValue, streamName]
        await localStorage.setItem("ruby_event_store_browser.swimlane_streams", JSON.stringify(this.streamsValue))
        this.list()
        this.drawerTarget.setAttribute("data-swimlane-drawer-open", "")
      }      
    }

    async remove(event) {
      event.preventDefault()
      const streamName = event.target.dataset.streamName
      if (!streamName) return
      this.streamsValue = this.streamsValue.filter((s) => s !== streamName)
      await localStorage.setItem("ruby_event_store_browser.swimlane_streams", JSON.stringify(this.streamsValue))
      this.list()
    }

    go() {
      if (this.streamsValue.length === 0) return
      const url = new URL(this.baseUrlValue + "/swimlane") 
      this.streamsValue.forEach((stream) => url.searchParams.append("streams[]", stream))
      window.location = url.toString()
    }

    list() {
      const items = this.streamsValue.map((stream) => {
        const item = document.createElement("li")
        item.className = "flex items-center justify-between gap-2 py-1.5"

        const link = document.createElement("a")
        link.href = `/streams/${encodeURIComponent(stream)}`
        link.title = stream
        link.className = "text-sm text-red-700 no-underline break-all hover:underline"
        link.textContent = stream

        const remove = document.createElement("button")
        remove.dataset.streamName = stream
        remove.dataset.action = "swimlane#remove"
        remove.setAttribute("aria-label", `Remove ${stream}`)
        remove.className = "flex items-center justify-center text-lg leading-none text-gray-400 rounded shrink-0 size-6 hover:bg-red-100 hover:text-red-700"
        remove.textContent = "×"

        item.append(link, remove)
        return item
      })
      this.drawerListTarget.replaceChildren(...items)
    }

    toggleDrawer() {
      this.drawerTarget.toggleAttribute("data-swimlane-drawer-open")
    }
  },
)

application.register(
  "swimlane-view",
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
    static values = { baseUrl: String }

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
      const url = new URL(this.baseUrlValue)
      url.searchParams.append("streams[]", name)
      window.location = url.toString()
    }
  },
)
