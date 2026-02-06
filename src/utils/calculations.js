// Working hours assumptions
const WORK_HOURS_PER_DAY = 8;
const WORK_DAYS_PER_WEEK = 5;
const WORK_WEEKS_PER_YEAR = 52;
const WORK_DAYS_PER_YEAR = WORK_DAYS_PER_WEEK * WORK_WEEKS_PER_YEAR;
const WORK_HOURS_PER_YEAR = WORK_DAYS_PER_YEAR * WORK_HOURS_PER_DAY;
const WORK_MINUTES_PER_YEAR = WORK_HOURS_PER_YEAR * 60;

export function salaryToPerMinute(amount, type = 'annual') {
  let annual;
  switch (type) {
    case 'hourly':
      annual = amount * WORK_HOURS_PER_YEAR;
      break;
    case 'monthly':
      annual = amount * 12;
      break;
    case 'weekly':
      annual = amount * WORK_WEEKS_PER_YEAR;
      break;
    case 'annual':
    default:
      annual = amount;
  }
  return annual / WORK_MINUTES_PER_YEAR;
}

export function calculateEarnings(durationMs, perMinuteRate) {
  const minutes = durationMs / 60000;
  return minutes * perMinuteRate;
}

export function formatCurrency(amount, currency = 'USD') {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency,
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount);
}

export function formatDuration(ms) {
  const totalSeconds = Math.floor(ms / 1000);
  const hours = Math.floor(totalSeconds / 3600);
  const minutes = Math.floor((totalSeconds % 3600) / 60);
  const seconds = totalSeconds % 60;
  const pad = (n) => String(n).padStart(2, '0');
  if (hours > 0) return `${pad(hours)}:${pad(minutes)}:${pad(seconds)}`;
  return `${pad(minutes)}:${pad(seconds)}`;
}

export function getBreaksInRange(breaks, startDate, endDate) {
  const start = new Date(startDate).getTime();
  const end = new Date(endDate).getTime();
  return breaks.filter((b) => {
    const t = new Date(b.timestamp).getTime();
    return t >= start && t <= end;
  });
}

export function getTodayBreaks(breaks) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), now.getDate());
  const end = new Date(start);
  end.setDate(end.getDate() + 1);
  return getBreaksInRange(breaks, start, end);
}

export function getWeekBreaks(breaks) {
  const now = new Date();
  const day = now.getDay();
  const start = new Date(now);
  start.setDate(now.getDate() - day);
  start.setHours(0, 0, 0, 0);
  const end = new Date(start);
  end.setDate(end.getDate() + 7);
  return getBreaksInRange(breaks, start, end);
}

export function getMonthBreaks(breaks) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);
  return getBreaksInRange(breaks, start, end);
}

export function getYearBreaks(breaks) {
  const now = new Date();
  const start = new Date(now.getFullYear(), 0, 1);
  const end = new Date(now.getFullYear() + 1, 0, 1);
  return getBreaksInRange(breaks, start, end);
}

export function totalEarnings(breaks, perMinuteRate) {
  return breaks.reduce((sum, b) => sum + calculateEarnings(b.duration, perMinuteRate), 0);
}

export function totalDuration(breaks) {
  return breaks.reduce((sum, b) => sum + b.duration, 0);
}

// Fun comparisons
const COMPARISONS = [
  { name: 'coffees', unit: 'coffee', plural: 'coffees', price: 5.50 },
  { name: 'burgers', unit: 'burger', plural: 'burgers', price: 12.00 },
  { name: 'gallons of gas', unit: 'gallon of gas', plural: 'gallons of gas', price: 3.50 },
  { name: 'streaming subscriptions', unit: 'month of streaming', plural: 'months of streaming', price: 15.99 },
  { name: 'avocado toasts', unit: 'avocado toast', plural: 'avocado toasts', price: 14.00 },
  { name: 'lottery tickets', unit: 'lottery ticket', plural: 'lottery tickets', price: 2.00 },
  { name: 'tacos', unit: 'taco', plural: 'tacos', price: 3.50 },
];

export function getComparisons(amount) {
  return COMPARISONS.map((c) => {
    const count = Math.floor(amount / c.price);
    return {
      ...c,
      count,
      label: count === 1 ? c.unit : c.plural,
    };
  }).filter((c) => c.count > 0);
}
