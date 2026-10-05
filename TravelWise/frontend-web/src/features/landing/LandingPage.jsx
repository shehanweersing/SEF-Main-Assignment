import { useEffect, useRef, useState } from 'react'
import { Link } from 'react-router-dom'
import './planet-landing.css'

const states = {
  bali: { name: 'Bali', next: 'Swiss Alps', number: '[01]', image: 'https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=2200&q=88', facts: [['Best for:', 'Island escapes, wellness, temples, and slow mornings.'], ['Best season:', 'April to October for warm, dry days.'], ['Typical stay:', '7–10 days across Ubud, Canggu, and the coast.'], ['Travel style:', 'Beach, culture, food, and restorative adventure.']] },
  alps: { name: 'Swiss Alps', next: 'Kyoto', number: '[02]', image: 'https://images.unsplash.com/photo-1531366936337-7c912a4589a7?auto=format&fit=crop&w=2200&q=88', facts: [['Best for:', 'Mountain villages, scenic rail journeys, and fresh air.'], ['Best season:', 'December to March for snow; June to September for hiking.'], ['Typical stay:', '5–8 days between Lucerne, Zermatt, and Interlaken.'], ['Travel style:', 'Nature, wellness, photography, and outdoor adventure.']] },
  kyoto: { name: 'Kyoto', next: 'Santorini', number: '[03]', image: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?auto=format&fit=crop&w=2200&q=88', facts: [['Best for:', 'Temples, tea houses, gardens, and unforgettable food.'], ['Best season:', 'March to May or October to November for mild weather.'], ['Typical stay:', '4–6 days with day trips to Nara and Osaka.'], ['Travel style:', 'Culture, design, history, and considered exploration.']] },
  santorini: { name: 'Santorini', next: 'Maldives', number: '[04]', image: 'https://images.unsplash.com/photo-1533105079780-92b9be482077?auto=format&fit=crop&w=2200&q=88', facts: [['Best for:', 'Sunset villages, volcanic coastlines, and long lunches.'], ['Best season:', 'May to October for bright skies and warm seas.'], ['Typical stay:', '4–7 days around Oia, Fira, and the caldera.'], ['Travel style:', 'Romance, beaches, food, and island discovery.']] },
  maldives: { name: 'Maldives', next: 'Bali', number: '[05]', image: 'https://images.unsplash.com/photo-1507525424584-4e6b3f3f6f5d?auto=format&fit=crop&w=2200&q=88', facts: [['Best for:', 'Turquoise lagoons, reef adventures, and total reset.'], ['Best season:', 'November to April for the driest, clearest weather.'], ['Typical stay:', '5–8 days on a private island or local atoll.'], ['Travel style:', 'Luxury, diving, wellness, and barefoot escapes.']] },
}
const order = ['Bali', 'Swiss Alps', 'Kyoto', 'Santorini', 'Maldives']

export default function LandingPage() {
  const rootRef = useRef(null)
  const portalRef = useRef(null)
  const portalCanvasRef = useRef(null)
  const preloaderRef = useRef(null)
  const [planet, setPlanet] = useState('bali')
  const [progress, setProgress] = useState(0)
  const [ready, setReady] = useState(false)
  const [busy, setBusy] = useState(false)
  const [cursor, setCursor] = useState({ x: 0, y: 0, visible: false, enter: false })
  const current = states[planet]
  const nextKey = { bali: 'alps', alps: 'kyoto', kyoto: 'santorini', santorini: 'maldives', maldives: 'bali' }[planet]

  useEffect(() => {
    document.body.classList.add('planet-body')
    return () => document.body.classList.remove('planet-body')
  }, [])

  useEffect(() => {
    let value = 0
    const timer = window.setInterval(() => {
      value = Math.min(100, value + 8)
      setProgress(value)
      if (value === 100) {
        clearInterval(timer)
        setReady(true)
      }
    }, 35)
    return () => clearInterval(timer)
  }, [])

  useEffect(() => {
    const canvas = portalCanvasRef.current
    const portal = portalRef.current
    const root = rootRef.current
    if (!canvas || !portal || !root) return undefined
    const ctx = canvas.getContext('2d')
    const media = new Image()
    if (current.image) media.src = current.image
    let frame
    let tiltX = 0
    let tiltY = 0
    let targetX = 0
    let targetY = 0
    const resize = () => { const d = Math.min(window.devicePixelRatio || 1, 2); canvas.width = innerWidth * d; canvas.height = innerHeight * d; canvas.style.width = `${innerWidth}px`; canvas.style.height = `${innerHeight}px`; ctx.setTransform(d, 0, 0, d, 0, 0) }
    const points = (w, h, radius) => {
      const result = []
      const arcs = [[w / 2 - radius, -h / 2 + radius, -Math.PI / 2, 0], [w / 2 - radius, h / 2 - radius, 0, Math.PI / 2], [-w / 2 + radius, h / 2 - radius, Math.PI / 2, Math.PI], [-w / 2 + radius, -h / 2 + radius, Math.PI, Math.PI * 1.5]]
      arcs.forEach(([x, y, from, to]) => { for (let i = 0; i <= 10; i += 1) { const angle = from + (to - from) * i / 10; result.push([x + radius * Math.cos(angle), y + radius * Math.sin(angle)]) } })
      return result
    }
    const drawCover = (source) => {
      const width = source.videoWidth || source.naturalWidth
      const height = source.videoHeight || source.naturalHeight
      if (!width || !height) return
      const scale = Math.max(innerWidth / width, innerHeight / height)
      const drawWidth = width * scale
      const drawHeight = height * scale
      ctx.drawImage(source, (innerWidth - drawWidth) / 2, (innerHeight - drawHeight) / 2, drawWidth, drawHeight)
    }
    const draw = (time) => {
      const delta = Math.min(40, time - (draw.last || time)); draw.last = time
      tiltX += (targetX - tiltX) * Math.min(1, delta * .009)
      tiltY += (targetY - tiltY) * Math.min(1, delta * .009)
      ctx.clearRect(0, 0, innerWidth, innerHeight)
      const rect = portal.getBoundingClientRect()
      const w = rect.width
      const h = rect.height
      const cx = rect.left + rect.width / 2
      const cy = rect.top + rect.height / 2
      const radius = Math.min(90, w / 2, h / 2)
      const projection = (x, y) => { const ax = tiltX * Math.PI / 180; const ay = tiltY * Math.PI / 180; const xx = x * Math.cos(ay); const yy = y * Math.cos(ax); const z = x * Math.sin(ay) - y * Math.sin(ax); const scale = 850 / (850 + z); return [cx + xx * scale, cy + yy * scale] }
      const shape = points(w, h, radius)
      ctx.beginPath()
      shape.forEach(([x, y], index) => { const [px, py] = projection(x, y); if (index) ctx.lineTo(px, py); else ctx.moveTo(px, py) })
      ctx.closePath()
      ctx.save(); ctx.clip(); drawCover(media); const shade = ctx.createLinearGradient(0, innerHeight * .52, 0, innerHeight); shade.addColorStop(0, 'transparent'); shade.addColorStop(1, 'rgba(0,0,0,.88)'); ctx.fillStyle = shade; ctx.fillRect(0, innerHeight * .52, innerWidth, innerHeight); ctx.restore()
      frame = requestAnimationFrame(draw)
    }
    const move = (event) => { targetY = (event.clientX / innerWidth - .5) * 37.4; targetX = (event.clientY / innerHeight - .5) * -33 }
    resize(); window.addEventListener('resize', resize); window.addEventListener('pointermove', move); frame = requestAnimationFrame(draw)
    return () => { cancelAnimationFrame(frame); window.removeEventListener('resize', resize); window.removeEventListener('pointermove', move) }
  }, [current, planet])

  async function travel() {
    if (busy) return
    setBusy(true)
    const start = performance.now()
    await new Promise((resolve) => {
      const tick = (time) => { if (time - start >= 1100) resolve(); else requestAnimationFrame(tick) }
      requestAnimationFrame(tick)
    })
    setPlanet(nextKey)
    setBusy(false)
  }

  const handlePointer = (event) => setCursor({ x: event.clientX, y: event.clientY, visible: true, enter: event.type === 'pointerenter' })
  return <main ref={rootRef} className={`planet-experience ${ready ? 'is-ready' : ''} ${busy ? 'is-transitioning' : ''}`}>
    <div className="planet-backgrounds" aria-hidden="true">
      {Object.entries(states).map(([key, destination]) => <img key={key} className={planet === key ? 'visible' : ''} src={destination.image} alt="" />)}
    </div>
    <div ref={preloaderRef} className={`planet-preloader ${ready ? 'done' : ''}`} />
    <div className="planet-shade" />
    <header className="planet-header">
      <Link to="/" className="planet-logo"><span>TW</span> TravelWise</Link>
      <nav><a className="active" href="#about">About</a><a href="#explore">Explore</a><a href="#planets">Destinations</a></nav>
      <div className="planet-actions"><Link to="/login">Log in</Link><Link className="planet-menu" to="/register">Join TravelWise</Link></div>
    </header>
    <aside className="planet-list">{order.map((item) => <span className={item.toLowerCase() === current.name.toLowerCase() ? 'active' : ''} key={item}>{item}</span>)}</aside>
    <section className="planet-portal-wrap">
      <button ref={portalRef} className="planet-portal" onClick={travel} onPointerEnter={() => setCursor((value) => ({ ...value, enter: true }))} onPointerLeave={() => setCursor((value) => ({ ...value, enter: false }))} aria-label={`Travel to ${current.next}`}><img src={current.image} alt="" /></button>
    </section>
    <canvas ref={portalCanvasRef} className="planet-portal-canvas" aria-hidden="true" />
    <section className="planet-content"><h1>{current.name.toUpperCase()}</h1><dl>{current.facts.map(([label, value]) => <div className="planet-fact" key={label}><dt>{label}</dt><dd>{value}</dd></div>)}</dl></section>
    <div className="planet-loader">{progress}%</div>
    <div className={`planet-cursor ${cursor.visible ? 'visible' : ''} ${cursor.enter ? 'enter' : ''}`} onPointerMove={handlePointer} style={{ transform: `translate3d(${cursor.x}px, ${cursor.y}px, 0)` }}><i /><b>Enter</b></div>
  </main>
}
