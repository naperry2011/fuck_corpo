const STORAGE_KEY = 'fuckcorpo_data';

const defaultData = {
  salary: { amount: 0, type: 'annual', currency: 'USD' },
  breaks: [],
  settings: {
    theme: 'dark',
    currency: 'USD',
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    industry: '',
    state: '',
    soundEnabled: true,
  },
  achievements: [],
  onboarded: false,
};

export function loadData() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return { ...defaultData };
    return { ...defaultData, ...JSON.parse(raw) };
  } catch {
    return { ...defaultData };
  }
}

export function saveData(data) {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(data));
  } catch (e) {
    console.error('Failed to save data:', e);
  }
}

export function exportData() {
  const data = loadData();
  const blob = new Blob([JSON.stringify(data, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = `fuckcorpo-export-${new Date().toISOString().slice(0, 10)}.json`;
  a.click();
  URL.revokeObjectURL(url);
}

export function importData(jsonString) {
  try {
    const data = JSON.parse(jsonString);
    saveData({ ...defaultData, ...data });
    return true;
  } catch {
    return false;
  }
}

export function clearData() {
  localStorage.removeItem(STORAGE_KEY);
}
