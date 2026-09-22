import { ArrowUpRight, Menu } from 'lucide-react'
import { Link } from 'react-router-dom'

export default function LandingHeader() { return <header className="landing-header"><Link to="/" className="brand"><span className="brand-mark">TW</span><span>TravelWise</span></Link><nav className="landing-nav"><a href="#explore">Explore</a><a href="#plans">Plans</a><a href="#why">Why TravelWise</a></nav><div className="header-actions"><Link to="/login" className="text-link">Log in</Link><Link to="/login" className="button button-dark">Sign up <ArrowUpRight size={16} /></Link></div><button className="mobile-menu"><Menu size={20} /></button></header> }
