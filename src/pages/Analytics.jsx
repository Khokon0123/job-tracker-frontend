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
