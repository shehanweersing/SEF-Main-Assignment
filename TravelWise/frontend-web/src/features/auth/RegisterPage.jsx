import { ArrowLeft, ArrowRight, LockKeyhole, Mail, UserRound } from 'lucide-react'
import { useForm } from 'react-hook-form'
import { Link, useNavigate } from 'react-router-dom'
import { useState } from 'react'
import { authApi } from '../../api/travelWiseApi'

export default function RegisterPage() {
  const { register, handleSubmit, formState: { errors } } = useForm()
  const navigate = useNavigate()
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  async function onSubmit(values) {
    setError('')
    setSuccess('')
    try {
      await authApi.register({ fullName: values.fullName, email: values.email, password: values.password, role: 'Traveller' })
      setSuccess('Your account is ready. You can sign in now.')
      setTimeout(() => navigate('/login'), 900)
    } catch (requestError) {
      setError(requestError.response?.data?.message || requestError.response?.data || 'We could not create your account.')
    }
  }

  return <div className="auth-page"><div className="auth-visual"><Link to="/" className="brand brand-light"><span className="brand-mark">TW</span><span>TravelWise</span></Link><div><span className="eyebrow eyebrow-light">Make space for the good parts</span><h1>Plan less.<br /><em>Experience more.</em></h1></div><span className="auth-visual-caption">A thoughtful way to get there.</span></div><div className="auth-form-wrap"><Link to="/" className="back-link"><ArrowLeft size={16} /> Back home</Link><div className="auth-form"><span className="eyebrow">New here?</span><h2>Create your travel space.</h2><p>Bring every moving part of your next trip together.</p><form onSubmit={handleSubmit(onSubmit)}><label>Full name<span className="input-wrap"><UserRound size={17} /><input placeholder="Your name" {...register('fullName', { required: 'Name is required' })} /></span>{errors.fullName && <small className="field-error">{errors.fullName.message}</small>}</label><label>Email address<span className="input-wrap"><Mail size={17} /><input type="email" placeholder="you@example.com" {...register('email', { required: 'Email is required' })} /></span>{errors.email && <small className="field-error">{errors.email.message}</small>}</label><label>Password<span className="input-wrap"><LockKeyhole size={17} /><input type="password" placeholder="At least 6 characters" {...register('password', { required: 'Password is required', minLength: { value: 6, message: 'Use at least 6 characters' } })} /></span>{errors.password && <small className="field-error">{errors.password.message}</small>}</label>{error && <div className="form-error">{String(error)}</div>}{success && <div className="form-success">{success}</div>}<button className="button button-dark full-button" type="submit">Create account <ArrowRight size={16} /></button></form><small className="auth-note">By continuing, you agree to travel thoughtfully.</small></div></div></div>
}
