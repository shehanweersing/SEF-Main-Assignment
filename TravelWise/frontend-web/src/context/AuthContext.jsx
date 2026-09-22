import { createContext, useContext, useEffect, useState } from 'react'
import { authApi } from '../api/travelWiseApi'

const AuthContext = createContext(null)

function decodeRole(token) {
  try {
    const payload = JSON.parse(atob(token.split('.')[1]))
    return payload['http://schemas.microsoft.com/ws/2008/06/identity/claims/role'] || payload.role || 'Traveller'
  } catch {
    return 'Traveller'
  }
}

export function AuthProvider({ children }) {
  const [token, setToken] = useState(() => localStorage.getItem('travelwise_token'))
  const [user, setUser] = useState(() => JSON.parse(localStorage.getItem('travelwise_user') || 'null'))
  const role = user?.role || (token ? decodeRole(token) : null)

  useEffect(() => {
    if (token) localStorage.setItem('travelwise_token', token)
    else localStorage.removeItem('travelwise_token')
  }, [token])

  async function login(credentials) {
    const { data } = await authApi.login(credentials)
    const nextUser = { email: credentials.email, role: decodeRole(data.token) }
    setToken(data.token)
    setUser(nextUser)
    localStorage.setItem('travelwise_user', JSON.stringify(nextUser))
    return nextUser
  }

  function logout() {
    setToken(null)
    setUser(null)
    localStorage.removeItem('travelwise_token')
    localStorage.removeItem('travelwise_user')
  }

  return <AuthContext.Provider value={{ user, token, role, isAuthenticated: Boolean(token), login, logout }}>{children}</AuthContext.Provider>
}

export function useAuth() { return useContext(AuthContext) }
