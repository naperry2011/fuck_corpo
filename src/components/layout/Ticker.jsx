import { useApp } from '../../context/AppContext';
import { totalEarnings, totalDuration, formatCurrency, formatDuration, getTodayBreaks } from '../../utils/calculations';
import './Ticker.css';

export default function Ticker() {
  const { state, perMinuteRate } = useApp();
  const todayBreaks = getTodayBreaks(state.breaks);
  const todayEarned = totalEarnings(todayBreaks, perMinuteRate);
  const todayTime = totalDuration(todayBreaks);
  const lifetimeEarned = totalEarnings(state.breaks, perMinuteRate);
  const totalBreaks = state.breaks.length;

  const items = [
    { label: '$EARN', value: formatCurrency(todayEarned), positive: true },
    { label: '$TIME', value: formatDuration(todayTime), positive: false },
    { label: '$LIFE', value: formatCurrency(lifetimeEarned), positive: true },
    { label: '$SESS', value: String(totalBreaks), positive: true },
    { label: '$RATE', value: `${formatCurrency(perMinuteRate)}/min`, positive: true },
  ];

  // Duplicate for seamless scroll
  const tickerItems = [...items, ...items];

  return (
    <div className="ticker" role="marquee" aria-label="Earnings ticker">
      <div className="ticker-track">
        {tickerItems.map((item, i) => (
          <span key={i} className="ticker-item">
            <span className="ticker-symbol">{item.label}</span>
            <span className={`ticker-value ${item.positive ? 'positive' : 'negative'}`}>
              {item.value}
            </span>
            <span className="ticker-sep">|</span>
          </span>
        ))}
      </div>
    </div>
  );
}
