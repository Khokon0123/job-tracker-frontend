#!/bin/bash
set -e
echo "🚀 Updating frontend for manager view..."

# ─── UserContext ──────────────────────────────────────────────
cat > src/context/UserContext.jsx << 'EOF'
import { createContext, useContext, useState } from 'react';

const UserContext = createContext(null);

export const USERS = [
  { id: null, name: 'My data (Khokon)' },
  { id: '69bf7c39f126973fbfb782ec', name: 'Wasif vai' },
];

export function UserProvider({ children }) {
  const [viewingUser, setViewingUser] = useState(USERS[0]);
  return (
    <UserContext.Provider value={{ viewingUser, setViewingUser }}>
      {children}
    </UserContext.Provider>
  );
}

export const useViewingUser = () => useContext(UserContext);
EOF

# ─── App.jsx ─────────────────────────────────────────────────
cat > src/App.jsx << 'EOF'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import { UserProvider } from './context/UserContext';
import Layout from './components/Layout';
import Login from './pages/Login';
import Calendar from './pages/Calendar';
import Pipeline from './pages/Pipeline';
import Alumni from './pages/Alumni';
import Analytics from './pages/Analytics';

function PrivateRoute({ children }) {
  const { user } = useAuth();
  return user ? <Layout>{children}</Layout> : <Navigate to="/login" replace />;
}

function PublicRoute({ children }) {
  const { user } = useAuth();
  return user ? <Navigate to="/" replace /> : children;
}

export default function App() {
  return (
    <AuthProvider>
      <UserProvider>
        <BrowserRouter>
          <Routes>
            <Route path="/login" element={<PublicRoute><Login /></PublicRoute>} />
            <Route path="/" element={<PrivateRoute><Calendar /></PrivateRoute>} />
            <Route path="/pipeline" element={<PrivateRoute><Pipeline /></PrivateRoute>} />
            <Route path="/alumni" element={<PrivateRoute><Alumni /></PrivateRoute>} />
            <Route path="/analytics" element={<PrivateRoute><Analytics /></PrivateRoute>} />
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
        </BrowserRouter>
      </UserProvider>
    </AuthProvider>
  );
}
EOF

# ─── Layout.jsx ──────────────────────────────────────────────
cat > src/components/Layout.jsx << 'EOF'
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { useViewingUser, USERS } from '../context/UserContext';

const navItems = [
  { to: '/', label: 'Calendar' },
  { to: '/pipeline', label: 'Pipeline' },
  { to: '/alumni', label: 'Alumni' },
  { to: '/analytics', label: 'Analytics' },
];

export default function Layout({ children }) {
  const { user, logout } = useAuth();
  const { viewingUser, setViewingUser } = useViewingUser();
  const navigate = useNavigate();
  const handleLogout = () => { logout(); navigate('/login'); };

  return (
    <div style={{ minHeight: '100vh', background: '#f9f9f8' }}>
      <div style={{ background: '#fff', borderBottom: '0.5px solid #e5e5e5', padding: '0 24px', display: 'flex', alignItems: 'center', gap: 4 }}>
        <span style={{ fontSize: 15, fontWeight: 500, marginRight: 16, color: '#111' }}>Job tracker</span>
        {navItems.map(item => (
          <NavLink key={item.to} to={item.to} end={item.to === '/'}
            style={({ isActive }) => ({
              padding: '14px 14px', fontSize: 13, textDecoration: 'none',
              borderBottom: isActive ? '2px solid #1D9E75' : '2px solid transparent',
              color: isActive ? '#1D9E75' : '#666', fontWeight: isActive ? 500 : 400,
            })}>
            {item.label}
          </NavLink>
        ))}
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 12 }}>
          {user?.role === 'manager' && (
            <select value={viewingUser.id || ''} onChange={e => setViewingUser(USERS.find(u => (u.id || '') === e.target.value))}
              style={{ padding: '5px 10px', fontSize: 12, border: '0.5px solid #ddd', borderRadius: 8, background: '#f5f5f4', color: '#333', cursor: 'pointer' }}>
              {USERS.map(u => <option key={u.id || 'me'} value={u.id || ''}>{u.name}</option>)}
            </select>
          )}
          <span style={{ fontSize: 13, color: '#888' }}>{user?.name} · <span style={{ background: '#E1F5EE', color: '#0F6E56', padding: '2px 8px', borderRadius: 10, fontSize: 11 }}>{user?.role}</span></span>
          <button onClick={handleLogout} style={{ padding: '5px 12px', fontSize: 12, border: '0.5px solid #ddd', borderRadius: 8, background: 'transparent', cursor: 'pointer', color: '#666' }}>Sign out</button>
        </div>
      </div>
      <div style={{ padding: '24px', maxWidth: 1200, margin: '0 auto' }}>{children}</div>
    </div>
  );
}
EOF

# ─── Pipeline.jsx ─────────────────────────────────────────────
cat > src/pages/Pipeline.jsx << 'EOF'
import { useState, useEffect } from 'react';
import api from '../api/client';
import { useViewingUser } from '../context/UserContext';
import { useAuth } from '../context/AuthContext';

const STAGES = ['Applied', 'Awaiting response', 'Interview scheduled', 'Offer received', 'Rejected'];
const COLORS = ['#E6F1FB', '#FAEEDA', '#E1F5EE', '#EAF3DE', '#FCEBEB'];
const TEXT_COLORS = ['#185FA5', '#854F0B', '#0F6E56', '#3B6D11', '#A32D2D'];

export default function Pipeline() {
  const { user } = useAuth();
  const { viewingUser } = useViewingUser();
  const [jobs, setJobs] = useState([]);
  const [addingStage, setAddingStage] = useState(-1);
  const [newJob, setNewJob] = useState({ company: '', role: '' });

  const isManager = user?.role === 'manager';
  const userId = viewingUser?.id;
  const readOnly = isManager && !!userId;

  const fetchJobs = async () => {
    try {
      const params = new URLSearchParams();
      if (isManager && userId) params.append('userId', userId);
      const { data } = await api.get(`/api/jobs?${params}`);
      setJobs(data.jobs);
    } catch {}
  };

  useEffect(() => { fetchJobs(); }, [userId]);

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
    if (readOnly) return;
    const next = (job.stage + 1) % 5;
    if (!window.confirm(`Move "${job.company}" to "${STAGES[next]}"?\nCancel to delete instead.`)) {
      if (window.confirm('Delete this job?')) { await api.delete(`/api/jobs/${job._id}`); fetchJobs(); }
      return;
    }
    await api.patch(`/api/jobs/${job._id}`, { stage: next });
    fetchJobs();
  };

  return (
    <div>
      {readOnly && (
        <div style={{ background: '#E1F5EE', border: '0.5px solid #5DCAA5', borderRadius: 8, padding: '8px 14px', marginBottom: 16, fontSize: 13, color: '#0F6E56' }}>
          Viewing <strong>{viewingUser.name}</strong>'s pipeline — read only
        </div>
      )}
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
                  style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 8, padding: 10, marginBottom: 8, cursor: readOnly ? 'default' : 'pointer' }}>
                  <div style={{ fontSize: 13, fontWeight: 500, color: '#111' }}>{job.company}</div>
                  {job.role && <div style={{ fontSize: 11, color: '#888', marginTop: 2 }}>{job.role}</div>}
                  <div style={{ fontSize: 10, color: '#aaa', marginTop: 6 }}>{job.dateApplied}</div>
                  <span style={{ display: 'inline-block', marginTop: 6, fontSize: 10, padding: '2px 8px', borderRadius: 10, background: COLORS[si], color: TEXT_COLORS[si], fontWeight: 500 }}>{stage}</span>
                </div>
              ))}
              {!readOnly && (
                addingStage === si ? (
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
                )
              )}
            </div>
          );
        })}
      </div>
    </div>
  );
}
EOF

# ─── Alumni.jsx ───────────────────────────────────────────────
cat > src/pages/Alumni.jsx << 'EOF'
import { useState, useEffect } from 'react';
import api from '../api/client';
import { useViewingUser } from '../context/UserContext';
import { useAuth } from '../context/AuthContext';

const STATUS_ORDER = ['pending', 'replied', 'meeting', 'done'];
const STATUS_LABEL = { pending: 'Pending reply', replied: 'Replied', meeting: 'Meeting scheduled', done: 'Done' };
const STATUS_STYLE = {
  pending: { background: '#FAEEDA', color: '#854F0B' },
  replied: { background: '#E1F5EE', color: '#0F6E56' },
  meeting: { background: '#E6F1FB', color: '#185FA5' },
  done: { background: '#EAF3DE', color: '#3B6D11' },
};
const empty = { name: '', company: '', dateContacted: '', status: 'pending', meetingDate: '', notes: '' };

export default function Alumni() {
  const { user } = useAuth();
  const { viewingUser } = useViewingUser();
  const [alumni, setAlumni] = useState([]);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState(empty);
  const [editId, setEditId] = useState(null);

  const isManager = user?.role === 'manager';
  const userId = viewingUser?.id;
  const readOnly = isManager && !!userId;

  const fetchAlumni = async () => {
    try {
      const params = new URLSearchParams();
      if (isManager && userId) params.append('userId', userId);
      const { data } = await api.get(`/api/alumni?${params}`);
      setAlumni(data.alumni);
    } catch {}
  };

  useEffect(() => { fetchAlumni(); }, [userId]);

  const save = async () => {
    if (!form.name.trim()) return;
    try {
      if (editId) await api.patch(`/api/alumni/${editId}`, form);
      else await api.post('/api/alumni', form);
      setModal(false); fetchAlumni();
    } catch {}
  };

  const cycleStatus = async (a) => {
    if (readOnly) return;
    const next = STATUS_ORDER[(STATUS_ORDER.indexOf(a.status) + 1) % STATUS_ORDER.length];
    await api.patch(`/api/alumni/${a._id}`, { status: next });
    fetchAlumni();
  };

  const del = async (id) => {
    if (readOnly) return;
    if (window.confirm('Delete this contact?')) { await api.delete(`/api/alumni/${id}`); fetchAlumni(); }
  };

  return (
    <div>
      {readOnly && (
        <div style={{ background: '#E1F5EE', border: '0.5px solid #5DCAA5', borderRadius: 8, padding: '8px 14px', marginBottom: 16, fontSize: 13, color: '#0F6E56' }}>
          Viewing <strong>{viewingUser.name}</strong>'s alumni — read only
        </div>
      )}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <h2 style={{ fontSize: 16, fontWeight: 500 }}>Alumni network</h2>
        {!readOnly && <button onClick={() => { setForm(empty); setEditId(null); setModal(true); }} style={{ padding: '7px 16px', background: '#1D9E75', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 500, cursor: 'pointer' }}>+ Add contact</button>}
      </div>
      <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 12, overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: '#f9f9f8' }}>
              {['Name','Company','Date contacted','Status','Meeting date','Notes',''].map(h => (
                <th key={h} style={{ textAlign: 'left', fontSize: 11, fontWeight: 500, color: '#888', padding: '10px 14px', borderBottom: '0.5px solid #e5e5e5' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {alumni.length === 0 ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: 40, color: '#aaa', fontSize: 13 }}>No contacts yet</td></tr>
            ) : alumni.map(a => (
              <tr key={a._id} style={{ borderBottom: '0.5px solid #f0f0f0' }}>
                <td style={{ padding: '10px 14px', fontSize: 13, fontWeight: 500 }}>{a.name}</td>
                <td style={{ padding: '10px 14px', fontSize: 13, color: '#555' }}>{a.company}</td>
                <td style={{ padding: '10px 14px', fontSize: 13, color: '#888' }}>{a.dateContacted}</td>
                <td style={{ padding: '10px 14px' }}><span style={{ fontSize: 11, padding: '3px 10px', borderRadius: 10, fontWeight: 500, ...STATUS_STYLE[a.status] }}>{STATUS_LABEL[a.status]}</span></td>
                <td style={{ padding: '10px 14px', fontSize: 13, color: '#888' }}>{a.meetingDate || '—'}</td>
                <td style={{ padding: '10px 14px', fontSize: 12, color: '#aaa', maxWidth: 140, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.notes}</td>
                <td style={{ padding: '10px 14px' }}>
                  {!readOnly && (
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button onClick={() => cycleStatus(a)} style={actionBtn}>Next status</button>
                      <button onClick={() => { setForm(a); setEditId(a._id); setModal(true); }} style={actionBtn}>Edit</button>
                      <button onClick={() => del(a._id)} style={{ ...actionBtn, color: '#c0392b' }}>Delete</button>
                    </div>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      {modal && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.4)', display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 100 }}>
          <div style={{ background: '#fff', borderRadius: 16, padding: 28, width: 380, maxWidth: '90vw' }}>
            <h3 style={{ fontSize: 15, fontWeight: 500, marginBottom: 16 }}>{editId ? 'Edit contact' : 'Add alumni contact'}</h3>
            {[['name','Name','text'],['company','Company','text'],['dateContacted','Date contacted','date'],['meetingDate','Meeting date (optional)','date'],['notes','Notes','text']].map(([key, label, type]) => (
              <div key={key} style={{ marginBottom: 12 }}>
                <label style={{ display: 'block', fontSize: 12, color: '#888', marginBottom: 4 }}>{label}</label>
                <input type={type} value={form[key]} onChange={e => setForm({ ...form, [key]: e.target.value })}
                  style={{ width: '100%', padding: '7px 10px', border: '0.5px solid #ddd', borderRadius: 8, fontSize: 13, boxSizing: 'border-box' }} />
              </div>
            ))}
            <div style={{ marginBottom: 16 }}>
              <label style={{ display: 'block', fontSize: 12, color: '#888', marginBottom: 4 }}>Status</label>
              <select value={form.status} onChange={e => setForm({ ...form, status: e.target.value })}
                style={{ width: '100%', padding: '7px 10px', border: '0.5px solid #ddd', borderRadius: 8, fontSize: 13 }}>
                {STATUS_ORDER.map(s => <option key={s} value={s}>{STATUS_LABEL[s]}</option>)}
              </select>
            </div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button onClick={() => setModal(false)} style={{ flex: 1, padding: 8, borderRadius: 8, fontSize: 13, cursor: 'pointer', border: '0.5px solid #ddd', background: 'transparent', color: '#666' }}>Cancel</button>
              <button onClick={save} style={{ flex: 1, padding: 8, borderRadius: 8, fontSize: 13, cursor: 'pointer', border: 'none', background: '#1D9E75', color: '#fff', fontWeight: 500 }}>Save</button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

const actionBtn = { fontSize: 11, padding: '3px 8px', borderRadius: 6, cursor: 'pointer', border: '0.5px solid #e5e5e5', background: 'transparent', color: '#555' };
EOF

# ─── Analytics.jsx ────────────────────────────────────────────
cat > src/pages/Analytics.jsx << 'EOF'
import { useState, useEffect } from 'react';
import api from '../api/client';
import { useViewingUser } from '../context/UserContext';
import { useAuth } from '../context/AuthContext';

export default function Analytics() {
  const { user } = useAuth();
  const { viewingUser } = useViewingUser();
  const [logs, setLogs] = useState([]);
  const [jobs, setJobs] = useState([]);

  const isManager = user?.role === 'manager';
  const userId = viewingUser?.id;

  useEffect(() => {
    const now = new Date();
    const params = new URLSearchParams({ year: now.getFullYear() });
    if (isManager && userId) params.append('userId', userId);
    const jobParams = new URLSearchParams();
    if (isManager && userId) jobParams.append('userId', userId);
    api.get(`/api/logs?${params}`).then(r => setLogs(r.data.logs)).catch(() => {});
    api.get(`/api/jobs?${jobParams}`).then(r => setJobs(r.data.jobs)).catch(() => {});
  }, [userId]);

  const totals = logs.reduce((a, l) => ({
    apps: a.apps+(l.apps||0), interviews: a.interviews+(l.interviews||0),
    rejections: a.rejections+(l.rejections||0), alumContacted: a.alumContacted+(l.alumContacted||0),
    alumReplied: a.alumReplied+(l.alumReplied||0),
  }), { apps:0, interviews:0, rejections:0, alumContacted:0, alumReplied:0 });

  const offers = jobs.filter(j => j.stage === 3).length;
  const ir = totals.apps > 0 ? Math.round(totals.interviews/totals.apps*100) : 0;
  const rr = totals.apps > 0 ? Math.round(totals.rejections/totals.apps*100) : 0;
  const ar = totals.alumContacted > 0 ? Math.round(totals.alumReplied/totals.alumContacted*100) : 0;

  const funnel = [
    { label: 'Applications', value: totals.apps, color: '#378ADD' },
    { label: 'Interviews', value: totals.interviews, color: '#1D9E75' },
    { label: 'Rejections', value: totals.rejections, color: '#E24B4A' },
    { label: 'Offers', value: offers, color: '#639922' },
  ];
  const maxF = Math.max(...funnel.map(f => f.value), 1);

  const trend = Array(14).fill(null).map((_, i) => {
    const d = new Date(); d.setDate(d.getDate()-(13-i));
    const ds = d.toISOString().split('T')[0];
    const log = logs.find(l => l.date === ds);
    return { label: d.getDate(), value: log?.apps || 0 };
  });
  const maxT = Math.max(...trend.map(t => t.value), 1);

  return (
    <div>
      {isManager && userId && (
        <div style={{ background: '#E1F5EE', border: '0.5px solid #5DCAA5', borderRadius: 8, padding: '8px 14px', marginBottom: 16, fontSize: 13, color: '#0F6E56' }}>
          Viewing <strong>{viewingUser.name}</strong>'s analytics
        </div>
      )}
      <h2 style={{ fontSize: 16, fontWeight: 500, marginBottom: 16 }}>Analytics</h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 12, padding: 20 }}>
          <h3 style={{ fontSize: 13, fontWeight: 500, color: '#888', marginBottom: 16 }}>Funnel breakdown</h3>
          {funnel.map(f => (
            <div key={f.label} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
              <span style={{ fontSize: 12, color: '#888', width: 100, flexShrink: 0, textAlign: 'right' }}>{f.label}</span>
              <div style={{ flex: 1, background: '#f5f5f4', borderRadius: 4, height: 20, overflow: 'hidden' }}>
                <div style={{ height: '100%', borderRadius: 4, background: f.color, width: `${Math.max(4, Math.round(f.value/maxF*100))}%`, display: 'flex', alignItems: 'center', paddingLeft: 8 }}>
                  <span style={{ fontSize: 11, color: '#fff', fontWeight: 500 }}>{f.value}</span>
                </div>
              </div>
            </div>
          ))}
        </div>
        <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 12, padding: 20 }}>
          <h3 style={{ fontSize: 13, fontWeight: 500, color: '#888', marginBottom: 16 }}>Key rates</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            {[{label:'Interview rate',value:ir+'%'},{label:'Rejection rate',value:rr+'%'},{label:'Alumni reply rate',value:ar+'%'},{label:'Active offers',value:offers}].map(r => (
              <div key={r.label} style={{ background: '#f5f5f4', borderRadius: 10, padding: 14, textAlign: 'center' }}>
                <div style={{ fontSize: 26, fontWeight: 500, color: '#111' }}>{r.value}</div>
                <div style={{ fontSize: 11, color: '#888', marginTop: 4 }}>{r.label}</div>
              </div>
            ))}
          </div>
        </div>
        <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 12, padding: 20, gridColumn: '1/-1' }}>
          <h3 style={{ fontSize: 13, fontWeight: 500, color: '#888', marginBottom: 16 }}>Applications per day (last 14 days)</h3>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 4, height: 80 }}>
            {trend.map((t, i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', height: '100%', justifyContent: 'flex-end' }}>
                <div title={`${t.value} apps`} style={{ width: '100%', borderRadius: '3px 3px 0 0', background: '#5DCAA5', height: `${Math.max(2, Math.round(t.value/maxT*64))}px` }} />
              </div>
            ))}
          </div>
          <div style={{ display: 'flex', gap: 4, marginTop: 6 }}>
            {trend.map((t, i) => <div key={i} style={{ flex: 1, fontSize: 9, color: '#aaa', textAlign: 'center' }}>{t.label}</div>)}
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

# ─── Push ─────────────────────────────────────────────────────
git add .
git commit -m "fix all views to show wasif data for manager"
git push

echo ""
echo "✅ Done! Vercel will redeploy in ~1 minute."
echo "Then select 'Wasif vai' from the dropdown to see his data."
echo ""
