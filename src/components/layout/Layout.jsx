import Navbar from './Navbar';
import Ticker from './Ticker';
import './Layout.css';

export default function Layout({ children }) {
  return (
    <div className="layout">
      <Navbar />
      <Ticker />
      <main className="layout-main">
        <div className="container">
          {children}
        </div>
      </main>
    </div>
  );
}
