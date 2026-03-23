#!/bin/bash
set -e

echo "🚀 Setting up job-tracker-frontend..."

# Create .env file
cat > .env << 'EOF'
VITE_API_URL=https://job-tracker-production-fb50.up.railway.app
EOF

# Create src folder structure
mkdir -p src/api src/components src/pages src/context

# ─── src/api/client.js ───────────────────────────────────────
cat > src/api/client.js << 'EOF'
import axios from 'axios';

const api = axios.create({
  baseURL: import.meta.env.VITE_API_URL,
});

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

api.interceptors.response.use(
  (res) => res,
  (err) => {
    if (err.response?.status === 401) {
      localStorage.removeItem('token');
      localStorage.removeItem('user');
      window.location.href = '/login';
    }
    return Promise.reject(err);
  }
);

export default api;
EOF

# ─── src/context/AuthContext.jsx ─────────────────────────────
cat > src/context/AuthContext.jsx << 'EOF'
import { createContext, useContext, useState, useEffect } from 'react';
import api from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(() => {
    const u = localStorage.getItem('user');
    return u ? JSON.parse(u) : null;
  });
  const [loading, setLoading] = useState(false);

  const login = async (email, password) => {
    const { data } = await api.post('/api/auth/login', { email, password });
    localStorage.setItem('token', data.token);
    localStorage.setItem('user', JSON.stringify(data.user));
    setUser(data.user);
    return data.user;
  };

  const logout = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('user');
    setUser(null);
  };

  return (
    <AuthContext.Provider value={{ user, login, logout, loading }}>
      {children}
    </AuthContext.Provider>
  );
}

export const useAuth = () => useContext(AuthContext);
EOF

# ─── src/pages/Login.jsx ─────────────────────────────────────
cat > src/pages/Login.jsx << 'EOF'
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function Login() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const [form, setForm] = useState({ email: '', password: '' });
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      await login(form.email, form.password);
      navigate('/');
    } catch (err) {
      setError(err.response?.data?.error || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{ minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center', background: '#f9f9f8' }}>
      <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 16, padding: '40px 36px', width: 360, maxWidth: '90vw' }}>
        <h1 style={{ fontSize: 22, fontWeight: 500, marginBottom: 6 }}>Job tracker</h1>
        <p style={{ fontSize: 14, color: '#888', marginBottom: 28 }}>Sign in to your account</p>
        {error && <div style={{ background: '#fff0f0', color: '#c0392b', padding: '10px 14px', borderRadius: 8, fontSize: 13, marginBottom: 16 }}>{error}</div>}
        <form onSubmit={handleSubmit}>
          <label style={{ display: 'block', fontSize: 12, color: '#888', marginBottom: 4 }}>Email</label>
          <input
            type="email" required value={form.email}
            onChange={e => setForm({ ...form, email: e.target.value })}
            style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #ddd', borderRadius: 8, fontSize: 14, marginBottom: 14, boxSizing: 'border-box' }}
            placeholder="you@email.com"
          />
          <label style={{ display: 'block', fontSize: 12, color: '#888', marginBottom: 4 }}>Password</label>
          <input
            type="password" required value={form.password}
            onChange={e => setForm({ ...form, password: e.target.value })}
            style={{ width: '100%', padding: '8px 12px', border: '0.5px solid #ddd', borderRadius: 8, fontSize: 14, marginBottom: 24, boxSizing: 'border-box' }}
            placeholder="••••••••"
          />
          <button type="submit" disabled={loading}
            style={{ width: '100%', padding: '10px', background: '#1D9E75', color: '#fff', border: 'none', borderRadius: 8, fontSize: 14, fontWeight: 500, cursor: loading ? 'not-allowed' : 'pointer', opacity: loading ? 0.7 : 1 }}>
            {loading ? 'Signing in...' : 'Sign in'}
          </button>
        </form>
      </div>
    </div>
  );
}
EOF

# ─── src/components/Layout.jsx ───────────────────────────────
cat > src/components/Layout.jsx << 'EOF'
import { NavLink, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

const navItems = [
  { to: '/', label: 'Calendar' },
  { to: '/pipeline', label: 'Pipeline' },
  { to: '/alumni', label: 'Alumni' },
  { to: '/analytics', label: 'Analytics' },
];

export default function Layout({ children }) {
  const { user, logout } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => { logout(); navigate('/login'); };

  return (
    <div style={{ minHeight: '100vh', background: '#f9f9f8' }}>
      <div style={{ background: '#fff', borderBottom: '0.5px solid #e5e5e5', padding: '0 24px', display: 'flex', alignItems: 'center', gap: 4 }}>
        <span style={{ fontSize: 15, fontWeight: 500, marginRight: 16, color: '#111' }}>Job tracker</span>
        {navItems.map(item => (
          <NavLink key={item.to} to={item.to} end={item.to === '/'}
            style={({ isActive }) => ({
              padding: '14px 14px', fontSize: 13, textDecoration: 'none', borderBottom: isActive ? '2px solid #1D9E75' : '2px solid transparent',
              color: isActive ? '#1D9E75' : '#666', fontWeight: isActive ? 500 : 400,
            })}>
            {item.label}
          </NavLink>
        ))}
        <div style={{ marginLeft: 'auto', display: 'flex', alignItems: 'center', gap: 12 }}>
          <span style={{ fontSize: 13, color: '#888' }}>{user?.name} · <span style={{ background: '#E1F5EE', color: '#0F6E56', padding: '2px 8px', borderRadius: 10, fontSize: 11 }}>{user?.role}</span></span>
          <button onClick={handleLogout} style={{ padding: '5px 12px', fontSize: 12, border: '0.5px solid #ddd', borderRadius: 8, background: 'transparent', cursor: 'pointer', color: '#666' }}>Sign out</button>
        </div>
      </div>
      <div style={{ padding: '24px', maxWidth: 1200, margin: '0 auto' }}>
        {children}
      </div>
    </div>
  );
}
EOF

# ─── src/pages/Calendar.jsx ──────────────────────────────────
cat > src/pages/Calendar.jsx << 'EOF'
import { useState, useEffect, useCallback } from 'react';
import api from '../api/client';

const MONTHS = ['January','February','March','April','May','June','July','August','September','October','November','December'];
const today = () => new Date().toISOString().split('T')[0];
const fmt = (y, m, d) => `${y}-${String(m+1).padStart(2,'0')}-${String(d).padStart(2,'0')}`;

export default function Calendar() {
  const [year, setYear] = useState(new Date().getFullYear());
  const [month, setMonth] = useState(new Date().getMonth());
  const [logs, setLogs] = useState({});
  const [selected, setSelected] = useState(today());
  const [form, setForm] = useState({ apps:0, rejections:0, interviews:0, alumContacted:0, alumReplied:0, alumMeetings:0, notes:'' });
  const [saving, setSaving] = useState(false);
  const [saved, setSaved] = useState(false);

  const fetchLogs = useCallback(async () => {
    try {
      const { data } = await api.get(`/api/logs?year=${year}&month=${month+1}`);
      const map = {};
      data.logs.forEach(l => { map[l.date] = l; });
      setLogs(map);
    } catch {}
  }, [year, month]);

  useEffect(() => { fetchLogs(); }, [fetchLogs]);

  useEffect(() => {
    const log = logs[selected];
    if (log) setForm({ apps: log.apps||0, rejections: log.rejections||0, interviews: log.interviews||0, alumContacted: log.alumContacted||0, alumReplied: log.alumReplied||0, alumMeetings: log.alumMeetings||0, notes: log.notes||'' });
    else setForm({ apps:0, rejections:0, interviews:0, alumContacted:0, alumReplied:0, alumMeetings:0, notes:'' });
  }, [selected, logs]);

  const changeMonth = (d) => {
    let m = month + d, y = year;
    if (m > 11) { m = 0; y++; }
    if (m < 0) { m = 11; y--; }
    setMonth(m); setYear(y);
  };

  const saveLog = async () => {
    setSaving(true);
    try {
      await api.put(`/api/logs/${selected}`, form);
      await fetchLogs();
      setSaved(true);
      setTimeout(() => setSaved(false), 2000);
    } catch {} finally { setSaving(false); }
  };

  const first = new Date(year, month, 1);
  const last = new Date(year, month+1, 0);
  const todayStr = today();

  // month totals
  const totals = Object.values(logs).reduce((a, l) => ({
    apps: a.apps + (l.apps||0), interviews: a.interviews + (l.interviews||0),
    rejections: a.rejections + (l.rejections||0), alum: a.alum + (l.alumContacted||0)
  }), { apps:0, interviews:0, rejections:0, alum:0 });

  const statCards = [
    { label: 'Applications', value: totals.apps, color: '#378ADD' },
    { label: 'Interviews', value: totals.interviews, color: '#1D9E75' },
    { label: 'Rejections', value: totals.rejections, color: '#E24B4A' },
    { label: 'Alumni contacted', value: totals.alum, color: '#EF9F27' },
  ];

  const fields = [
    { key: 'apps', label: 'Applications sent' },
    { key: 'rejections', label: 'Rejections received' },
    { key: 'interviews', label: 'Interview calls' },
    { key: 'alumContacted', label: 'Alumni emailed' },
    { key: 'alumReplied', label: 'Alumni replied' },
    { key: 'alumMeetings', label: 'Alumni meetings' },
  ];

  return (
    <div>
      {/* Stats */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4,1fr)', gap: 10, marginBottom: 20 }}>
        {statCards.map(s => (
          <div key={s.label} style={{ background: '#f5f5f4', borderRadius: 10, padding: '12px 14px' }}>
            <div style={{ fontSize: 11, color: '#888', marginBottom: 4 }}>{s.label}</div>
            <div style={{ fontSize: 24, fontWeight: 500, color: s.color }}>{s.value}</div>
            <div style={{ fontSize: 11, color: '#aaa' }}>this month</div>
          </div>
        ))}
      </div>

      {/* Calendar header */}
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 14 }}>
        <h2 style={{ fontSize: 16, fontWeight: 500 }}>{MONTHS[month]} {year}</h2>
        <div style={{ display: 'flex', gap: 8 }}>
          <button onClick={() => changeMonth(-1)} style={navBtn}>←</button>
          <button onClick={() => { setYear(new Date().getFullYear()); setMonth(new Date().getMonth()); setSelected(todayStr); }} style={navBtn}>Today</button>
          <button onClick={() => changeMonth(1)} style={navBtn}>→</button>
        </div>
      </div>

      {/* Calendar grid */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(7,1fr)', gap: 4, marginBottom: 20 }}>
        {['Su','Mo','Tu','We','Th','Fr','Sa'].map(d => (
          <div key={d} style={{ textAlign: 'center', fontSize: 11, color: '#aaa', padding: '4px 0', fontWeight: 500 }}>{d}</div>
        ))}
        {Array(first.getDay()).fill(null).map((_, i) => <div key={`e${i}`} />)}
        {Array(last.getDate()).fill(null).map((_, i) => {
          const d = i + 1;
          const ds = fmt(year, month, d);
          const log = logs[ds];
          const isToday = ds === todayStr;
          const isSel = ds === selected;
          const hasData = log && (log.apps || log.interviews || log.rejections || log.alumContacted);
          return (
            <div key={d} onClick={() => setSelected(ds)}
              style={{ minHeight: 60, border: isSel ? '1.5px solid #1D9E75' : isToday ? '1.5px solid #5DCAA5' : '0.5px solid #e5e5e5',
                borderRadius: 8, padding: 6, cursor: 'pointer', background: isSel ? '#E1F5EE' : hasData ? '#f9f9f8' : '#fff',
                transition: 'all .1s' }}>
              <div style={{ fontSize: 12, fontWeight: 500, color: isToday ? '#1D9E75' : '#333' }}>{d}</div>
              {hasData && (
                <div style={{ display: 'flex', gap: 2, marginTop: 4, flexWrap: 'wrap' }}>
                  {log.apps > 0 && <div style={{ width: 5, height: 5, borderRadius: '50%', background: '#378ADD' }} />}
                  {log.interviews > 0 && <div style={{ width: 5, height: 5, borderRadius: '50%', background: '#1D9E75' }} />}
                  {log.rejections > 0 && <div style={{ width: 5, height: 5, borderRadius: '50%', background: '#E24B4A' }} />}
                  {log.alumContacted > 0 && <div style={{ width: 5, height: 5, borderRadius: '50%', background: '#EF9F27' }} />}
                </div>
              )}
            </div>
          );
        })}
      </div>

      {/* Log form */}
      {selected && (
        <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 12, padding: 20 }}>
          <h3 style={{ fontSize: 14, fontWeight: 500, marginBottom: 16 }}>
            {selected === todayStr ? 'Today' : selected}: daily log
          </h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            {fields.map(f => (
              <div key={f.key}>
                <label style={{ display: 'block', fontSize: 12, color: '#888', marginBottom: 4 }}>{f.label}</label>
                <input type="number" min="0" value={form[f.key]}
                  onChange={e => setForm({ ...form, [f.key]: parseInt(e.target.value) || 0 })}
                  style={{ width: '100%', padding: '7px 10px', border: '0.5px solid #ddd', borderRadius: 8, fontSize: 14, boxSizing: 'border-box' }} />
              </div>
            ))}
            <div style={{ gridColumn: '1/-1' }}>
              <label style={{ display: 'block', fontSize: 12, color: '#888', marginBottom: 4 }}>Notes</label>
              <textarea value={form.notes} onChange={e => setForm({ ...form, notes: e.target.value })}
                placeholder="Anything noteworthy today..."
                style={{ width: '100%', padding: '7px 10px', border: '0.5px solid #ddd', borderRadius: 8, fontSize: 13, minHeight: 70, resize: 'vertical', boxSizing: 'border-box' }} />
            </div>
          </div>
          <button onClick={saveLog} disabled={saving}
            style={{ marginTop: 14, padding: '8px 20px', background: '#1D9E75', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 500, cursor: 'pointer' }}>
            {saving ? 'Saving...' : saved ? '✓ Saved!' : 'Save log'}
          </button>
        </div>
      )}
    </div>
  );
}

const navBtn = { padding: '5px 12px', border: '0.5px solid #ddd', borderRadius: 8, background: '#fff', cursor: 'pointer', fontSize: 13 };
EOF

# ─── src/pages/Pipeline.jsx ──────────────────────────────────
cat > src/pages/Pipeline.jsx << 'EOF'
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
EOF

# ─── src/pages/Alumni.jsx ────────────────────────────────────
cat > src/pages/Alumni.jsx << 'EOF'
import { useState, useEffect } from 'react';
import api from '../api/client';

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
  const [alumni, setAlumni] = useState([]);
  const [modal, setModal] = useState(false);
  const [form, setForm] = useState(empty);
  const [editId, setEditId] = useState(null);

  const fetchAlumni = async () => {
    try { const { data } = await api.get('/api/alumni'); setAlumni(data.alumni); } catch {}
  };

  useEffect(() => { fetchAlumni(); }, []);

  const openAdd = () => { setForm(empty); setEditId(null); setModal(true); };
  const openEdit = (a) => { setForm(a); setEditId(a._id); setModal(true); };

  const save = async () => {
    if (!form.name.trim()) return;
    try {
      if (editId) await api.patch(`/api/alumni/${editId}`, form);
      else await api.post('/api/alumni', form);
      setModal(false); fetchAlumni();
    } catch {}
  };

  const cycleStatus = async (a) => {
    const next = STATUS_ORDER[(STATUS_ORDER.indexOf(a.status) + 1) % STATUS_ORDER.length];
    await api.patch(`/api/alumni/${a._id}`, { status: next });
    fetchAlumni();
  };

  const del = async (id) => {
    if (window.confirm('Delete this contact?')) { await api.delete(`/api/alumni/${id}`); fetchAlumni(); }
  };

  return (
    <div>
      <div style={{ display: 'flex', alignItems: 'center', justifyContent: 'space-between', marginBottom: 16 }}>
        <h2 style={{ fontSize: 16, fontWeight: 500 }}>Alumni network</h2>
        <button onClick={openAdd} style={{ padding: '7px 16px', background: '#1D9E75', color: '#fff', border: 'none', borderRadius: 8, fontSize: 13, fontWeight: 500, cursor: 'pointer' }}>+ Add contact</button>
      </div>

      <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 12, overflow: 'hidden' }}>
        <table style={{ width: '100%', borderCollapse: 'collapse' }}>
          <thead>
            <tr style={{ background: '#f9f9f8' }}>
              {['Name', 'Company', 'Date contacted', 'Status', 'Meeting date', 'Notes', ''].map(h => (
                <th key={h} style={{ textAlign: 'left', fontSize: 11, fontWeight: 500, color: '#888', padding: '10px 14px', borderBottom: '0.5px solid #e5e5e5' }}>{h}</th>
              ))}
            </tr>
          </thead>
          <tbody>
            {alumni.length === 0 ? (
              <tr><td colSpan={7} style={{ textAlign: 'center', padding: 40, color: '#aaa', fontSize: 13 }}>No contacts yet — add your first alumni contact</td></tr>
            ) : alumni.map(a => (
              <tr key={a._id} style={{ borderBottom: '0.5px solid #f0f0f0' }}>
                <td style={{ padding: '10px 14px', fontSize: 13, fontWeight: 500 }}>{a.name}</td>
                <td style={{ padding: '10px 14px', fontSize: 13, color: '#555' }}>{a.company}</td>
                <td style={{ padding: '10px 14px', fontSize: 13, color: '#888' }}>{a.dateContacted}</td>
                <td style={{ padding: '10px 14px' }}>
                  <span style={{ fontSize: 11, padding: '3px 10px', borderRadius: 10, fontWeight: 500, ...STATUS_STYLE[a.status] }}>{STATUS_LABEL[a.status]}</span>
                </td>
                <td style={{ padding: '10px 14px', fontSize: 13, color: '#888' }}>{a.meetingDate || '—'}</td>
                <td style={{ padding: '10px 14px', fontSize: 12, color: '#aaa', maxWidth: 140, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.notes}</td>
                <td style={{ padding: '10px 14px' }}>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button onClick={() => cycleStatus(a)} style={actionBtn}>Next status</button>
                    <button onClick={() => openEdit(a)} style={actionBtn}>Edit</button>
                    <button onClick={() => del(a._id)} style={{ ...actionBtn, color: '#c0392b' }}>Delete</button>
                  </div>
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

# ─── src/pages/Analytics.jsx ─────────────────────────────────
cat > src/pages/Analytics.jsx << 'EOF'
import { useState, useEffect } from 'react';
import api from '../api/client';

export default function Analytics() {
  const [logs, setLogs] = useState([]);
  const [jobs, setJobs] = useState([]);

  useEffect(() => {
    const now = new Date();
    api.get(`/api/logs?year=${now.getFullYear()}`).then(r => setLogs(r.data.logs)).catch(() => {});
    api.get('/api/jobs').then(r => setJobs(r.data.jobs)).catch(() => {});
  }, []);

  const totals = logs.reduce((a, l) => ({
    apps: a.apps + (l.apps||0), interviews: a.interviews + (l.interviews||0),
    rejections: a.rejections + (l.rejections||0), alumContacted: a.alumContacted + (l.alumContacted||0),
    alumReplied: a.alumReplied + (l.alumReplied||0),
  }), { apps:0, interviews:0, rejections:0, alumContacted:0, alumReplied:0 });

  const offers = jobs.filter(j => j.stage === 3).length;
  const ir = totals.apps > 0 ? Math.round(totals.interviews / totals.apps * 100) : 0;
  const rr = totals.apps > 0 ? Math.round(totals.rejections / totals.apps * 100) : 0;
  const ar = totals.alumContacted > 0 ? Math.round(totals.alumReplied / totals.alumContacted * 100) : 0;

  const funnel = [
    { label: 'Applications', value: totals.apps, color: '#378ADD' },
    { label: 'Interviews', value: totals.interviews, color: '#1D9E75' },
    { label: 'Rejections', value: totals.rejections, color: '#E24B4A' },
    { label: 'Offers', value: offers, color: '#639922' },
  ];
  const maxF = Math.max(...funnel.map(f => f.value), 1);

  // Last 14 days trend
  const trend = Array(14).fill(null).map((_, i) => {
    const d = new Date(); d.setDate(d.getDate() - (13 - i));
    const ds = d.toISOString().split('T')[0];
    const log = logs.find(l => l.date === ds);
    return { label: d.getDate(), value: log?.apps || 0 };
  });
  const maxT = Math.max(...trend.map(t => t.value), 1);

  const rateCards = [
    { label: 'Interview rate', value: ir + '%' },
    { label: 'Rejection rate', value: rr + '%' },
    { label: 'Alumni reply rate', value: ar + '%' },
    { label: 'Active offers', value: offers },
  ];

  return (
    <div>
      <h2 style={{ fontSize: 16, fontWeight: 500, marginBottom: 16 }}>Analytics</h2>
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
        {/* Funnel */}
        <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 12, padding: 20 }}>
          <h3 style={{ fontSize: 13, fontWeight: 500, color: '#888', marginBottom: 16 }}>Funnel breakdown</h3>
          {funnel.map(f => (
            <div key={f.label} style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 12 }}>
              <span style={{ fontSize: 12, color: '#888', width: 100, flexShrink: 0, textAlign: 'right' }}>{f.label}</span>
              <div style={{ flex: 1, background: '#f5f5f4', borderRadius: 4, height: 20, overflow: 'hidden' }}>
                <div style={{ height: '100%', borderRadius: 4, background: f.color, width: `${Math.max(4, Math.round(f.value / maxF * 100))}%`, display: 'flex', alignItems: 'center', paddingLeft: 8 }}>
                  <span style={{ fontSize: 11, color: '#fff', fontWeight: 500 }}>{f.value}</span>
                </div>
              </div>
            </div>
          ))}
        </div>

        {/* Rate cards */}
        <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 12, padding: 20 }}>
          <h3 style={{ fontSize: 13, fontWeight: 500, color: '#888', marginBottom: 16 }}>Key rates</h3>
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 10 }}>
            {rateCards.map(r => (
              <div key={r.label} style={{ background: '#f5f5f4', borderRadius: 10, padding: 14, textAlign: 'center' }}>
                <div style={{ fontSize: 26, fontWeight: 500, color: '#111' }}>{r.value}</div>
                <div style={{ fontSize: 11, color: '#888', marginTop: 4 }}>{r.label}</div>
              </div>
            ))}
          </div>
        </div>

        {/* Trend */}
        <div style={{ background: '#fff', border: '0.5px solid #e5e5e5', borderRadius: 12, padding: 20, gridColumn: '1/-1' }}>
          <h3 style={{ fontSize: 13, fontWeight: 500, color: '#888', marginBottom: 16 }}>Applications per day (last 14 days)</h3>
          <div style={{ display: 'flex', alignItems: 'flex-end', gap: 4, height: 80 }}>
            {trend.map((t, i) => (
              <div key={i} style={{ flex: 1, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, height: '100%', justifyContent: 'flex-end' }}>
                <div title={`${t.value} apps`} style={{ width: '100%', borderRadius: '3px 3px 0 0', background: '#5DCAA5', height: `${Math.max(2, Math.round(t.value / maxT * 64))}px`, minHeight: 2 }} />
              </div>
            ))}
          </div>
          <div style={{ display: 'flex', gap: 4, marginTop: 6 }}>
            {trend.map((t, i) => (
              <div key={i} style={{ flex: 1, fontSize: 9, color: '#aaa', textAlign: 'center' }}>{t.label}</div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
EOF

# ─── src/App.jsx ─────────────────────────────────────────────
cat > src/App.jsx << 'EOF'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
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
    </AuthProvider>
  );
}
EOF

# ─── src/main.jsx ─────────────────────────────────────────────
cat > src/main.jsx << 'EOF'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.jsx'

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <App />
  </StrictMode>,
)
EOF

# ─── src/index.css ────────────────────────────────────────────
cat > src/index.css << 'EOF'
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; color: #111; }
input, textarea, select, button { font-family: inherit; }
input:focus, textarea:focus, select:focus { outline: none; border-color: #1D9E75 !important; }
EOF

echo ""
echo "✅ Frontend files created!"
echo ""
echo "Next steps:"
echo "  1. npm run dev"
echo "  2. Open http://localhost:5173"
echo "  3. Login with your credentials"
echo ""
