import { useRef, useState, type ChangeEvent, type FormEvent } from 'react'
import './App.css'

const MAX_UPLOAD_BYTES = 25 * 1024 * 1024

type FileVisibility = 'private' | 'household'

interface FileMetadata {
  id: string
  name: string
  content_type: string
  size_bytes: number
  sha256: string
  folder_id: string
  visibility: FileVisibility
  description: string | null
  created_at: string
  updated_at: string
}

interface ErrorEnvelope {
  error?: {
    code?: string
    message?: string
  }
}

function App() {
  const [file, setFile] = useState<File | null>(null)
  const [folderId, setFolderId] = useState('')
  const [visibility, setVisibility] = useState<FileVisibility>('household')
  const [description, setDescription] = useState('')
  const [uploading, setUploading] = useState(false)
  const [error, setError] = useState('')
  const [uploadedFile, setUploadedFile] = useState<FileMetadata | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  function handleFileChange(event: ChangeEvent<HTMLInputElement>) {
    const selectedFile = event.target.files?.[0] ?? null
    setError('')
    setUploadedFile(null)

    if (selectedFile && selectedFile.size > MAX_UPLOAD_BYTES) {
      setFile(null)
      setError('The selected file exceeds the 25 MB upload limit.')
      event.target.value = ''
      return
    }

    setFile(selectedFile)
  }

  async function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setError('')
    setUploadedFile(null)

    if (!file) {
      setError('Choose a file to upload.')
      return
    }
    if (file.size > MAX_UPLOAD_BYTES) {
      setError('The selected file exceeds the 25 MB upload limit.')
      return
    }
    if (!folderId.trim()) {
      setError('Folder ID is required.')
      return
    }

    const token =
      window.localStorage.getItem('access_token') ||
      window.localStorage.getItem('token')
    if (!token) {
      setError('Sign in before uploading a file.')
      return
    }

    const formData = new FormData()
    formData.append('file', file)
    formData.append('folder_id', folderId.trim())
    formData.append('visibility', visibility)
    if (description.trim()) {
      formData.append('description', description.trim())
    }

    const headers = new Headers()
    headers.set('Authorization', `Bearer ${token}`)

    setUploading(true)
    try {
      const response = await fetch('/api/v1/files', {
        method: 'POST',
        headers,
        body: formData,
      })

      if (!response.ok) {
        let message = `Upload failed (${response.status}).`
        try {
          const envelope = (await response.json()) as ErrorEnvelope
          if (envelope.error?.message) {
            message = envelope.error.message
          }
        } catch {
          // Keep the status-based fallback for non-JSON responses.
        }
        setError(message)
        return
      }

      const metadata = (await response.json()) as FileMetadata
      setUploadedFile(metadata)
      setFile(null)
      setDescription('')
      if (fileInputRef.current) {
        fileInputRef.current.value = ''
      }
    } catch {
      setError('Unable to upload the file. Check your connection and try again.')
    } finally {
      setUploading(false)
    }
  }

  return (
    <main className="file-page">
      <section className="file-card" aria-labelledby="upload-heading">
        <header>
          <p className="eyebrow">Household files</p>
          <h1 id="upload-heading">Upload a file</h1>
          <p className="subtitle">Store a family document or photo securely.</p>
        </header>

        <form onSubmit={handleSubmit}>
          <div className="field">
            <label htmlFor="file">File</label>
            <input
              id="file"
              name="file"
              type="file"
              ref={fileInputRef}
              onChange={handleFileChange}
              disabled={uploading}
              aria-describedby="file-help"
            />
            <small id="file-help">Maximum size: 25 MB</small>
          </div>

          <div className="field">
            <label htmlFor="folder_id">Folder ID</label>
            <input
              id="folder_id"
              name="folder_id"
              type="text"
              value={folderId}
              placeholder="Enter destination folder ID"
              onChange={(event) => setFolderId(event.target.value)}
              required
              disabled={uploading}
            />
          </div>

          <div className="field">
            <label htmlFor="visibility">Visibility</label>
            <select
              id="visibility"
              name="visibility"
              value={visibility}
              onChange={(event) =>
                setVisibility(event.target.value as FileVisibility)
              }
              disabled={uploading}
            >
              <option value="household">Household</option>
              <option value="private">Private</option>
            </select>
          </div>

          <div className="field">
            <label htmlFor="description">
              Description <span>(optional)</span>
            </label>
            <textarea
              id="description"
              name="description"
              value={description}
              onChange={(event) => setDescription(event.target.value)}
              rows={3}
              disabled={uploading}
            />
          </div>

          {error && (
            <p className="message error" role="alert">
              {error}
            </p>
          )}

          {uploadedFile && (
            <div className="message success" role="status">
              <strong>Upload complete</strong>
              <span>{uploadedFile.name}</span>
              <small>
                {uploadedFile.content_type} · {uploadedFile.size_bytes} bytes
              </small>
              <code>{uploadedFile.sha256}</code>
            </div>
          )}

          <button type="submit" disabled={uploading || !file}>
            {uploading ? 'Uploading…' : 'Upload file'}
          </button>
        </form>
      </section>
    </main>
  )
}

export default App
