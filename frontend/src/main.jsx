import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

console.log(
  `%c
  _______
 |__   __|
    | |   _   _   ___  ___   __ _  _ __
    | |  | | | | / __|/ _ \\ / _\` || '_ \\
    | |  | |_| || (__|  __/| (_| || | | |
    |_|   \\__,_| \\___|\\___| \\__,_||_| |_|

   Built and managed by Tucean, part of V8Media.ro
   Please contact me at adrian.tucicovenco@gmail.com
  `,
  'color: #ebb434ff; font-weight: bold;'
);

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
