import { ArrowUpRight, MessageCircle } from 'lucide-react'
import { Link } from 'react-router-dom'
export default function PlanningCTA() {
     return <section className="planning-cta" id="why"><div><span className="eyebrow eyebrow-light">A little help goes a long way</span><h2>Your next chapter<br />starts with a plan.</h2><p>Have a question? Our travel people are only a message away.</p><Link to="/login" className="button button-light">Get started <ArrowUpRight size={16} /></Link></div><div className="cta-contact"><MessageCircle size={22} /><span>Talk to a travel person<br /><a href="mailto:my3.funk@gmail.com">
    <strong>my3.funk@gmail.com</strong>
</a></span></div></section> }
