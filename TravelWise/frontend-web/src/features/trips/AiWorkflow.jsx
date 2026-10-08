import { useEffect, useState } from 'react';
import { LoaderCircle, CheckCircle, AlertCircle, RefreshCw } from 'lucide-react';
import { useAuth } from '../../context/AuthContext';
import axios from 'axios';

const api = axios.create({
  baseURL: 'http://localhost:5038/api',
  withCredentials: true
});

api.interceptors.request.use((config) => {
    const token = localStorage.getItem('token');
    if (token) {
        config.headers.Authorization = `Bearer ${token}`;
    }
    return config;
});

export default function AiWorkflow({ tripId, onClose }) {
    const { user } = useAuth();
    const [workflow, setWorkflow] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [revisionReason, setRevisionReason] = useState('');

    const loadWorkflow = async () => {
        try {
            // we could check if one exists, but for demo we start a new one or fetch the latest
            // to keep it simple, we'll assume we can start a new one
            setLoading(true);
            const response = await api.post(`/trips/${tripId}/ai-workflows`, { objective: "Plan a great trip" });
            setWorkflow(response.data);
            pollStatus(response.data.workflowId);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const pollStatus = async (id) => {
        const interval = setInterval(async () => {
            try {
                const response = await api.get(`/ai-workflows/${id}/status`);
                setWorkflow(prev => ({ ...prev, status: response.data.status, activeAgent: response.data.activeAgent }));
                
                if (['AWAITING_APPROVAL', 'APPROVED', 'REJECTED', 'COMPLETED', 'VALIDATION_FAILED', 'SAFE_FAILED', 'AGENT_FAILED'].includes(response.data.status)) {
                    clearInterval(interval);
                    fetchFullWorkflow(id);
                }
            } catch (err) {
                console.error(err);
                clearInterval(interval);
            }
        }, 2000);
    };

    const fetchFullWorkflow = async (id) => {
        try {
            const response = await api.get(`/ai-workflows/${id}`);
            setWorkflow(response.data);
        } catch (err) {
            console.error(err);
        }
    };

    const handleAction = async (action) => {
        try {
            if (action === 'approve') {
                await api.post(`/ai-workflows/${workflow.id || workflow.workflowId}/approve`);
            } else if (action === 'reject') {
                await api.post(`/ai-workflows/${workflow.id || workflow.workflowId}/reject`);
            } else if (action === 'revise') {
                await api.post(`/ai-workflows/${workflow.id || workflow.workflowId}/revise`, { reason: revisionReason });
                pollStatus(workflow.id || workflow.workflowId);
            }
            fetchFullWorkflow(workflow.id || workflow.workflowId);
        } catch (err) {
            setError(err.message);
        }
    };

    const isDone = ['AWAITING_APPROVAL', 'APPROVED', 'REJECTED', 'COMPLETED'].includes(workflow?.status);

    return (
        <div className="workflow-overlay">
            <div className="workflow-modal">
                <div className="workflow-header">
                    <h2>Intelligent Trip Plan</h2>
                    <button onClick={onClose} className="button button-dark">Close</button>
                </div>
                
                <div className="workflow-content">
                    {!workflow && !loading && (
                        <button onClick={loadWorkflow} className="button button-coral">Start Intelligent Trip Plan</button>
                    )}
                    
                    {loading && <p><LoaderCircle className="spin" size={16} /> Starting workflow...</p>}
                    {error && <p className="form-error">{error}</p>}

                    {workflow && (
                        <div className="workflow-status">
                            <h3>Status: {workflow.status}</h3>
                            {workflow.activeAgent && <p>Active Agent: {workflow.activeAgent}</p>}
                            
                            <ul className="workflow-steps">
                                <li><CheckCircle size={16} className={workflow.status !== 'CREATED' ? 'done' : ''} /> Group Collaboration</li>
                                <li><CheckCircle size={16} className={['RISK_ANALYSIS', 'BUDGET_ANALYSIS', 'VALIDATING', 'AWAITING_APPROVAL'].includes(workflow.status) ? 'done' : ''} /> Itinerary Planning</li>
                                <li><CheckCircle size={16} className={['BUDGET_ANALYSIS', 'VALIDATING', 'AWAITING_APPROVAL'].includes(workflow.status) ? 'done' : ''} /> Risk Analysis</li>
                                <li><CheckCircle size={16} className={['VALIDATING', 'AWAITING_APPROVAL'].includes(workflow.status) ? 'done' : ''} /> Budget Analysis</li>
                                <li><CheckCircle size={16} className={isDone ? 'done' : ''} /> Cross-Agent Review & Validation</li>
                            </ul>

                            {workflow.status === 'AWAITING_APPROVAL' && (
                                <div className="workflow-actions">
                                    <h4>Workflow Complete! Review required.</h4>
                                    <div className="actions-row">
                                        <button onClick={() => handleAction('approve')} className="button button-coral">Approve</button>
                                        <button onClick={() => handleAction('reject')} className="button button-dark">Reject</button>
                                    </div>
                                    <div className="revise-row">
                                        <input type="text" placeholder="Reason for revision..." value={revisionReason} onChange={e => setRevisionReason(e.target.value)} />
                                        <button onClick={() => handleAction('revise')} className="button button-dark">Request Revision</button>
                                    </div>
                                </div>
                            )}
                        </div>
                    )}
                </div>
            </div>
            
            <style jsx>{`
                .workflow-overlay { position: fixed; top: 0; left: 0; right: 0; bottom: 0; background: rgba(0,0,0,0.5); display: flex; align-items: center; justify-content: center; z-index: 1000; }
                .workflow-modal { background: #fff; padding: 24px; border-radius: 8px; width: 600px; max-width: 90vw; max-height: 90vh; overflow-y: auto; color: #111; }
                .workflow-header { display: flex; justify-content: space-between; align-items: center; margin-bottom: 20px; }
                .workflow-steps { list-style: none; padding: 0; margin: 20px 0; }
                .workflow-steps li { display: flex; align-items: center; gap: 10px; margin-bottom: 10px; }
                .workflow-steps .done { color: green; }
                .actions-row, .revise-row { display: flex; gap: 10px; margin-top: 15px; }
                .revise-row input { flex: 1; padding: 8px; border: 1px solid #ccc; border-radius: 4px; }
            `}</style>
        </div>
    );
}
