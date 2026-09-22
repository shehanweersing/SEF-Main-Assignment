import api from './axiosInstance'

export async function fetchTrips(searchQuery = '') {
  const { data } = await api.get('/Trip', { params: searchQuery.trim() ? { search: searchQuery.trim() } : undefined })
  return data
}

export async function createTrip(tripData) {
  const { data } = await api.post('/Trip', tripData)
  return data
}
