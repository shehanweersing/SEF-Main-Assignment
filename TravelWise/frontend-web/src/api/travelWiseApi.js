import axiosInstance from './axiosInstance'

export const authApi = {
  login: (credentials) => axiosInstance.post('/Auth/login', credentials),
  register: (credentials) => axiosInstance.post('/Auth/register', credentials),
}

export const budgetApi = {
  listBudgets: (tripId) => axiosInstance.get('/Budget', { params: tripId ? { tripId } : undefined }),
  getBudget: (id) => axiosInstance.get(`/Budget/${id}`),
  createBudget: (budget) => axiosInstance.post('/Budget', budget),
  updateBudget: (id, budget) => axiosInstance.put(`/Budget/${id}`, budget),
  deleteBudget: (id) => axiosInstance.delete(`/Budget/${id}`),
  listExpenses: (budgetId) => axiosInstance.get('/Budget/expenses', { params: budgetId ? { budgetId } : undefined }),
  getExpense: (id) => axiosInstance.get(`/Budget/expenses/${id}`),
  addExpense: (expense) => axiosInstance.post('/Budget/expenses', expense),
  updateExpense: (id, expense) => axiosInstance.put(`/Budget/expenses/${id}`, expense),
  deleteExpense: (id) => axiosInstance.delete(`/Budget/expenses/${id}`),
}

export const activityApi = {
  list: (tripId) => axiosInstance.get('/Activity', { params: tripId ? { tripId } : undefined }),
  get: (id) => axiosInstance.get(`/Activity/${id}`),
  addActivity: (activity) => axiosInstance.post('/Activity', activity),
  update: (id, activity) => axiosInstance.put(`/Activity/${id}`, activity),
  remove: (id) => axiosInstance.delete(`/Activity/${id}`),
}

export const riskApi = {
  getWeather: (destination, signal) => axiosInstance.get('/Risk/weather', { params: { destination }, signal }),
  list: (tripId) => axiosInstance.get('/Risk', { params: tripId ? { tripId } : undefined }),
  get: (id) => axiosInstance.get(`/Risk/${id}`),
  addAssessment: (assessment) => axiosInstance.post('/Risk', assessment),
  update: (id, assessment) => axiosInstance.put(`/Risk/${id}`, assessment),
  remove: (id) => axiosInstance.delete(`/Risk/${id}`),
}

export const readinessApi = {
  list: (tripId) => axiosInstance.get('/Readiness', { params: tripId ? { tripId } : undefined }),
  get: (id) => axiosInstance.get(`/Readiness/${id}`),
  addDocument: (document) => axiosInstance.post('/Readiness', document),
  update: (id, document) => axiosInstance.put(`/Readiness/${id}`, document),
  remove: (id) => axiosInstance.delete(`/Readiness/${id}`),
}

export const tripApi = {
  list: (userId) => axiosInstance.get('/Trip', { params: userId ? { userId } : undefined }),
  get: (id) => axiosInstance.get(`/Trip/${id}`),
  create: (trip) => axiosInstance.post('/Trip', trip),
  update: (id, trip) => axiosInstance.put(`/Trip/${id}`, trip),
  remove: (id) => axiosInstance.delete(`/Trip/${id}`),
}

export async function getOrCreateTrip(userId) {
  const { data: trips } = await tripApi.list(userId)
  if (trips.length) return trips[0]
  const { data } = await tripApi.create({ userId, destination: 'Sri Lanka', startDate: new Date(Date.now() + 86400000 * 18).toISOString(), endDate: new Date(Date.now() + 86400000 * 26).toISOString(), travelObjective: 'A thoughtful Sri Lanka escape', status: 'Planning' })
  return data
}

export async function getOrCreateBudget(tripId) {
  const { data: budgets } = await budgetApi.listBudgets(tripId)
  if (budgets.length) return budgets[0]
  const { data } = await budgetApi.createBudget({ tripId, totalAllocation: 2400, currency: 'USD' })
  return data
}
