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
