import { useState, useRef } from 'react';
import { useApp } from '../context/AppContext';
import { useToast } from '../context/ToastContext';
import { salaryToPerMinute, formatCurrency } from '../utils/calculations';
import { exportData, importData, clearData } from '../utils/storage';
import Button from '../components/shared/Button';
import Card from '../components/shared/Card';
import PageTransition from '../components/shared/PageTransition';
import './Settings.css';

const SALARY_TYPES = ['Annual', 'Hourly', 'Monthly', 'Weekly'];
const CURRENCIES = ['USD', 'EUR', 'GBP', 'CAD', 'AUD', 'JPY'];
const INDUSTRIES = [
  'Technology',
  'Healthcare',
  'Retail',
  'Finance',
  'Education',
  'Manufacturing',
  'Food Service',
  'Government',
  'Other',
];

export default function Settings() {
  const { state, dispatch } = useApp();
  const { addToast } = useToast();
  const fileInputRef = useRef(null);

  // Salary form state
  const [salaryAmount, setSalaryAmount] = useState(state.salary.amount || '');
  const [salaryType, setSalaryType] = useState(
    SALARY_TYPES.find((t) => t.toLowerCase() === state.salary.type) || 'Annual'
  );

  // Profile form state
  const [currency, setCurrency] = useState(state.settings.currency || 'USD');
  const [industry, setIndustry] = useState(state.settings.industry || '');
  const [stateRegion, setStateRegion] = useState(state.settings.state || '');

  // Theme state
  const [theme, setTheme] = useState(state.settings.theme || 'dark');

  // Sound state
  const [soundEnabled, setSoundEnabled] = useState(state.settings.soundEnabled !== false);

  // Data management state
  const [confirmClear, setConfirmClear] = useState(false);
  const [importStatus, setImportStatus] = useState(null);

  // Derived per-minute rate for display
  const previewRate = salaryAmount
    ? salaryToPerMinute(Number(salaryAmount), salaryType.toLowerCase())
    : 0;

  const handleSalaryUpdate = (e) => {
    e.preventDefault();
    if (!salaryAmount || Number(salaryAmount) <= 0) return;
    dispatch({
      type: 'SET_SALARY',
      payload: { amount: Number(salaryAmount), type: salaryType.toLowerCase() },
    });
    addToast('Salary updated', 'success');
  };

  const handleProfileSave = (e) => {
    e.preventDefault();
    dispatch({
      type: 'UPDATE_SETTINGS',
      payload: { currency, industry, state: stateRegion },
    });
    addToast('Profile saved', 'success');
  };

  const handleThemeToggle = () => {
    const next = theme === 'dark' ? 'light' : 'dark';
    setTheme(next);
    document.documentElement.setAttribute('data-theme', next);
    dispatch({ type: 'UPDATE_SETTINGS', payload: { theme: next } });
  };

  const handleSoundToggle = () => {
    const next = !soundEnabled;
    setSoundEnabled(next);
    dispatch({ type: 'UPDATE_SETTINGS', payload: { soundEnabled: next } });
  };

  const handleExport = () => {
    exportData();
    addToast('Data exported', 'success');
  };

  const handleImportClick = () => {
    fileInputRef.current?.click();
  };

  const handleImportFile = (e) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (event) => {
      const success = importData(event.target.result);
      if (success) {
        setImportStatus('success');
        addToast('Data imported successfully', 'success');
        setTimeout(() => window.location.reload(), 800);
      } else {
        setImportStatus('error');
      }
    };
    reader.readAsText(file);
    e.target.value = '';
  };

  const handleClearData = () => {
    if (!confirmClear) {
      setConfirmClear(true);
      return;
    }
    clearData();
    window.location.reload();
  };

  return (
    <PageTransition className="settings-page">
      {/* Page Header */}
      <header className="settings-header">
        <h2>ACCOUNT SETTINGS</h2>
        <p className="settings-subtitle text-gray">Manage your portfolio</p>
      </header>

      {/* Salary Settings */}
      <Card className="settings-card">
        <p className="settings-card-header">Compensation Package</p>
        <form className="settings-form" onSubmit={handleSalaryUpdate}>
          <div className="form-group">
            <label className="form-label" htmlFor="salary-amount">
              Salary / Wage
            </label>
            <div className="form-row">
              <input
                id="salary-amount"
                className="settings-input mono"
                type="number"
                min="0"
                step="any"
                placeholder="e.g. 75000"
                value={salaryAmount}
                onChange={(e) => setSalaryAmount(e.target.value)}
              />
              <select
                className="settings-select"
                value={salaryType}
                onChange={(e) => setSalaryType(e.target.value)}
                aria-label="Salary type"
              >
                {SALARY_TYPES.map((t) => (
                  <option key={t} value={t}>{t}</option>
                ))}
              </select>
            </div>
          </div>

          {previewRate > 0 && (
            <p className="per-minute-rate">
              Per-minute rate:{' '}
              <span className="mono text-green">
                {formatCurrency(previewRate, currency)}/min
              </span>
            </p>
          )}

          <Button type="submit" variant="primary" size="md">
            Update Salary
          </Button>
        </form>
      </Card>

      {/* Profile Settings */}
      <Card className="settings-card">
        <p className="settings-card-header">Employee Profile</p>
        <form className="settings-form" onSubmit={handleProfileSave}>
          <div className="form-group">
            <label className="form-label" htmlFor="settings-currency">
              Currency
            </label>
            <select
              id="settings-currency"
              className="settings-select"
              value={currency}
              onChange={(e) => setCurrency(e.target.value)}
            >
              {CURRENCIES.map((c) => (
                <option key={c} value={c}>{c}</option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="settings-industry">
              Industry
            </label>
            <select
              id="settings-industry"
              className="settings-select"
              value={industry}
              onChange={(e) => setIndustry(e.target.value)}
            >
              <option value="">Select Industry</option>
              {INDUSTRIES.map((i) => (
                <option key={i} value={i}>{i}</option>
              ))}
            </select>
          </div>

          <div className="form-group">
            <label className="form-label" htmlFor="settings-state">
              State / Region
            </label>
            <input
              id="settings-state"
              className="settings-input"
              type="text"
              placeholder="e.g. California"
              value={stateRegion}
              onChange={(e) => setStateRegion(e.target.value)}
            />
          </div>

          <Button type="submit" variant="primary" size="md">
            Save Profile
          </Button>
        </form>
      </Card>

      {/* Display Settings */}
      <Card className="settings-card">
        <p className="settings-card-header">Display Preferences</p>
        <div className="settings-form">
          <div className="theme-toggle-row">
            <div className="theme-toggle-info">
              <span className="form-label">Theme</span>
              <span className="theme-toggle-value text-gray">
                {theme === 'dark' ? 'Dark Mode' : 'Light Mode'}
              </span>
            </div>
            <button
              className={`theme-toggle ${theme === 'light' ? 'theme-toggle-light' : ''}`}
              onClick={handleThemeToggle}
              role="switch"
              aria-checked={theme === 'light'}
              aria-label="Toggle light mode"
            >
              <span className="theme-toggle-thumb" />
            </button>
          </div>
          <div className="theme-toggle-row">
            <div className="theme-toggle-info">
              <span className="form-label">Sound Effects</span>
              <span className="theme-toggle-value text-gray">
                {soundEnabled ? 'On' : 'Off'}
              </span>
            </div>
            <button
              className={`theme-toggle ${soundEnabled ? 'theme-toggle-light' : ''}`}
              onClick={handleSoundToggle}
              role="switch"
              aria-checked={soundEnabled}
              aria-label="Toggle sound effects"
            >
              <span className="theme-toggle-thumb" />
            </button>
          </div>
        </div>
      </Card>

      {/* Data Management */}
      <Card className="settings-card">
        <p className="settings-card-header">Data Management</p>
        <div className="settings-form">
          <div className="data-actions">
            <div className="data-action-row">
              <div>
                <p className="data-action-title">Export Data</p>
                <p className="data-action-desc text-gray">
                  Download your portfolio as a JSON file
                </p>
              </div>
              <Button variant="secondary" size="sm" onClick={handleExport}>
                Export Data
              </Button>
            </div>

            <div className="data-action-row">
              <div>
                <p className="data-action-title">Import Data</p>
                <p className="data-action-desc text-gray">
                  Restore from a previously exported file
                </p>
                {importStatus === 'success' && (
                  <p className="import-status text-green">Import successful. Reloading...</p>
                )}
                {importStatus === 'error' && (
                  <p className="import-status text-red">Invalid file format.</p>
                )}
              </div>
              <Button variant="secondary" size="sm" onClick={handleImportClick}>
                Import Data
              </Button>
              <input
                ref={fileInputRef}
                type="file"
                accept=".json"
                className="hidden-file-input"
                onChange={handleImportFile}
              />
            </div>

            <div className="data-action-row data-action-danger">
              <div>
                <p className="data-action-title">Clear All Data</p>
                <p className="data-action-desc text-gray">
                  Permanently delete all breaks, settings, and achievements
                </p>
              </div>
              {!confirmClear ? (
                <Button variant="danger" size="sm" onClick={handleClearData}>
                  Clear All Data
                </Button>
              ) : (
                <div className="confirm-clear">
                  <span className="confirm-text text-red">Are you sure?</span>
                  <Button variant="danger" size="sm" onClick={handleClearData}>
                    Confirm
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => setConfirmClear(false)}
                  >
                    Cancel
                  </Button>
                </div>
              )}
            </div>
          </div>
        </div>
      </Card>

      {/* About */}
      <Card className="settings-card">
        <p className="settings-card-header">Corporate Information</p>
        <div className="about-section">
          <h3 className="about-title">
            Fuck<span className="text-green">Corpo</span>
          </h3>
          <p className="about-version mono text-gray">v1.0.0</p>
          <p className="about-tagline">
            Your time is valuable, even in the bathroom.
          </p>
          <div className="about-details">
            <p><span className="text-gray">Board of Directors:</span> You</p>
            <p><span className="text-gray">Chief Bathroom Officer:</span> You</p>
            <p><span className="text-gray">Shareholder Value:</span>{' '}
              <span className="text-green">Maximized</span>
            </p>
          </div>
        </div>
      </Card>

      {/* Know Your Rights */}
      <Card className="settings-card settings-card-rights">
        <p className="settings-card-header settings-card-header-gold">
          Know Your Rights
        </p>
        <div className="rights-section">
          <p className="rights-text">
            Under OSHA regulations, employers must provide workers with toilet
            facilities and allow them to use them. Restricting bathroom access is
            a violation of workers' rights.
          </p>
          <p className="rights-footer text-gray">
            This is not legal advice. Know your local labor laws.
          </p>
        </div>
      </Card>
    </PageTransition>
  );
}
