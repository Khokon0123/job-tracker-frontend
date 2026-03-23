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
