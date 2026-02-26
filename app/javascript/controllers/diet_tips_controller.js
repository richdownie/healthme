import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["content", "button", "question", "mic"]
  static values = { url: String }

  connect() {
    this.recognition = null
    this.isListening = false
  }

  disconnect() {
    this.#stopDictation()
  }

  toggleDictation() {
    if (this.isListening) {
      this.#stopDictation()
    } else {
      this.#startDictation()
    }
  }

  #startDictation() {
    const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition
    if (!SpeechRecognition) {
      this.questionTarget.placeholder = "Speech recognition not supported"
      return
    }

    this.recognition = new SpeechRecognition()
    this.recognition.continuous = false
    this.recognition.interimResults = true
    this.recognition.lang = "en-US"

    this.recognition.onstart = () => {
      this.isListening = true
      this.micTarget.classList.add("listening")
    }

    this.recognition.onresult = (event) => {
      let transcript = ""
      for (let i = 0; i < event.results.length; i++) {
        transcript += event.results[i][0].transcript
      }
      this.questionTarget.value = transcript
    }

    this.recognition.onend = () => {
      this.isListening = false
      this.micTarget.classList.remove("listening")
      this.recognition = null
    }

    this.recognition.onerror = () => {
      this.isListening = false
      this.micTarget.classList.remove("listening")
      this.recognition = null
    }

    this.recognition.start()
  }

  #stopDictation() {
    if (this.recognition) {
      this.recognition.stop()
      this.recognition = null
    }
    this.isListening = false
    if (this.hasMicTarget) {
      this.micTarget.classList.remove("listening")
    }
  }

  async load() {
    this.buttonTarget.disabled = true
    this.buttonTarget.textContent = "Thinking..."
    this.contentTarget.innerHTML = '<p class="tips-loading">Analyzing your activities...</p>'
    this.contentTarget.style.display = "block"

    let url = this.urlValue
    const question = this.hasQuestionTarget ? this.questionTarget.value.trim() : ""
    if (question) {
      url += (url.includes("?") ? "&" : "?") + "question=" + encodeURIComponent(question)
    }

    try {
      const response = await fetch(url)
      if (!response.ok) throw new Error("Failed to load tips")

      const data = await response.json()
      this.contentTarget.innerHTML = this.#formatTips(data.tips)
      this.buttonTarget.textContent = "Refresh Tips"
    } catch (e) {
      this.contentTarget.innerHTML = '<p class="tips-error">Could not generate tips. Make sure you have activities logged and an API key configured.</p>'
      this.buttonTarget.textContent = "Get Daily Tips"
    }

    this.buttonTarget.disabled = false
  }

  #formatTips(text) {
    const escaped = text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")
    const html = escaped
      .replace(/\*\*(.+?)\*\*/g, "<strong>$1</strong>")
      .replace(/\n/g, "<br>")
    return `<div class="tips-content">${html}</div>`
  }
}
