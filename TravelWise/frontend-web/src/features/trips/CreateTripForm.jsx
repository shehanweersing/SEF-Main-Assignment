import { CalendarDays, LoaderCircle, MapPin, Plus, X } from 'lucide-react'
import { useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { createTrip, updateTrip } from '../../api/tripApi'
import { tripDefaultValues, tripSchema } from './tripSchema'
import { useAuth } from '../../context/AuthContext'

export default function CreateTripForm({ trip, onCreated, onCancel }) {
  const { user } = useAuth()
  const [serverError, setServerError] = useState('')
  const { register, handleSubmit, reset, formState: { errors, isSubmitting } } = useForm({ resolver: zodResolver(tripSchema), defaultValues: tripDefaultValues })
  useEffect(() => {
    if (!trip) return
    const startPoint = trip.travelObjective?.replace(/^From\s+/i, '') || ''
    reset({ StartPoint: startPoint, Destination: trip.destination, StartDate: trip.startDate?.slice(0, 10), EndDate: trip.endDate?.slice(0, 10) })
  }, [trip, reset])
  async function submit(values) {
    setServerError('')
    try {
      const payload = { userId: trip?.userId || user?.id, destination: values.Destination, startDate: new Date(`${values.StartDate}T00:00:00`).toISOString(), endDate: new Date(`${values.EndDate}T00:00:00`).toISOString(), travelObjective: `From ${values.StartPoint}`, status: trip?.status || 'Created' }
      const saved = trip ? await updateTrip(trip.id, payload) : await createTrip(payload)
      reset()
      onCreated?.(saved)
    } catch (error) {
      setServerError(error.response?.data || `Could not ${trip ? 'update' : 'create'} this trip. Please try again.`)
    }
  }
  return <form className="trip-form" onSubmit={handleSubmit(submit)} noValidate><div className="trip-form-heading"><div><span className="eyebrow">{trip ? 'Edit journey' : 'New journey'}</span><h2>{trip ? 'Refine the trip ahead.' : 'Shape the trip ahead.'}</h2></div>{onCancel && <button type="button" className="icon-button" onClick={onCancel} title="Close form"><X size={17} /></button>}</div><div className="trip-form-grid"><label>Start point<div className="trip-input"><MapPin size={16} /><input placeholder="Colombo" {...register('StartPoint')} /></div>{errors.StartPoint && <small className="field-error">{errors.StartPoint.message}</small>}</label><label>Destination<div className="trip-input"><MapPin size={16} /><input placeholder="Galle, Sri Lanka" {...register('Destination')} /></div>{errors.Destination && <small className="field-error">{errors.Destination.message}</small>}</label><label>Start date<div className="trip-input"><CalendarDays size={16} /><input type="date" {...register('StartDate')} /></div>{errors.StartDate && <small className="field-error">{errors.StartDate.message}</small>}</label><label>End date<div className="trip-input"><CalendarDays size={16} /><input type="date" {...register('EndDate')} /></div>{errors.EndDate && <small className="field-error">{errors.EndDate.message}</small>}</label></div>{serverError && <div className="form-error">{String(serverError)}</div>}<button className="button button-coral" type="submit" disabled={isSubmitting}>{isSubmitting ? <LoaderCircle className="spin" size={16} /> : <Plus size={16} />}{isSubmitting ? 'Saving trip...' : trip ? 'Save trip' : 'Create trip'}</button></form>
}
