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
