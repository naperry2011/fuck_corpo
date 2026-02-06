import { NavLink } from 'react-router-dom';
import { Timer, BarChart3, Trophy, Settings } from 'lucide-react';
import './Navbar.css';

export default function Navbar() {
  return (
    <nav className="navbar">
      <div className="navbar-inner container">
        <div className="navbar-brand">
          <span className="navbar-logo">$</span>
          <span className="navbar-title">FUCKCORPO</span>
        </div>
        <div className="navbar-links">
          <NavLink to="/" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`} end>
            <Timer size={20} />
            <span>Timer</span>
          </NavLink>
          <NavLink to="/dashboard" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <BarChart3 size={20} />
            <span>Dashboard</span>
          </NavLink>
          <NavLink to="/achievements" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <Trophy size={20} />
            <span>Achievements</span>
          </NavLink>
          <NavLink to="/settings" className={({ isActive }) => `nav-link ${isActive ? 'active' : ''}`}>
            <Settings size={20} />
            <span>Settings</span>
          </NavLink>
        </div>
      </div>
    </nav>
  );
}
