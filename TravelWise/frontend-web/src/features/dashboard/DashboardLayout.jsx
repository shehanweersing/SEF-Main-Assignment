import { Bell, ChevronDown } from 'lucide-react'
import { Outlet } from 'react-router-dom'
import Sidebar from '../../components/Sidebar'
import { useAuth } from '../../context/AuthContext'
export default function DashboardLayout() { const { user } = useAuth(); return <div className="app-shell"><Sidebar /><div className="main-shell"><header className="app-header"><div className="mobile-brand">TravelWise</div><div className="header-spacer" /><button className="notification"><Bell size={18} /><span /></button><div className="header-user"><span className="avatar">{user?.email?.slice(0, 1).toUpperCase() || 'T'}</span><span>{user?.email?.split('@')[0] || 'Traveller'}</span><ChevronDown size={15} /></div></header><main className="dashboard-main"><Outlet /></main></div></div> }
