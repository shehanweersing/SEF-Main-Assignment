import { Bell, ChevronDown, Home } from 'lucide-react'
import { Link, Outlet } from 'react-router-dom'
import { motion } from 'framer-motion'
import Sidebar from '../../components/Sidebar'
import { useAuth } from '../../context/AuthContext'
import './dashboard-motion.css'
export default function DashboardLayout() { const { user } = useAuth(); return <div className="app-shell"><Sidebar /><div className="main-shell"><header className="app-header"><div className="mobile-brand">TravelWise</div><div className="header-spacer" /><Link to="/" className="home-link" title="Back to landing page"><Home size={16} /><span>TravelWise home</span></Link><button className="notification"><Bell size={18} /><span /></button><div className="header-user"><span className="avatar">{user?.email?.slice(0, 1).toUpperCase() || 'T'}</span><span>{user?.email?.split('@')[0] || 'Traveller'}</span><ChevronDown size={15} /></div></header><motion.main className="dashboard-main" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: .28, ease: 'easeOut' }}><Outlet /></motion.main></div></div> }
