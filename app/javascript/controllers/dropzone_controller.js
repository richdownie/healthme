import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "preview", "zone"]

  connect() {
    // Prevent browser default file-open on drag/drop anywhere on the page
    this.preventDrag = (e) => { e.preventDefault(); e.stopPropagation() }
    document.addEventListener("dragover", this.preventDrag)
    document.addEventListener("drop", this.preventDrag)
  }

  disconnect() {
    document.removeEventListener("dragover", this.preventDrag)
    document.removeEventListener("drop", this.preventDrag)
  }

  dragover(e) {
    e.preventDefault()
    e.stopPropagation()
    this.zoneTarget.classList.add("dropzone-active")
  }

  dragleave(e) {
    e.preventDefault()
    e.stopPropagation()
    this.zoneTarget.classList.remove("dropzone-active")
  }

  drop(e) {
    e.preventDefault()
    e.stopPropagation()
    this.zoneTarget.classList.remove("dropzone-active")
    const droppedFiles = [...e.dataTransfer.files].filter(f => f.type.startsWith("image/"))
    if (droppedFiles.length === 0) return

    // Merge dropped files with any existing files in the input
    const existing = [...this.inputTarget.files]
    const all = [...existing, ...droppedFiles]
    const dt = new DataTransfer()
    all.forEach(f => dt.items.add(f))
    this.inputTarget.files = dt.files

    this.#renderPreviews()
  }

  fileChanged() {
    this.#renderPreviews()
  }

  removeFile(e) {
    const index = parseInt(e.currentTarget.dataset.index)
    const dt = new DataTransfer()
    const files = [...this.inputTarget.files]
    files.splice(index, 1)
    files.forEach(f => dt.items.add(f))
    this.inputTarget.files = dt.files
    this.#renderPreviews()
  }

  #renderPreviews() {
    const files = [...this.inputTarget.files]
    this.previewTarget.innerHTML = ""
    files.forEach((file, i) => {
      const wrapper = document.createElement("div")
      wrapper.className = "dropzone-thumb"

      const img = document.createElement("img")
      img.src = URL.createObjectURL(file)
      img.alt = file.name

      const btn = document.createElement("button")
      btn.type = "button"
      btn.className = "dropzone-remove"
      btn.textContent = "×"
      btn.dataset.index = i
      btn.dataset.action = "click->dropzone#removeFile"

      wrapper.appendChild(img)
      wrapper.appendChild(btn)
      this.previewTarget.appendChild(wrapper)
    })
  }
}
