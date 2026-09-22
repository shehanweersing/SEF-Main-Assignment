import { NavLink } from 'react-router-dom'
import { Activity, BarChart3, FileCheck2, LayoutDashboard, LogOut, ShieldAlert, Sparkles, Wallet } from 'lucide-react'
import { useAuth } from '../context/AuthContext'

const links = [
  { label: 'Overview', to: '/dashboard', icon: LayoutDashboard, roles: ['Traveller', 'Admin', 'Staff'] },
  { label: 'Budget', to: '/dashboard/budget', icon: Wallet, roles: ['Traveller', 'Admin', 'Staff'] },
  { label: 'Activities', to: '/dashboard/activity', icon: Activity, roles: ['Traveller', 'Admin', 'Staff'] },
  { label: 'Risk radar', to: '/dashboard/risk', icon: ShieldAlert, roles: ['Traveller', 'Admin', 'Staff'] },
  { label: 'Readiness', to: '/dashboard/readiness', icon: FileCheck2, roles: ['Traveller', 'Admin', 'Staff'] },
  { label: 'AI approvals', to: '/approvals', icon: Sparkles, roles: ['Admin'] },
]

export default function Sidebar() {
  const { role, user, logout } = useAuth()
  return <aside className="sidebar">
    <div className="brand"><span className="brand-mark">TW</span><span>TravelWise</span></div>
    <div className="sidebar-kicker">Workspace</div>
    <nav className="sidebar-nav">{links.filter((link) => link.roles.includes(role)).map(({ label, to, icon: Icon }) => <NavLink key={to} to={to} end={to === '/dashboard'} className={({ isActive }) => `sidebar-link ${isActive ? 'active' : ''}`}><Icon size={17} /><span>{label}</span></NavLink>)}</nav>
    <div className="sidebar-footer"><div className="user-chip"><span className="avatar">{user?.email?.slice(0, 1).toUpperCase() || 'T'}</span><span><strong>{user?.email?.split('@')[0] || 'Traveller'}</strong><small>{role}</small></span></div><button className="icon-button" title="Log out" onClick={logout}><LogOut size={17} /></button></div>
  </aside>
}
