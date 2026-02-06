import { useState, useRef, useEffect } from 'react';
import { Trash2 } from 'lucide-react';
import { useApp } from '../context/AppContext';
import { useToast } from '../context/ToastContext';
import useSound from '../hooks/useSound';
import {
  calculateEarnings,
  formatCurrency,
  formatDuration,
  getTodayBreaks,
  totalEarnings,
  totalDuration,
} from '../utils/calculations';
import { getRandomMotivation } from '../utils/funFacts';
import Button from '../components/shared/Button';
import Card from '../components/shared/Card';
import PageTransition from '../components/shared/PageTransition';
import './Timer.css';

const CATEGORIES = [
  { value: 'Bathroom', emoji: '\u{1F6BD}' },
  { value: 'Smoke Break', emoji: '\u{1F6AC}' },
  { value: 'Mental Health Moment', emoji: '\u{1F9D8}' },
  { value: 'Coffee Break', emoji: '\u2615' },
  { value: 'Other', emoji: '\u23F0' },
];

function categoryEmoji(category) {
  return CATEGORIES.find((c) => c.value === category)?.emoji ?? '\u23F0';
}

function timeAgo(timestamp) {
  const diff = Date.now() - new Date(timestamp).getTime();
  const mins = Math.floor(diff / 60000);
  if (mins < 1) return 'just now';
  if (mins < 60) return `${mins}m ago`;
  const hours = Math.floor(mins / 60);
  if (hours < 24) return `${hours}h ago`;
  const days = Math.floor(hours / 24);
  return `${days}d ago`;
}

export default function Timer() {
  const { state, dispatch, perMinuteRate } = useApp();
  const { addToast } = useToast();
  const { chaChing } = useSound();

  // Live timer state
  const [running, setRunning] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  const [category, setCategory] = useState('Bathroom');
  const startTimeRef = useRef(null);

  // Quick log state
  const [quickMinutes, setQuickMinutes] = useState('');
  const [quickCategory, setQuickCategory] = useState('Bathroom');
  const [quickDate, setQuickDate] = useState(() => new Date().toISOString().split('T')[0]);

  // Motivational quote (picked fresh each time timer starts)
  const [motivation, setMotivation] = useState(getRandomMotivation);

  // Live timer effect
  useEffect(() => {
    if (!running) return;
    startTimeRef.current = Date.now() - elapsed;
    const id = setInterval(() => {
      setElapsed(Date.now() - startTimeRef.current);
    }, 100);
    return () => clearInterval(id);
  }, [running]);

  const handleToggle = () => {
    if (running) {
      // Stop and save
      setRunning(false);
      if (elapsed > 1000) {
        const earned = calculateEarnings(elapsed, perMinuteRate);
        const breakRecord = {
          id: crypto.randomUUID(),
          category,
          duration: elapsed,
          timestamp: new Date().toISOString(),
        };
        dispatch({ type: 'ADD_BREAK', payload: breakRecord });
        addToast(`Break logged! You earned ${formatCurrency(earned)}`, 'success');
        chaChing();
      }
      setElapsed(0);
    } else {
      setMotivation(getRandomMotivation());
      setRunning(true);
    }
  };

  const handleQuickLog = (e) => {
    e.preventDefault();
    const mins = parseFloat(quickMinutes);
    if (!mins || mins <= 0) return;
    const duration = mins * 60000;
    const earned = calculateEarnings(duration, perMinuteRate);
    const breakRecord = {
      id: crypto.randomUUID(),
      category: quickCategory,
      duration,
      timestamp: new Date(quickDate + 'T12:00:00').toISOString(),
    };
    dispatch({ type: 'ADD_BREAK', payload: breakRecord });
    addToast(`Break logged! You earned ${formatCurrency(earned)}`, 'success');
    chaChing();
    setQuickMinutes('');
  };

  const handleDelete = (breakId) => {
    dispatch({ type: 'DELETE_BREAK', payload: breakId });
    addToast('Break deleted', 'info');
  };

  // Derived data
  const todayBreaks = getTodayBreaks(state.breaks);
  const todayEarnings = totalEarnings(todayBreaks, perMinuteRate);
  const todayDuration = totalDuration(todayBreaks);
  const liveEarnings = calculateEarnings(elapsed, perMinuteRate);

  const recentBreaks = [...state.breaks]
    .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp))
    .slice(0, 10);

  return (
    <PageTransition className="timer-page">
      {/* Live Timer Section */}
      <section className="timer-hero">
        <div className="timer-category-selector">
          {CATEGORIES.map((cat) => (
            <button
              key={cat.value}
              className={`category-chip ${category === cat.value ? 'category-chip-active' : ''}`}
              onClick={() => setCategory(cat.value)}
              disabled={running}
              aria-label={cat.value}
            >
              <span className="category-emoji">{cat.emoji}</span>
              <span className="category-label">{cat.value}</span>
            </button>
          ))}
        </div>

        <div className="timer-display">
          <span className="timer-clock mono">{formatDuration(elapsed)}</span>
          <span className={`timer-earnings mono text-green${running ? ' timer-earnings-active' : ''}`}>
            {formatCurrency(liveEarnings)}
          </span>
        </div>

        <Button
          variant={running ? 'danger' : 'primary'}
          size="lg"
          className="timer-toggle-btn"
          onClick={handleToggle}
        >
          {running ? 'STOP & LOG' : 'START BREAK'}
        </Button>

        {running && (
          <>
            <p className="timer-status text-gray">
              Earning since you stepped away...
            </p>
            <p className="timer-motivation">{motivation}</p>
          </>
        )}
      </section>

      {/* Quick Log Section */}
      <section className="timer-section">
        <h3>Quick Log</h3>
        <Card className="quick-log-card">
          <form className="quick-log-form" onSubmit={handleQuickLog}>
            <div className="form-row">
              <div className="form-group">
                <label htmlFor="quick-minutes">Minutes</label>
                <input
                  id="quick-minutes"
                  type="number"
                  min="1"
                  max="480"
                  step="1"
                  placeholder="15"
                  value={quickMinutes}
                  onChange={(e) => setQuickMinutes(e.target.value)}
                  className="form-input mono"
                />
              </div>
              <div className="form-group">
                <label htmlFor="quick-category">Category</label>
                <select
                  id="quick-category"
                  value={quickCategory}
                  onChange={(e) => setQuickCategory(e.target.value)}
                  className="form-input"
                >
                  {CATEGORIES.map((cat) => (
                    <option key={cat.value} value={cat.value}>
                      {cat.emoji} {cat.value}
                    </option>
                  ))}
                </select>
              </div>
              <div className="form-group">
                <label htmlFor="quick-date">Date</label>
                <input
                  id="quick-date"
                  type="date"
                  value={quickDate}
                  onChange={(e) => setQuickDate(e.target.value)}
                  className="form-input"
                />
              </div>
            </div>
            <Button type="submit" variant="secondary" size="md">
              Log Break
            </Button>
          </form>
        </Card>
      </section>

      {/* Today's Summary Section */}
      <section className="timer-section">
        <h3>Today's Summary</h3>
        <div className="summary-grid">
          <Card className="summary-card">
            <span className="summary-label text-gray">Breaks Today</span>
            <span className="summary-value mono">{todayBreaks.length}</span>
          </Card>
          <Card className="summary-card">
            <span className="summary-label text-gray">Time on Break</span>
            <span className="summary-value mono">{formatDuration(todayDuration)}</span>
          </Card>
          <Card className="summary-card">
            <span className="summary-label text-gray">Earnings Today</span>
            <span className="summary-value mono text-green">{formatCurrency(todayEarnings)}</span>
          </Card>
        </div>
      </section>

      {/* Recent Breaks Section */}
      {recentBreaks.length > 0 && (
        <section className="timer-section">
          <h3>Recent Breaks</h3>
          <div className="recent-breaks-list">
            {recentBreaks.map((b) => (
              <Card key={b.id} className="break-item">
                <span className="break-emoji">{categoryEmoji(b.category)}</span>
                <div className="break-info">
                  <span className="break-category">{b.category}</span>
                  <span className="break-time text-gray">{timeAgo(b.timestamp)}</span>
                </div>
                <div className="break-stats">
                  <span className="break-duration mono">{formatDuration(b.duration)}</span>
                  <span className="break-earned mono text-green">
                    {formatCurrency(calculateEarnings(b.duration, perMinuteRate))}
                  </span>
                </div>
                <button
                  className="break-delete"
                  onClick={() => handleDelete(b.id)}
                  aria-label={`Delete ${b.category} break`}
                >
                  <Trash2 size={16} />
                </button>
              </Card>
            ))}
          </div>
        </section>
      )}
    </PageTransition>
  );
}
