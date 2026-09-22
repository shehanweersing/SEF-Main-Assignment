import { BrowserRouter, Navigate, Route, Routes } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import LandingPage from '../features/landing/LandingPage'
import LoginPage from '../features/auth/LoginPage'
import RegisterPage from '../features/auth/RegisterPage'
import DashboardLayout from '../features/dashboard/DashboardLayout'
import DashboardHome from '../features/dashboard/DashboardHome'
import BudgetPage from '../features/budget/BudgetPage'
import ActivityPage from '../features/activity/ActivityPage'
import RiskPage from '../features/risk/RiskPage'
import ReadinessPage from '../features/readiness/ReadinessPage'
import ApprovalQueue from '../features/approvals/ApprovalQueue'
import ProtectedRoute from '../components/ProtectedRoute'

function Unauthorized() { return <div className="center-page"><span className="eyebrow">403</span><h1>That view is restricted.</h1><p>Your workspace role does not have access to this area.</p><a className="button button-primary" href="/dashboard">Back to dashboard</a></div> }
function LoginRedirect() { const { isAuthenticated } = useAuth(); return isAuthenticated ? <Navigate to="/dashboard" replace /> : <LoginPage /> }

export default function AppRoutes() { return <BrowserRouter><Routes>
  <Route path="/" element={<LandingPage />} /><Route path="/results" element={<LandingPage />} /><Route path="/login" element={<LoginRedirect />} /><Route path="/register" element={<RegisterPage />} /><Route path="/unauthorized" element={<Unauthorized />} />
  <Route element={<ProtectedRoute />}><Route element={<DashboardLayout />}><Route path="/dashboard" element={<DashboardHome />} /><Route path="/dashboard/budget" element={<BudgetPage />} /><Route path="/dashboard/activity" element={<ActivityPage />} /><Route path="/dashboard/risk" element={<RiskPage />} /><Route path="/dashboard/readiness" element={<ReadinessPage />} /></Route><Route path="/approvals" element={<ProtectedRoute allowedRoles={['Admin']} />}><Route index element={<ApprovalQueue />} /></Route></Route>
  <Route path="*" element={<Navigate to="/" replace />} />
</Routes></BrowserRouter> }
