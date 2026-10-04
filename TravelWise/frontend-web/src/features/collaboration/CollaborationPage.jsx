import { Check, LoaderCircle, Mail, ShieldCheck, Trash2, UsersRound, Vote } from 'lucide-react'
import { useEffect, useMemo, useState } from 'react'
import { activityApi, collaborationApi, getOrCreateTrip } from '../../api/travelWiseApi'
import { useAuth } from '../../context/AuthContext'

function errorMessage(error, fallback) {
  const data = error.response?.data
  return typeof data === 'string' ? data : data?.detail || data?.title || data?.message || fallback
}

function formatDate(value) {
  return value ? new Intl.DateTimeFormat('en', { month: 'short', day: 'numeric', year: 'numeric' }).format(new Date(value)) : ''
}

export default function CollaborationPage() {
  const { user } = useAuth()
  const [trip, setTrip] = useState(null)
  const [members, setMembers] = useState([])
  const [activities, setActivities] = useState([])
  const [report, setReport] = useState(null)
  const [inviteEmail, setInviteEmail] = useState('')
  const [preference, setPreference] = useState({ category: '', weight: 3, notes: '' })
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState('')
  const [error, setError] = useState('')
  const [message, setMessage] = useState('')

  const currentMember = useMemo(() => members.find((member) => member.userId === user?.id), [members, user?.id])
  const canManage = currentMember?.role === 'Owner' || currentMember?.role === 'Editor'
  const isOwner = currentMember?.role === 'Owner'

  async function load() {
    if (!user?.id) return
    setLoading(true)
    setError('')
    try {
      const selectedTrip = await getOrCreateTrip(user.id)
      setTrip(selectedTrip)
      const [membersResponse, activityResponse] = await Promise.all([
        collaborationApi.listMembers(selectedTrip.id),
        activityApi.list(selectedTrip.id),
      ])
      setMembers(membersResponse.data)
      setActivities(activityResponse.data)
      try {
        const reportResponse = await collaborationApi.getConsensusReport(selectedTrip.id)
        setReport(reportResponse.data)
      } catch (reportError) {
        if (reportError.response?.status !== 404) throw reportError
        setReport(null)
      }
    } catch (requestError) {
      setError(errorMessage(requestError, 'Could not load collaboration details.'))
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => { load() }, [user?.id])

  async function runAction(key, action, success) {
    setBusy(key)
    setError('')
    setMessage('')
    try {
      await action()
      setMessage(success)
      await load()
    } catch (requestError) {
      setError(errorMessage(requestError, 'The request could not be completed.'))
    } finally {
      setBusy('')
    }
  }

  function invite(event) {
    event.preventDefault()
    if (!inviteEmail.trim()) return
    runAction('invite', () => collaborationApi.inviteMember(trip.id, { invitedEmail: inviteEmail.trim() }), 'Invitation created and valid for 7 days.').then(() => setInviteEmail(''))
  }

  function savePreference(event) {
    event.preventDefault()
    if (!preference.category.trim()) return
    runAction('preference', () => collaborationApi.savePreference(trip.id, preference), 'Preference saved.')
  }

  function changeRole(member, role) {
    runAction(`role-${member.userId}`, () => collaborationApi.changeMemberRole(trip.id, member.userId, { role }), 'Member role updated.')
  }

  function removeMember(member) {
    if (!window.confirm(`Remove ${member.fullName || member.email} from this trip?`)) return
    runAction(`remove-${member.userId}`, () => collaborationApi.removeMember(trip.id, member.userId), 'Member removed.')
  }

  function vote(activityId, voteType) {
    runAction(`vote-${activityId}`, () => collaborationApi.vote(trip.id, activityId, { voteType }), 'Vote recorded.')
  }

  if (loading) return <div className="collab-loading"><LoaderCircle className="spin" size={24} /> Loading collaboration workspace...</div>
  if (!trip) return <div className="form-error">{error || 'No trip is available for collaboration.'}</div>

  return <div className="collab-page">
    <div className="page-intro">
      <div><span className="eyebrow">Group travel</span><h1>Plan it together.</h1><p>Invite your group, capture preferences, and turn every voice into a better itinerary.</p></div>
      <div className="collab-trip-chip"><MapPinFallback /> <span>{trip.destination}</span><small>Trip #{trip.id}</small></div>
    </div>
    {error && <div className="form-error">{error}</div>}
    {message && <div className="collab-success"><Check size={15} /> {message}</div>}

    <div className="collab-grid">
      <section className="collab-panel collab-members">
        <div className="collab-panel-heading"><div><span className="eyebrow">The group</span><h2><UsersRound size={19} /> Members <span>{members.length}</span></h2></div><ShieldCheck size={20} /></div>
        {canManage && <form className="collab-inline-form" onSubmit={invite}><label><Mail size={15} /><input type="email" value={inviteEmail} onChange={(event) => setInviteEmail(event.target.value)} placeholder="friend@email.com" required /></label><button className="button button-dark" disabled={busy === 'invite'}>{busy === 'invite' ? 'Sending...' : 'Invite'}</button></form>}
        <div className="member-list">{members.map((member) => <div className="member-row" key={member.userId}><div className="avatar">{(member.fullName || member.email || '?').slice(0, 1).toUpperCase()}</div><div className="member-copy"><strong>{member.fullName || member.email}</strong><small>{member.email || 'Invitation pending'}</small></div><span className={`role-badge role-${member.role.toLowerCase()}`}>{member.role}</span>{isOwner && member.userId !== user?.id && <><select value={member.role} onChange={(event) => changeRole(member, event.target.value)} disabled={busy === `role-${member.userId}`} aria-label={`Change role for ${member.email}`}><option>Viewer</option><option>Editor</option><option>Owner</option></select><button className="icon-button" title="Remove member" onClick={() => removeMember(member)} disabled={busy === `remove-${member.userId}`}><Trash2 size={15} /></button></>}</div>)}</div>
      </section>

      <section className="collab-panel">
        <div className="collab-panel-heading"><div><span className="eyebrow">Your voice</span><h2>Share a preference</h2></div><span className="weight-label">1 — 5</span></div>
        <form className="preference-form" onSubmit={savePreference}><label>Category<input value={preference.category} onChange={(event) => setPreference({ ...preference, category: event.target.value })} placeholder="Nature, Culture, Relaxation..." required /></label><label>Importance<input type="range" min="1" max="5" value={preference.weight} onChange={(event) => setPreference({ ...preference, weight: Number(event.target.value) })} /><strong>{preference.weight}</strong></label><label>Notes<textarea value={preference.notes} onChange={(event) => setPreference({ ...preference, notes: event.target.value })} placeholder="Tell the group what matters to you." maxLength="500" /></label><button className="button button-coral" disabled={busy === 'preference'}>{busy === 'preference' ? 'Saving...' : 'Save preference'}</button></form>
      </section>
    </div>

    <section className="collab-panel voting-panel">
      <div className="collab-panel-heading"><div><span className="eyebrow">Decision room</span><h2><Vote size={19} /> Vote on activities</h2></div><span className="collab-muted">One vote per activity</span></div>
      {activities.length ? <div className="activity-vote-list">{activities.map((activity) => <div className="activity-vote-row" key={activity.id}><div><strong>{activity.title}</strong><small>{activity.interestType || 'Activity'} · {formatDate(activity.startTime)} · {activity.location}</small></div><div className="vote-actions"><button className="vote-button upvote" onClick={() => vote(activity.id, 'Upvote')} disabled={busy === `vote-${activity.id}`}>Upvote</button><button className="vote-button downvote" onClick={() => vote(activity.id, 'Downvote')} disabled={busy === `vote-${activity.id}`}>Downvote</button></div></div>)}</div> : <p className="collab-muted">Add activities to this trip before asking the group to vote.</p>}
    </section>

    <section className="collab-panel consensus-panel">
      <div className="collab-panel-heading"><div><span className="eyebrow">Consensus agent</span><h2>Fairness &amp; satisfaction</h2></div>{canManage && <button className="button button-dark" onClick={() => runAction('consensus', () => collaborationApi.resolveConsensus(trip.id), 'Consensus report refreshed.')} disabled={busy === 'consensus'}>{busy === 'consensus' ? 'Resolving...' : 'Resolve consensus'}</button>}</div>
      {report ? <><div className="consensus-metrics"><div><strong>{report.fairnessScore.toFixed(0)}%</strong><span>Fairness score</span></div><div><strong>{report.participationCount}/{report.requiredParticipation}</strong><span>Participation</span></div><div><strong>{report.requiresArbitration ? 'Review' : 'Clear'}</strong><span>Decision status</span></div></div><div className="decision-list">{report.decisions.map((decision) => <div className="decision-row" key={decision.activityId}><span>{decision.title}</span><span>{decision.upvotes} up · {decision.downvotes} down</span><strong className={decision.requiresArbitration ? 'decision-arbitration' : ''}>{decision.requiresArbitration ? 'Human arbitration' : decision.outcome}</strong></div>)}</div></> : <p className="collab-muted">Resolve consensus after at least 60% of members have voted.</p>}
    </section>
  </div>
}

function MapPinFallback() {
  return <span className="collab-trip-dot" aria-hidden="true" />
}
