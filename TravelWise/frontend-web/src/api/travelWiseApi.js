import axiosInstance from './axiosInstance'

export const authApi = {
  login: (credentials) => axiosInstance.post('/Auth/login', credentials),
  register: (credentials) => axiosInstance.post('/Auth/register', credentials),
}

export const budgetApi = {
  addExpense: (expense) => axiosInstance.post('/Budget/expenses', expense),
}

export const activityApi = {
  addActivity: (activity) => axiosInstance.post('/Activity', activity),
}

export const riskApi = {
  addAssessment: (assessment) => axiosInstance.post('/Risk', assessment),
}

export const readinessApi = {
  addDocument: (document) => axiosInstance.post('/Readiness', document),
}
