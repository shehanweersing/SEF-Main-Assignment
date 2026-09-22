import { AlertTriangle, CheckCircle2, LoaderCircle, ShieldAlert } from 'lucide-react'
import { useEffect, useState } from 'react'
import api from '../../api/axiosInstance'

const statusStyles = {
  HEALTHY: { label: 'Healthy', badge: 'bg-emerald-100 text-emerald-700', dot: 'bg-emerald-500', bar: 'bg-emerald-500', Icon: CheckCircle2 },
  WARNING: { label: 'Warning', badge: 'bg-amber-100 text-amber-800', dot: 'bg-amber-500', bar: 'bg-amber-500', Icon: AlertTriangle },
  CRITICAL: { label: 'Critical', badge: 'bg-red-100 text-red-700', dot: 'bg-red-500', bar: 'bg-red-500', Icon: ShieldAlert },
}

export default function BudgetHealthCard({ tripId, currency = 'USD' }) {
  const [health, setHealth] = useState(null)
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!tripId) return
    let active = true
    setLoading(true)
    api.get(`/Budgets/${tripId}/health`).then(({ data }) => {
      if (active) setHealth(data)
    }).catch((requestError) => {
      if (active) setError(requestError.response?.data || 'Could not load budget health.')
    }).finally(() => {
      if (active) setLoading(false)
    })
    return () => { active = false }
  }, [tripId])

  if (loading) return <section className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm"><div className="flex items-center gap-2 text-sm text-slate-500"><LoaderCircle className="animate-spin" size={17} /> Loading budget health...</div></section>
  if (error) return <section className="rounded-xl border border-red-200 bg-red-50 p-6 text-sm text-red-700" role="alert">{String(error)}</section>
  if (!health) return null

  const status = statusStyles[health.healthStatus] || statusStyles.HEALTHY
  const StatusIcon = status.Icon
  const percentage = Number(health.spendingPercentage) || 0
  const progressWidth = Math.min(Math.max(percentage, 0), 100)
  const money = (value) => new Intl.NumberFormat('en-US', { style: 'currency', currency }).format(Number(value) || 0)

  return <section className="rounded-xl border border-slate-200 bg-white p-6 shadow-sm" aria-label="Budget health"><div className="flex flex-wrap items-start justify-between gap-4"><div><p className="text-xs font-semibold uppercase tracking-[0.14em] text-slate-500">Budget health</p><h2 className="mt-2 text-2xl font-semibold tracking-tight text-slate-900">Your spending pulse</h2></div><div className={`inline-flex items-center gap-2 rounded-full px-3 py-1.5 text-xs font-bold ${status.badge}`}><span className={`h-2 w-2 rounded-full ${status.dot} ${health.healthStatus === 'CRITICAL' ? 'animate-pulse' : ''}`} /><StatusIcon size={14} /> {status.label}</div></div><div className="mt-6"><div className="mb-2 flex items-center justify-between text-sm"><span className="text-slate-500">{money(health.totalSpent)} spent</span><strong className="text-slate-900">{percentage.toFixed(2)}%</strong></div><div className="h-3 overflow-hidden rounded-full bg-slate-100"><div className={`h-full rounded-full transition-[width] duration-500 ${status.bar}`} style={{ width: `${progressWidth}%` }} /></div></div><div className="mt-6 grid grid-cols-1 gap-3 sm:grid-cols-3"><div className="rounded-lg bg-slate-50 p-4"><p className="text-xs text-slate-500">Total budget</p><strong className="mt-1 block text-lg text-slate-900">{money(health.totalBudget)}</strong></div><div className="rounded-lg bg-slate-50 p-4"><p className="text-xs text-slate-500">Total spent</p><strong className="mt-1 block text-lg text-slate-900">{money(health.totalSpent)}</strong></div><div className={`rounded-lg p-4 ${health.remainingBudget < 0 ? 'bg-red-50' : 'bg-slate-50'}`}><p className="text-xs text-slate-500">Remaining balance</p><strong className={`mt-1 block text-lg ${health.remainingBudget < 0 ? 'text-red-700' : 'text-slate-900'}`}>{money(health.remainingBudget)}</strong></div></div></section>
}