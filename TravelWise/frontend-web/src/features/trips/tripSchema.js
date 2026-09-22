import { z } from 'zod'

export const tripSchema = z.object({
  StartPoint: z.string().trim().min(2, 'Start point is required'),
  Destination: z.string().trim().min(2, 'Destination is required'),
  StartDate: z.string().min(1, 'Start date is required'),
  EndDate: z.string().min(1, 'End date is required'),
}).refine((values) => {
  if (!values.StartDate || !values.EndDate) return true
  return new Date(values.EndDate) > new Date(values.StartDate)
}, { path: ['EndDate'], message: 'End date must be after the start date' })

export const tripDefaultValues = { StartPoint: '', Destination: '', StartDate: '', EndDate: '' }
