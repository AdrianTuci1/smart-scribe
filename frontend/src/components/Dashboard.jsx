import { useState, useEffect } from 'react'
import { Socket } from 'phoenix'

function Dashboard() {
  const [socket, setSocket] = useState(null)
  const [channel, setChannel] = useState(null)
  const [messages, setMessages] = useState([])
  const [userId] = useState("user-123") // Mock user
  const [note, setNote] = useState({ id: "note-1", content: "Test note" })
  const [status, setStatus] = useState("Disconnected")

  useEffect(() => {
    // Connect to Backend (assuming running on localhost:4000)
    // Note: Make sure Backend CORS allows localhost:5173
    const s = new Socket(`${import.meta.env.VITE_API_URL || "ws://localhost:4000"}/socket`, {params: {token: "mock-token"}})
    s.connect()
    setSocket(s)
    
    s.onOpen(() => setStatus("Connected to Socket"))
    s.onClose(() => setStatus("Disconnected"))

    return () => s.disconnect()
  }, [])

  const joinChannel = () => {
    if (!socket) return

    const chan = socket.channel(`transcription:${userId}`, {})
    chan.join()
      .receive("ok", resp => {
        setStatus("Joined Channel")
        console.log("Joined successfully", resp)
      })
      .receive("error", resp => {
        setStatus("Join Failed")
        console.log("Unable to join", resp)
      })

    chan.on("correction", payload => {
      setMessages(prev => [...prev, `Correction: ${payload.original} -> ${payload.corrected}`])
    })

    setChannel(chan)
  }

  const sendAudioMock = () => {
    if (channel) {
      channel.push("audio_chunk", {data: "base64-mock-data"})
      setMessages(prev => [...prev, "Sent audio chunk..."])
    }
  }

  const saveNote = async () => {
    try {
      const res = await fetch(`${import.meta.env.VITE_API_URL || "http://localhost:4000"}/api/v1/notes`, {
        method: "POST",
        headers: { "Content-Type": "application/json", "Authorization": "Bearer mock-token" },
        body: JSON.stringify({ noteId: note.id, content: note.content })
      })
      const data = await res.json()
      setMessages(prev => [...prev, `Saved Note: ${JSON.stringify(data)}`])
    } catch (e) {
       console.error(e)
       setMessages(prev => [...prev, `Error: ${e.message}`])
    }
  }

  return (
    <div className="dashboard-container" style={{ padding: '2rem', color: 'white' }}>
      <h1>VoiceScribe Dashboard</h1>
      <div className="card" style={{ background: '#333', padding: '1rem', marginBottom: '1rem', borderRadius: '8px' }}>
        <p>Status: {status}</p>
        <button onClick={joinChannel} style={{ marginRight: '10px' }}>Join Transcription Channel</button>
        <button onClick={sendAudioMock}>Simulate Audio Chunk</button>
      </div>
      
      <div className="card" style={{ background: '#333', padding: '1rem', marginBottom: '1rem', borderRadius: '8px' }}>
        <h2>Notes</h2>
        <input value={note.content} onChange={e => setNote({...note, content: e.target.value})} style={{ padding: '0.5rem', marginRight: '10px' }} />
        <button onClick={saveNote}>Save Note</button>
      </div>

      <div className="logs" style={{ background: '#111', padding: '1rem', borderRadius: '8px', fontFamily: 'monospace' }}>
        <h3>Logs</h3>
        {messages.map((m, i) => <div key={i}>{m}</div>)}
      </div>
    </div>
  )
}

export default Dashboard
