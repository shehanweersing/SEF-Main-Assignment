import { ArrowUpRight, CheckCircle2, CloudSun, LoaderCircle, ShieldAlert, Trash2, Wind } from 'lucide-react'
import { useEffect, useState } from 'react'
import { getOrCreateTrip, riskApi } from '../../api/travelWiseApi'
import { useAuth } from '../../context/AuthContext'
import LocationField from '../../components/LocationField'
import '../../components/location-fields.css'
import './weather.css'

const initialRisks = [
  { destination: 'Sri Lanka · Weather', level: 'Low', message: 'Dry season conditions expected across your route.', updated: 'Updated 2h ago' },
  { destination: 'Sri Lanka · Health', level: 'Moderate', message: 'Stay hydrated and carry mosquito repellent for the south coast.', updated: 'Updated yesterday' },
  { destination: 'Sri Lanka · Local advisories', level: 'Low', message: 'No active travel restrictions for your destinations.', updated: 'Updated Sep 19' },
]

export const riskSchema = null

function seasonalFallback(destination) {
  const wetSeason = [5, 6, 7, 8, 9, 10].includes(new Date().getMonth() + 1)
  return { destination, source: 'TravelWise seasonal estimate', isFallback: true, temperatureC: wetSeason ? 27 : 29, relativeHumidity: wetSeason ? 82 : 72, windSpeedKmh: wetSeason ? 18 : 11, summary: wetSeason ? 'Warm with seasonal showers' : 'Warm and mostly settled', advisory: 'Live weather could not be reached. Pack light rain protection and check local advisories before outdoor activities.' }
}

export default function RiskPage() {
  const { user } = useAuth()
  const [items, setItems] = useState(initialRisks)
  const [destination, setDestination] = useState('Sri Lanka')
  const [weather, setWeather] = useState(null)
  const [weatherNotice, setWeatherNotice] = useState('')
  const [loadingWeather, setLoadingWeather] = useState(false)
  const [serverError, setServerError] = useState('')

  async function loadWeather(value = destination) {
    setLoadingWeather(true)
    setWeatherNotice('')
    try {
      const { data } = await riskApi.getWeather(value)
      setWeather(data)
      if (data.isFallback) setWeatherNotice('Live weather is unavailable. Showing a seasonal estimate instead.')
    } catch {
      setWeather(seasonalFallback(value))
      setWeatherNotice('Live weather is unavailable. Showing a seasonal estimate instead.')
    } finally {
      setLoadingWeather(false)
    }
  }

  useEffect(() => { loadWeather() }, [])

  async function refresh() {
    setServerError('')
    try {
      const trip = await getOrCreateTrip(user.id)
      const { data } = await riskApi.addAssessment({ tripId: trip.id, destination, severityLevel: 'Low', advisoryMessage: weather?.advisory || 'No active travel restrictions.' })
      setItems((current) => [{ id: data.id, destination: `${data.destination} · Latest assessment`, level: data.severityLevel, message: data.advisoryMessage, updated: 'Just now' }, ...current])
      await loadWeather(destination)
    } catch (error) {
      setServerError(error.response?.data || 'Could not refresh travel intelligence.')
    }
  }

  async function removeAssessment(item) {
    if (!item.id || !window.confirm('Delete this assessment?')) return
    try { await riskApi.remove(item.id); setItems((current) => current.filter((entry) => entry.id !== item.id)) } catch (error) { setServerError(error.response?.data || 'Could not delete this assessment.') }
  }

  return <><div className="page-intro"><div><span className="eyebrow">Travel intelligence</span><h1>Know before you go.</h1><p>Live conditions with a calm seasonal fallback when the signal goes quiet.</p></div><button className="button button-dark" onClick={refresh}><ShieldAlert size={16} /> Refresh radar</button></div><div className="risk-location"><span className="eyebrow">Assess a destination</span><LocationField label="Risk destination" value={destination} onChange={setDestination} placeholder="Search Google Maps" /><button className="button button-light" type="button" onClick={() => loadWeather(destination)}>Update weather</button></div>{serverError && <div className="form-error">{String(serverError)}</div>}{weatherNotice && <div className="weather-notice" role="status">{weatherNotice}</div>}{weather && <section className="weather-telemetry"><div className="weather-heading"><div><span className="eyebrow">Weather telemetry</span><h2>{weather.destination}</h2></div><span className={`weather-source ${weather.isFallback ? 'fallback' : 'live'}`}><span />{weather.source}</span></div><div className="weather-metrics"><div><CloudSun size={18} /><strong>{weather.temperatureC ?? '--'}°C</strong><small>{weather.summary}</small></div><div><span className="weather-metric-label">Humidity</span><strong>{weather.relativeHumidity ?? '--'}%</strong></div><div><Wind size={18} /><strong>{weather.windSpeedKmh ?? '--'} km/h</strong><small>Wind</small></div></div><p className="weather-advisory">{weather.advisory}</p></section>}{loadingWeather && <div className="trips-loading"><LoaderCircle className="spin" size={18} /> Refreshing weather...</div>}<div className="risk-hero"><div className="risk-score"><span>Overall outlook</span><strong>Good to go</strong><div className="risk-meter"><span /></div><small>Based on {items.length} active signals</small></div><div className="risk-hero-note"><CheckCircle2 size={20} /><span><strong>No critical alerts</strong>Your current itinerary is in a comfortable zone.</span></div></div><section className="risk-list">{items.map((item, index) => <article className="risk-card" key={`${item.destination}-${index}`}><div className={`severity-badge ${item.level.toLowerCase()}`}><span />{item.level}</div><div className="risk-card-copy"><h2>{item.destination}</h2><p>{item.message}</p><small>{item.updated}</small></div>{item.id ? <button className="icon-button" title="Delete assessment" onClick={() => removeAssessment(item)}><Trash2 size={14} /></button> : <ArrowUpRight size={18} />}</article>)}</section></>
}
