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
      <div style={{ padding: '24px', maxWidth: 1200, margin: '0 auto' }}>
        {children}
      </div>
    </div>
  );
}
