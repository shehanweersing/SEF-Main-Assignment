import api from './axiosInstance'

export async function fetchTrips(searchQuery = '', userId) {
  const params = {}
  if (searchQuery.trim()) params.search = searchQuery.trim()
  if (userId) params.userId = userId
  const { data } = await api.get('/Trip', { params })
  return Array.isArray(data) ? data : data ? [data] : []
}

export async function createTrip(tripData) {
  const { data } = await api.post('/Trip', tripData)
  return data
}

export async function updateTrip(id, tripData) {
  const { data } = await api.put(`/Trip/${id}`, tripData)
  return data
}

export async function deleteTrip(id) {
  return api.delete(`/Trip/${id}`)
}
