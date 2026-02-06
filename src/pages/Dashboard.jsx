import { useMemo, useState, useEffect, useCallback } from 'react';
import { useApp } from '../context/AppContext';
import {
  getTodayBreaks,
  getWeekBreaks,
  getMonthBreaks,
  getYearBreaks,
  totalEarnings,
  totalDuration,
  formatCurrency,
  formatDuration,
  getBreaksInRange,
  getComparisons,
  calculateEarnings,
} from '../utils/calculations';
import { getRandomFact, getCorporateMemo } from '../utils/funFacts';
import Card from '../components/shared/Card';
import AnimatedCurrency from '../components/shared/AnimatedCurrency';
import PageTransition from '../components/shared/PageTransition';
import { Line, Bar, Doughnut } from 'react-chartjs-2';
import {
  Chart as ChartJS,
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler,
} from 'chart.js';
import './Dashboard.css';

ChartJS.register(
  CategoryScale,
  LinearScale,
  PointElement,
  LineElement,
  BarElement,
  ArcElement,
  Title,
  Tooltip,
  Legend,
  Filler
);

const COMPARISON_EMOJIS = {
  coffees: '\u2615',
  burgers: '\uD83C\uDF54',
  'gallons of gas': '\u26FD',
  'streaming subscriptions': '\uD83D\uDCFA',
  'avocado toasts': '\uD83E\uDD51',
  'lottery tickets': '\uD83C\uDFB0',
  tacos: '\uD83C\uDF2E',
};

const CATEGORY_COLORS = {
  Bathroom: '#00b559',
  Smoke: '#e63946',
  'Mental Health': '#ffd60a',
  Coffee: '#c9a648',
  Other: '#778da9',
};

export default function Dashboard() {
  const { state, perMinuteRate } = useApp();
  const breaks = state.breaks;

  // Running totals
  const todayBreaks = useMemo(() => getTodayBreaks(breaks), [breaks]);
  const weekBreaks = useMemo(() => getWeekBreaks(breaks), [breaks]);
  const monthBreaks = useMemo(() => getMonthBreaks(breaks), [breaks]);
  const yearBreaks = useMemo(() => getYearBreaks(breaks), [breaks]);

  const todayEarnings = useMemo(() => totalEarnings(todayBreaks, perMinuteRate), [todayBreaks, perMinuteRate]);
  const weekEarnings = useMemo(() => totalEarnings(weekBreaks, perMinuteRate), [weekBreaks, perMinuteRate]);
  const monthEarnings = useMemo(() => totalEarnings(monthBreaks, perMinuteRate), [monthBreaks, perMinuteRate]);
  const yearEarnings = useMemo(() => totalEarnings(yearBreaks, perMinuteRate), [yearBreaks, perMinuteRate]);
  const lifetimeEarnings = useMemo(() => totalEarnings(breaks, perMinuteRate), [breaks, perMinuteRate]);

  // Last 7 days earnings chart data
  const earningsChartData = useMemo(() => {
    const labels = [];
    const data = [];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      const start = new Date(date.getFullYear(), date.getMonth(), date.getDate());
      const end = new Date(start);
      end.setDate(end.getDate() + 1);
      const dayBreaks = getBreaksInRange(breaks, start, end);
      const dayEarnings = totalEarnings(dayBreaks, perMinuteRate);
      labels.push(start.toLocaleDateString('en-US', { weekday: 'short', month: 'short', day: 'numeric' }));
      data.push(parseFloat(dayEarnings.toFixed(2)));
    }
    return { labels, data };
  }, [breaks, perMinuteRate]);

  // Break patterns by hour
  const breakPatternData = useMemo(() => {
    const hourCounts = new Array(24).fill(0);
    breaks.forEach((b) => {
      const hour = new Date(b.timestamp).getHours();
      hourCounts[hour]++;
    });
    return hourCounts;
  }, [breaks]);

  // Category breakdown
  const categoryData = useMemo(() => {
    const counts = {};
    breaks.forEach((b) => {
      const cat = b.category || 'Other';
      counts[cat] = (counts[cat] || 0) + 1;
    });
    return counts;
  }, [breaks]);

  // Fun stats
  const funStats = useMemo(() => {
    if (breaks.length === 0) return null;
    const totalDur = totalDuration(breaks);
    const avgDuration = totalDur / breaks.length;
    const longestBreak = Math.max(...breaks.map((b) => b.duration));
    const categoryCounts = {};
    breaks.forEach((b) => {
      const cat = b.category || 'Other';
      categoryCounts[cat] = (categoryCounts[cat] || 0) + 1;
    });
    const mostCommon = Object.entries(categoryCounts).sort((a, b) => b[1] - a[1])[0];
    return {
      avgDuration,
      longestBreak,
      totalBreaks: breaks.length,
      mostCommonCategory: mostCommon ? mostCommon[0] : 'N/A',
    };
  }, [breaks]);

  // Comparisons
  const comparisons = useMemo(() => getComparisons(lifetimeEarnings), [lifetimeEarnings]);

  // Rotating fun fact (changes every 10 seconds)
  const [currentFact, setCurrentFact] = useState(getRandomFact);
  const [factVisible, setFactVisible] = useState(true);

  const rotateFact = useCallback(() => {
    setFactVisible(false);
    setTimeout(() => {
      setCurrentFact(getRandomFact());
      setFactVisible(true);
    }, 400);
  }, []);

  useEffect(() => {
    const id = setInterval(rotateFact, 10000);
    return () => clearInterval(id);
  }, [rotateFact]);

  // Corporate memo based on user stats
  const corporateMemo = useMemo(() => {
    const totalDur = totalDuration(breaks);
    const avgDuration = breaks.length > 0 ? totalDur / breaks.length : 0;
    return getCorporateMemo({
      earnings: lifetimeEarnings,
      breakCount: breaks.length,
      avgDuration,
    });
  }, [breaks, lifetimeEarnings]);

  // Empty state
  if (breaks.length === 0) {
    return (
      <div className="dashboard container">
        <header className="dashboard-header">
          <span className="dashboard-confidential">CONFIDENTIAL</span>
          <h2 className="dashboard-title">YOUR QUARTERLY EARNINGS REPORT</h2>
        </header>
        <Card className="dashboard-empty">
          <p className="dashboard-empty-text">
            No data yet. Start tracking your breaks to see your earnings report.
          </p>
        </Card>
      </div>
    );
  }

  // Chart configs
  const lineChartData = {
    labels: earningsChartData.labels,
    datasets: [
      {
        label: 'Daily Earnings',
        data: earningsChartData.data,
        borderColor: '#00b559',
        backgroundColor: 'rgba(0,181,89,0.1)',
        fill: true,
        tension: 0.3,
        pointBackgroundColor: '#00b559',
        pointBorderColor: '#00b559',
        pointRadius: 4,
        pointHoverRadius: 6,
      },
    ],
  };

  const lineChartOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { labels: { color: '#fff', font: { family: "'Roboto Mono', monospace" } } },
      tooltip: {
        callbacks: {
          label: (ctx) => formatCurrency(ctx.parsed.y),
        },
      },
    },
    scales: {
      x: {
        ticks: { color: '#778da9', font: { family: "'Roboto Mono', monospace", size: 11 } },
        grid: { color: 'rgba(119,141,169,0.2)' },
      },
      y: {
        ticks: {
          color: '#778da9',
          font: { family: "'Roboto Mono', monospace", size: 11 },
          callback: (value) => formatCurrency(value),
        },
        grid: { color: 'rgba(119,141,169,0.2)' },
      },
    },
  };

  const hourLabels = Array.from({ length: 24 }, (_, i) => {
    const ampm = i >= 12 ? 'PM' : 'AM';
    const hour = i % 12 || 12;
    return `${hour}${ampm}`;
  });

  const barChartData = {
    labels: hourLabels,
    datasets: [
      {
        label: 'Breaks',
        data: breakPatternData,
        backgroundColor: 'rgba(0,181,89,0.6)',
        borderColor: '#00b559',
        borderWidth: 1,
        borderRadius: 4,
      },
    ],
  };

  const barChartOptions = {
    indexAxis: 'y',
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: { labels: { color: '#fff', font: { family: "'Roboto Mono', monospace" } } },
    },
    scales: {
      x: {
        ticks: { color: '#778da9', font: { family: "'Roboto Mono', monospace", size: 11 }, stepSize: 1 },
        grid: { color: 'rgba(119,141,169,0.2)' },
      },
      y: {
        ticks: { color: '#778da9', font: { family: "'Roboto Mono', monospace", size: 10 } },
        grid: { color: 'rgba(119,141,169,0.1)' },
      },
    },
  };

  const categoryLabels = Object.keys(categoryData);
  const categoryValues = Object.values(categoryData);
  const categoryColors = categoryLabels.map((cat) => CATEGORY_COLORS[cat] || '#778da9');

  const doughnutData = {
    labels: categoryLabels,
    datasets: [
      {
        data: categoryValues,
        backgroundColor: categoryColors,
        borderColor: '#0a1128',
        borderWidth: 2,
        hoverOffset: 8,
      },
    ],
  };

  const doughnutOptions = {
    responsive: true,
    maintainAspectRatio: false,
    plugins: {
      legend: {
        position: 'bottom',
        labels: { color: '#fff', font: { family: "'Roboto Mono', monospace" }, padding: 16 },
      },
    },
  };

  const earningsTotals = [
    { label: 'TODAY', value: todayEarnings },
    { label: 'THIS WEEK', value: weekEarnings },
    { label: 'THIS MONTH', value: monthEarnings },
    { label: 'THIS YEAR', value: yearEarnings },
  ];

  return (
    <PageTransition className="dashboard container">
      <header className="dashboard-header">
        <span className="dashboard-confidential">CONFIDENTIAL</span>
        <h2 className="dashboard-title">YOUR QUARTERLY EARNINGS REPORT</h2>
        <p className="dashboard-subtitle">
          Internal document -- Do not distribute outside the restroom
        </p>
      </header>

      {/* Running Totals */}
      <section className="dashboard-section">
        <div className="dashboard-totals-grid">
          {earningsTotals.map((item) => (
            <Card key={item.label} className="dashboard-stat-card">
              <span className="dashboard-stat-label">{item.label}</span>
              <AnimatedCurrency value={item.value} className="dashboard-stat-value" />
            </Card>
          ))}
          <Card elevated className="dashboard-stat-card dashboard-stat-featured">
            <span className="dashboard-stat-label">LIFETIME EARNINGS</span>
            <AnimatedCurrency value={lifetimeEarnings} className="dashboard-stat-value dashboard-stat-featured-value" />
          </Card>
        </div>
      </section>

      {/* Market Analysis — Rotating Fun Fact */}
      <section className="dashboard-section">
        <h3 className="dashboard-section-title">MARKET ANALYSIS</h3>
        <Card className="dashboard-funfact">
          <p className={`dashboard-funfact-text ${factVisible ? 'dashboard-funfact-visible' : 'dashboard-funfact-hidden'}`}>
            {currentFact}
          </p>
        </Card>
      </section>

      {/* Corporate Memo */}
      <section className="dashboard-section">
        <h3 className="dashboard-section-title">INTERNAL CORRESPONDENCE</h3>
        <Card className="dashboard-memo">
          <div className="dashboard-memo-header">
            <span className="dashboard-memo-field"><strong>To:</strong> Employee #{String(breaks.length + 1000).padStart(5, '0')}</span>
            <span className="dashboard-memo-field"><strong>From:</strong> Management, Break Analytics Division</span>
            <span className="dashboard-memo-field"><strong>Subject:</strong> {corporateMemo.subject}</span>
          </div>
          <div className="dashboard-memo-divider" />
          <p className="dashboard-memo-body">{corporateMemo.body}</p>
        </Card>
      </section>

      {/* Earnings Over Time Chart */}
      <section className="dashboard-section">
        <h3 className="dashboard-section-title">EARNINGS OVER TIME</h3>
        <Card className="dashboard-chart-card">
          <div className="dashboard-chart-container dashboard-chart-line">
            <Line data={lineChartData} options={lineChartOptions} />
          </div>
        </Card>
      </section>

      {/* Charts Row: Patterns + Category */}
      <section className="dashboard-section">
        <div className="dashboard-charts-row">
          <div className="dashboard-chart-col">
            <h3 className="dashboard-section-title">BREAK PATTERNS</h3>
            <Card className="dashboard-chart-card">
              <div className="dashboard-chart-container dashboard-chart-bar">
                <Bar data={barChartData} options={barChartOptions} />
              </div>
            </Card>
          </div>
          <div className="dashboard-chart-col">
            <h3 className="dashboard-section-title">CATEGORY BREAKDOWN</h3>
            <Card className="dashboard-chart-card">
              <div className="dashboard-chart-container dashboard-chart-doughnut">
                <Doughnut data={doughnutData} options={doughnutOptions} />
              </div>
            </Card>
          </div>
        </div>
      </section>

      {/* Fun Stats */}
      {funStats && (
        <section className="dashboard-section">
          <h3 className="dashboard-section-title">PERFORMANCE METRICS</h3>
          <div className="dashboard-fun-stats-grid">
            <Card className="dashboard-fun-stat">
              <span className="dashboard-fun-stat-label">AVG SESSION LENGTH</span>
              <span className="dashboard-fun-stat-value">{formatDuration(funStats.avgDuration)}</span>
            </Card>
            <Card className="dashboard-fun-stat">
              <span className="dashboard-fun-stat-label">LONGEST SESSION EVER</span>
              <span className="dashboard-fun-stat-value">{formatDuration(funStats.longestBreak)}</span>
            </Card>
            <Card className="dashboard-fun-stat">
              <span className="dashboard-fun-stat-label">TOTAL BREAKS</span>
              <span className="dashboard-fun-stat-value">{funStats.totalBreaks}</span>
            </Card>
            <Card className="dashboard-fun-stat">
              <span className="dashboard-fun-stat-label">MOST COMMON CATEGORY</span>
              <span className="dashboard-fun-stat-value dashboard-fun-stat-category">
                {funStats.mostCommonCategory}
              </span>
            </Card>
          </div>
        </section>
      )}

      {/* Comparisons */}
      {comparisons.length > 0 && (
        <section className="dashboard-section">
          <h3 className="dashboard-section-title">YOUR EARNINGS CAN BUY...</h3>
          <div className="dashboard-comparisons-grid">
            {comparisons.map((c) => (
              <Card key={c.name} className="dashboard-comparison-card">
                <span className="dashboard-comparison-emoji">
                  {COMPARISON_EMOJIS[c.name] || '\uD83D\uDCB0'}
                </span>
                <span className="dashboard-comparison-count">{c.count}</span>
                <span className="dashboard-comparison-label">{c.label}</span>
              </Card>
            ))}
          </div>
        </section>
      )}
    </PageTransition>
  );
}
