import { CalendarDays, LoaderCircle, MapPin, X } from 'lucide-react'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import LocationField from '../../components/LocationField'
import '../../components/location-fields.css'

const activityFormSchema = z.object({
  title: z.string().trim().min(2, 'Add a title'),
  location: z.string().trim().min(2, 'Choose a location'),
  startTime: z.string().min(1, 'Select a start time'),
  endTime: z.string().min(1, 'Select an end time'),
}).refine((values) => {
  if (!values.startTime || !values.endTime) return true
  return new Date(values.startTime) < new Date(values.endTime)
}, { path: ['endTime'], message: 'End time must be after start time' })

function toLocalInput(value) {
  if (!value) return ''
  const date = new Date(value)
  const offset = date.getTimezoneOffset() * 60000
  return new Date(date.getTime() - offset).toISOString().slice(0, 16)
}

function getApiMessage(error) {
  if (error.response?.status === 409) return error.response.data || 'This activity overlaps with another scheduled activity.'
  if (error.response?.status === 400) return error.response.data || 'Activity time must stay inside the selected trip dates.'
  return 'Could not save this activity. Check your connection and try again.'
}

export default function ActivityForm({ selectedTrip, onSubmit, onCancel }) {
  const [serverError, setServerError] = useState('')
  const tripStart = toLocalInput(selectedTrip?.startDate)
  const tripEnd = toLocalInput(selectedTrip?.endDate)
  const { register, handleSubmit, setValue, watch, formState: { errors, isSubmitting } } = useForm({ resolver: zodResolver(activityFormSchema), defaultValues: { startTime: tripStart, endTime: tripEnd } })
  const location = watch('location', '')

  async function submit(values) {
    setServerError('')
    try {
      await onSubmit(values)
    } catch (error) {
      setServerError(getApiMessage(error))
    }
  }

  return <form className="inline-form activity-form" onSubmit={handleSubmit(submit)} noValidate><div className="activity-form-heading"><span className="eyebrow">{selectedTrip ? `Inside ${selectedTrip.destination}` : 'Schedule activity'}</span>{onCancel && <button type="button" className="icon-button" onClick={onCancel} title="Close form"><X size={16} /></button>}</div><label>Title<input {...register('title')} placeholder="Activity name" />{errors.title && <small className="field-error">{errors.title.message}</small>}</label><label className="location-form-label">Location<LocationField label="Activity location" value={location} onChange={(value) => setValue('location', value, { shouldValidate: true })} placeholder="Search Google Maps" />{errors.location && <small className="field-error">{errors.location.message}</small>}</label><label>Start<div className="trip-input"><CalendarDays size={15} /><input type="datetime-local" min={tripStart || undefined} max={tripEnd || undefined} {...register('startTime')} /></div>{errors.startTime && <small className="field-error">{errors.startTime.message}</small>}</label><label>End<div className="trip-input"><CalendarDays size={15} /><input type="datetime-local" min={tripStart || undefined} max={tripEnd || undefined} {...register('endTime')} /></div>{errors.endTime && <small className="field-error">{errors.endTime.message}</small>}</label>{serverError && <div className="form-error activity-alert" role="alert">{String(serverError)}</div>}<button className="button button-dark" type="submit" disabled={isSubmitting}>{isSubmitting ? <><LoaderCircle className="spin" size={15} /> Saving...</> : 'Save activity'}</button>{onCancel && <button className="button button-light" type="button" onClick={onCancel}>Cancel</button>}</form>
}
