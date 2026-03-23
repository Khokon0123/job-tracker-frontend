import { useState, useEffect } from 'react';
import api from '../api/client';

const STAGES = ['Applied', 'Awaiting response', 'Interview scheduled', 'Offer received', 'Rejected'];
const COLORS = ['#E6F1FB', '#FAEEDA', '#E1F5EE', '#EAF3DE', '#FCEBEB'];
const TEXT_COLORS = ['#185FA5', '#854F0B', '#0F6E56', '#3B6D11', '#A32D2D'];

export default function Pipeline() {
  const [jobs, setJobs] = useState([]);
  const [addingStage, setAddingStage] = useState(-1);
  const [newJob, setNewJob] = useState({ company: '', role: '' });

  const fetchJobs = async () => {
    try { const { data } = await api.get('/api/jobs'); setJobs(data.jobs); } catch {}
  };

  useEffect(() => { fetchJobs(); }, []);

  const addJob = async (stage) => {
    if (!newJob.company.trim()) return;
    try {
      await api.post('/api/jobs', { ...newJob, stage, dateApplied: new Date().toISOString().split('T')[0] });
      setNewJob({ company: '', role: '' });
      setAddingStage(-1);
      fetchJobs();
    } catch {}
  };

  const moveJob = async (job) => {
    const next = (job.stage + 1) % 5;
    if (!window.confirm(`Move "${job.company}" to "${STAGES[next]}"?\nCancel to delete instead.`)) {
      if (window.confirm('Delete this job?')) {
        await api.delete(`/api/jobs/${job._id}`);
        fetchJobs();
      }
      return;
    }
    await api.patch(`/api/jobs/${job._id}`, { stage: next });
    fetchJobs();
  };

  return (
    <div>
      <h2 style={{ fontSize: 16, fontWeight: 500, marginBottom: 16 }}>Pipeline</h2>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(5,1fr)', gap: 10, alignItems: 'start' }}>
        {STAGES.map((stage, si) => {
          const stageJobs = jobs.filter(j => j.stage === si);
          return (
            <div key={si} style={{ background: '#f5f5f4', borderRadius: 12, padding: 10 }}>
              <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 10 }}>
                <span style={{ fontSize: 12, fontWeight: 500, color: '#666' }}>{stage}</span>
                <span style={{ fontSize: 11, background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 10, padding: '1px 7px', color: '#888' }}>{stageJobs.length}</span>
              </div>
              {stageJobs.map(job => (
                <div key={job._id} onClick={() => moveJob(job)}
                  style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 8, padding: 10, marginBottom: 8, cursor: 'pointer' }}>
                  <div style={{ fontSize: 13, fontWeight: 500, color: '#111' }}>{job.company}</div>
                  {job.role && <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>{job.role}</div>}
                  <div style={{ fontSize: 10, color: '#aaa', marginTop: 6 }}>{job.dateApplied}</div>
                  <span style={{ display: 'inline-block', marginTop: 6, fontSize: 10, padding: '2px 8px', borderRadius: 10, background: COLORS[si], color: TEXT_COLORS[si], fontWeight: 500 }}>{stage}</span>
                </div>
              ))}
              {addingStage === si ? (
                <div style={{ background: '#fff', border: '0.5px solid #ddd', borderRadius: 8, padding: 10, marginTop: 4 }}>
                  <input placeholder="Company" value={newJob.company} onChange={e => setNewJob({ ...newJob, company: e.target.value })}
                    style={{ width: '100%', padding: '5px 8px', border: '0.5px solid #ddd', borderRadius: 6, fontSize: 12, marginBottom: 6, boxSizing: 'border-box' }} autoFocus />
                  <input placeholder="Role" value={newJob.role} onChange={e => setNewJob({ ...newJob, role: e.target.value })}
                    style={{ width: '100%', padding: '5px 8px', border: '0.5px solid #ddd', borderRadius: 6, fontSize: 12, marginBottom: 8, boxSizing: 'border-box' }} />
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button onClick={() => { setAddingStage(-1); setNewJob({ company: '', role: '' }); }}
                      style={{ flex: 1, padding: '5px', borderRadius: 6, fontSize: 12, cursor: 'pointer', border: '0.5px solid #ddd', background: 'transparent', color: '#888' }}>Cancel</button>
                    <button onClick={() => addJob(si)}
                      style={{ flex: 1, padding: '5px', borderRadius: 6, fontSize: 12, cursor: 'pointer', border: 'none', background: '#1D9E75', color: '#fff' }}>Add</button>
                  </div>
                </div>
              ) : (
                <button onClick={() => setAddingStage(si)}
                  style={{ width: '100%', padding: '6px', border: '0.5px dashed #ccc', borderRadius: 8, background: 'transparent', fontSize: 12, color: '#aaa', cursor: 'pointer', marginTop: 4 }}>+ Add</button>
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
