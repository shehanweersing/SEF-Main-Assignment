import { useForm } from 'react-hook-form'
import { zodResolver } from '@hookform/resolvers/zod'
import { z } from 'zod'
import LocationField from '../../components/LocationField'
import '../../components/location-fields.css'

const activityFormSchema = z.object({ title: z.string().min(2, 'Add a title'), location: z.string().min(2, 'Choose a location'), startTime: z.string().min(1, 'Select a start time'), endTime: z.string().min(1, 'Select an end time') })

export default function ActivityForm({ onSubmit, onCancel }) {
  const { register, handleSubmit, setValue, watch, formState: { errors } } = useForm({ resolver: zodResolver(activityFormSchema) })
  const location = watch('location', '')
  return <form className="inline-form activity-form" onSubmit={handleSubmit(onSubmit)}><label>Title<input {...register('title')} placeholder="Activity name" />{errors.title && <small className="field-error">{errors.title.message}</small>}</label><label className="location-form-label">Location<LocationField label="Activity location" value={location} onChange={(value) => setValue('location', value, { shouldValidate: true })} placeholder="Search Google Maps" />{errors.location && <small className="field-error">{errors.location.message}</small>}</label><label>Start<input type="datetime-local" {...register('startTime')} />{errors.startTime && <small className="field-error">{errors.startTime.message}</small>}</label><label>End<input type="datetime-local" {...register('endTime')} />{errors.endTime && <small className="field-error">{errors.endTime.message}</small>}</label><button className="button button-dark" type="submit">Save</button>{onCancel && <button className="button button-light" type="button" onClick={onCancel}>Cancel</button>}</form>
}
