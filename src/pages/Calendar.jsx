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
