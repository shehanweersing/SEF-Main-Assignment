import { Bell, ChevronDown, Home } from 'lucide-react'
import { Link, Outlet } from 'react-router-dom'
import { motion } from 'framer-motion'
import Sidebar from '../../components/Sidebar'
import { useAuth } from '../../context/AuthContext'
import { notificationApi } from '../../api/travelWiseApi'
import { useEffect, useState } from 'react'
import './dashboard-motion.css'
export default function DashboardLayout() {
  const { user } = useAuth()
  const [notifications, setNotifications] = useState([])
  const [open, setOpen] = useState(false)
  const [error, setError] = useState('')
  useEffect(() => { if (user?.id) notificationApi.list().then(({ data }) => setNotifications(data)).catch(() => {}) }, [user?.id])
  async function respond(notification, action) {
    setError('')
    try {
      await action(notification.id)
      setNotifications((current) => current.filter((item) => item.id !== notification.id))
    } catch (requestError) {
      setError(requestError.response?.data || 'Could not update this invitation.')
    }
  }
  const pendingCount = notifications.filter((item) => !item.isRead).length
  return <div className="app-shell"><Sidebar /><div className="main-shell"><header className="app-header"><div className="mobile-brand">TravelWise</div><div className="header-spacer" /><Link to="/" className="home-link" title="Back to landing page"><Home size={16} /><span>TravelWise home</span></Link><div className="notification-wrap"><button className="notification" onClick={() => setOpen((value) => !value)} aria-label="Notifications"><Bell size={18} />{pendingCount > 0 && <span className="notification-count">{pendingCount}</span>}</button>{open && <div className="notification-menu"><strong>Notifications</strong>{error && <small className="notification-error">{String(error)}</small>}{notifications.length === 0 ? <p>No new notifications.</p> : notifications.map((notification) => <div className="notification-item" key={notification.id}><p>{notification.message}</p><small>{new Date(notification.createdAt).toLocaleString()}</small><div><button className="button button-coral" onClick={() => respond(notification, notificationApi.acceptInvitation)}>Accept</button><button className="button button-light" onClick={() => respond(notification, notificationApi.leaveInvitation)}>Leave</button></div></div>)}</div>}</div><div className="header-user"><span className="avatar">{user?.email?.slice(0, 1).toUpperCase() || 'T'}</span><span>{user?.email?.split('@')[0] || 'Traveller'}</span><ChevronDown size={15} /></div></header><motion.main className="dashboard-main" initial={{ opacity: 0, y: 10 }} animate={{ opacity: 1, y: 0 }} transition={{ duration: .28, ease: 'easeOut' }}><Outlet /></motion.main></div></div>
}
