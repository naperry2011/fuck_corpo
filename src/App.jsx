import { Routes, Route } from 'react-router-dom';
import Layout from './components/layout/Layout';
import Landing from './pages/Landing';
import Timer from './pages/Timer';
import Dashboard from './pages/Dashboard';
import Achievements from './pages/Achievements';
import Settings from './pages/Settings';
import { useApp } from './context/AppContext';

function App() {
  const { state } = useApp();

  if (!state.onboarded) {
    return <Landing />;
  }

  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Timer />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/achievements" element={<Achievements />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Layout>
  );
}

export default App;
