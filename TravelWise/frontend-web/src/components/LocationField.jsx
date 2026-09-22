import { ExternalLink, MapPin } from 'lucide-react'

export default function LocationField({ label = 'Location', value, onChange, placeholder = 'Search a place', compact = false }) {
  const mapUrl = value ? `https://www.google.com/maps?q=${encodeURIComponent(value)}&output=embed` : ''
  const mapsLink = value ? `https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(value)}` : '#'
  return <div className={`location-field ${compact ? 'compact' : ''}`}><div className="location-input-row"><MapPin size={16} /><input value={value || ''} onChange={(event) => onChange?.(event.target.value)} placeholder={placeholder} aria-label={label} /><a href={mapsLink} target="_blank" rel="noreferrer" title="Open in Google Maps" className="maps-open"><ExternalLink size={14} /></a></div>{value && <div className="location-map-preview"><iframe title={`${label} map`} src={mapUrl} loading="lazy" referrerPolicy="no-referrer-when-downgrade" /></div>}</div>
}
