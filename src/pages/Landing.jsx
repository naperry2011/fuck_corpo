import Application from '../components/Application';
import Card from '../components/shared/Card';
import './Landing.css';

export default function Landing() {
  return (
    <main className="landing">
      {/* ── Hero ─────────────────────────────────── */}
      <section className="landing-hero">
        <span className="landing-ticker">$POOP +420.69%</span>
        <h1>
          QUARTERLY{' '}
          <span className="text-green">EARNINGS REPORT</span>
        </h1>
        <p className="landing-tagline">
          Your time is valuable, even in the bathroom.
        </p>
        <p className="landing-subtitle">
          Track exactly how much your employer pays you to handle personal business.
          Because every minute on the clock counts toward your bottom line.
        </p>
      </section>

      {/* ── Application Wizard ───────────────────── */}
      <Application />

      {/* ── Features Preview ─────────────────────── */}
      <section className="landing-features">
        <p className="landing-features-heading">What Your Portfolio Includes</p>
        <div className="landing-features-grid">
          <Card className="feature-card">
            <div className="feature-icon">💰</div>
            <h4>Track Earnings</h4>
            <p>
              Log every bathroom break and watch your off-the-books compensation grow
              in real time.
            </p>
            <span className="feature-ticker">$FLUSH +12.4%</span>
          </Card>

          <Card className="feature-card">
            <div className="feature-icon">📊</div>
            <h4>View Stats</h4>
            <p>
              Detailed analytics on your ROI. Daily, weekly, and monthly breakdowns
              of time reclaimed.
            </p>
            <span className="feature-ticker">$STATS +8.7%</span>
          </Card>

          <Card className="feature-card">
            <div className="feature-icon">🏆</div>
            <h4>Earn Achievements</h4>
            <p>
              Unlock badges for milestones like "First $100 Earned" and
              "Marathon Session."
            </p>
            <span className="feature-ticker">$BADGE +31.2%</span>
          </Card>
        </div>
      </section>
    </main>
  );
}
