import { useState, useEffect, useCallback } from 'react';
import { useApp } from '../context/AppContext';
import { Star, ArrowLeft, CheckCircle } from 'lucide-react';
import Button from './shared/Button';
import Card from './shared/Card';
import './Application.css';

const SALARY_TYPES = ['Annual', 'Hourly', 'Monthly', 'Weekly'];
const CURRENCIES = ['USD', 'EUR', 'GBP', 'CAD', 'AUD'];
const INDUSTRIES = [
  'Technology', 'Healthcare', 'Retail', 'Finance',
  'Education', 'Manufacturing', 'Food Service', 'Government', 'Other',
];

const EXPERIENCE_OPTIONS = [
  { value: '0-1', label: '0-1 (Novice)' },
  { value: '1-3', label: '1-3 (Intermediate)' },
  { value: '3-5', label: '3-5 (Seasoned)' },
  { value: '5-10', label: '5-10 (Expert)' },
  { value: '10+', label: '10+ (Veteran)' },
  { value: 'born-ready', label: 'I was born ready' },
];

const MOTIVATIONS = [
  'Financial gain',
  'Existential dread',
  'Coffee processing',
  'Doom scrolling',
  'Sticking it to the man',
  'All of the above',
];

const COMPOSURE_OPTIONS = [
  'Yes',
  'Absolutely',
  'Without question',
  'I was born for this',
];

const STATUS_MESSAGES = [
  'Verifying bathroom credentials...',
  'Cross-referencing break history with HR...',
  'Calculating your earning potential...',
  'Checking references with your toilet...',
  'Reviewing your commitment to doing nothing...',
  'Assessing corporate time theft aptitude...',
  'Consulting the Board of Bowel Directors...',
  'Finalizing your compensation package...',
];

export default function Application() {
  const { dispatch } = useApp();
  const [step, setStep] = useState(1);

  // Step 2 state
  const [fullName, setFullName] = useState('');
  const [pseudonym, setPseudonym] = useState('');
  const [starRating, setStarRating] = useState(0);
  const [hoverRating, setHoverRating] = useState(0);
  const [experience, setExperience] = useState('');

  // Step 3 state
  const [motivation, setMotivation] = useState('');
  const [composure, setComposure] = useState('');
  const [swearOath, setSwearOath] = useState(false);

  // Step 4 state
  const [progress, setProgress] = useState(0);
  const [statusIndex, setStatusIndex] = useState(0);
  const [approved, setApproved] = useState(false);

  // Step 5 state
  const [salary, setSalary] = useState('');
  const [salaryType, setSalaryType] = useState('Annual');
  const [currency, setCurrency] = useState('USD');
  const [industry, setIndustry] = useState('Technology');
  const [stateRegion, setStateRegion] = useState('');

  // Step 4: background check animation
  useEffect(() => {
    if (step !== 4) return;

    setProgress(0);
    setStatusIndex(0);
    setApproved(false);

    const duration = 4000;
    const interval = 50;
    let elapsed = 0;

    const progressTimer = setInterval(() => {
      elapsed += interval;
      const pct = Math.min((elapsed / duration) * 100, 100);
      setProgress(pct);
      if (pct >= 100) {
        clearInterval(progressTimer);
        setApproved(true);
      }
    }, interval);

    const statusTimer = setInterval(() => {
      setStatusIndex((prev) => (prev + 1) % STATUS_MESSAGES.length);
    }, 700);

    return () => {
      clearInterval(progressTimer);
      clearInterval(statusTimer);
    };
  }, [step]);

  // Auto-advance after approval
  useEffect(() => {
    if (!approved) return;
    const timer = setTimeout(() => setStep(5), 1200);
    return () => clearTimeout(timer);
  }, [approved]);

  const handleSubmit = useCallback((e) => {
    e.preventDefault();
    if (!salary || Number(salary) <= 0) return;
    dispatch({ type: 'SET_SALARY', payload: { amount: Number(salary), type: salaryType.toLowerCase() } });
    dispatch({ type: 'UPDATE_SETTINGS', payload: { currency, industry, state: stateRegion } });
    dispatch({ type: 'SET_ONBOARDED' });
  }, [salary, salaryType, currency, industry, stateRegion, dispatch]);

  const experienceLabel = EXPERIENCE_OPTIONS.find((o) => o.value === experience)?.label || experience;

  return (
    <Card elevated className="application">
      {/* Progress indicator */}
      <div className="app-progress">
        <span className="app-step-label">STEP {step} OF 5</span>
        <div className="app-progress-track">
          <div className="app-progress-fill" style={{ width: `${(step / 5) * 100}%` }} />
        </div>
      </div>

      {/* Step 1: Cover Page */}
      {step === 1 && (
        <div className="app-step app-step-cover">
          <div className="app-letterhead">
            <div className="app-logo-text">FUCKCORPO INC.</div>
            <div className="app-logo-divider" />
            <div className="app-logo-sub">EST. 2024 &bull; BATHROOM REVENUE DIVISION</div>
          </div>

          <h2 className="app-cover-title">APPLICATION FOR EMPLOYMENT</h2>

          <div className="app-cover-details">
            <div className="app-detail-row">
              <span className="app-detail-label">Position:</span>
              <span className="app-detail-value">Chief Bathroom Revenue Officer (CBRO)</span>
            </div>
            <div className="app-detail-row">
              <span className="app-detail-label">Department:</span>
              <span className="app-detail-value">Asset Liberation Division</span>
            </div>
            <div className="app-detail-row">
              <span className="app-detail-label">Status:</span>
              <span className="app-detail-value">Full-Time (Bathroom Hours)</span>
            </div>
          </div>

          <Button variant="primary" size="lg" onClick={() => setStep(2)} className="app-begin-btn">
            BEGIN APPLICATION
          </Button>

          <p className="app-fine-print">
            FuckCorpo Inc. is an equal opportunity employer of bathroom breaks. All toilet types welcome.
          </p>
        </div>
      )}

      {/* Step 2: Applicant Information */}
      {step === 2 && (
        <div className="app-step">
          <button className="app-back" onClick={() => setStep(1)} type="button">
            <ArrowLeft size={16} /> Back
          </button>
          <h3 className="app-step-title">APPLICANT INFORMATION</h3>

          <div className="app-form">
            <div className="form-group">
              <label className="form-label" htmlFor="app-name">Full Name</label>
              <input
                id="app-name"
                className="form-input"
                type="text"
                placeholder="e.g. John Q. Taxpayer"
                value={fullName}
                onChange={(e) => setFullName(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="app-pseudonym">Preferred Bathroom Pseudonym</label>
              <input
                id="app-pseudonym"
                className="form-input"
                type="text"
                placeholder="e.g. The Phantom Flusher"
                value={pseudonym}
                onChange={(e) => setPseudonym(e.target.value)}
              />
            </div>

            <div className="form-group">
              <label className="form-label">How would you rate your current bathroom break performance?</label>
              <div className="app-stars">
                {[1, 2, 3, 4, 5].map((i) => (
                  <button
                    key={i}
                    type="button"
                    className="app-star-btn"
                    onClick={() => setStarRating(i)}
                    onMouseEnter={() => setHoverRating(i)}
                    onMouseLeave={() => setHoverRating(0)}
                    aria-label={`${i} star${i > 1 ? 's' : ''}`}
                  >
                    <Star
                      size={32}
                      fill={(hoverRating || starRating) >= i ? 'var(--color-gold)' : 'none'}
                      color={(hoverRating || starRating) >= i ? 'var(--color-gold)' : 'var(--color-gray)'}
                    />
                  </button>
                ))}
              </div>
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="app-experience">Years of Professional Bathroom Experience</label>
              <select
                id="app-experience"
                className="form-select"
                value={experience}
                onChange={(e) => setExperience(e.target.value)}
              >
                <option value="" disabled>Select your experience level</option>
                {EXPERIENCE_OPTIONS.map((o) => (
                  <option key={o.value} value={o.value}>{o.label}</option>
                ))}
              </select>
            </div>
          </div>

          <Button
            variant="primary"
            size="lg"
            className="app-next-btn"
            onClick={() => setStep(3)}
          >
            CONTINUE
          </Button>
        </div>
      )}

      {/* Step 3: Skills Assessment */}
      {step === 3 && (
        <div className="app-step">
          <button className="app-back" onClick={() => setStep(2)} type="button">
            <ArrowLeft size={16} /> Back
          </button>
          <h3 className="app-step-title">SKILLS ASSESSMENT</h3>

          <div className="app-form">
            <div className="form-group">
              <label className="form-label">What is your primary motivation for bathroom breaks?</label>
              <div className="app-radio-group">
                {MOTIVATIONS.map((m) => (
                  <label key={m} className={`app-radio-option ${motivation === m ? 'selected' : ''}`}>
                    <input
                      type="radio"
                      name="motivation"
                      value={m}
                      checked={motivation === m}
                      onChange={() => setMotivation(m)}
                    />
                    <span className="app-radio-indicator" />
                    <span>{m}</span>
                  </label>
                ))}
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Can you maintain composure while earning money on the toilet?</label>
              <div className="app-radio-group">
                {COMPOSURE_OPTIONS.map((c) => (
                  <label key={c} className={`app-radio-option ${composure === c ? 'selected' : ''}`}>
                    <input
                      type="radio"
                      name="composure"
                      value={c}
                      checked={composure === c}
                      onChange={() => setComposure(c)}
                    />
                    <span className="app-radio-indicator" />
                    <span>{c}</span>
                  </label>
                ))}
              </div>
            </div>

            <div className="form-group">
              <label className="form-label">Do you solemnly swear to maximize your bathroom ROI?</label>
              <label className={`app-toggle ${swearOath ? 'active' : ''}`}>
                <input
                  type="checkbox"
                  checked={swearOath}
                  onChange={(e) => setSwearOath(e.target.checked)}
                />
                <span className="app-toggle-track">
                  <span className="app-toggle-thumb" />
                </span>
                <span className="app-toggle-label">{swearOath ? 'I solemnly swear' : 'I do not yet swear'}</span>
              </label>
            </div>
          </div>

          <Button
            variant="primary"
            size="lg"
            className="app-next-btn"
            onClick={() => setStep(4)}
          >
            SUBMIT FOR REVIEW
          </Button>
        </div>
      )}

      {/* Step 4: Background Check */}
      {step === 4 && (
        <div className="app-step app-step-loading">
          <h3 className="app-step-title">BACKGROUND CHECK</h3>
          <p className="app-loading-sub">Please wait while we process your application...</p>

          <div className="app-check-progress-track">
            <div
              className="app-check-progress-fill"
              style={{ width: `${progress}%` }}
            />
          </div>

          {!approved && (
            <p className="app-status-message">{STATUS_MESSAGES[statusIndex]}</p>
          )}

          {approved && (
            <div className="app-approved-container">
              <div className="app-approved-stamp">
                <CheckCircle size={40} />
                <span>APPROVED</span>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Step 5: Offer Letter */}
      {step === 5 && (
        <div className="app-step">
          <button className="app-back" onClick={() => setStep(3)} type="button">
            <ArrowLeft size={16} /> Back
          </button>
          <h3 className="app-step-title">OFFER LETTER</h3>

          <div className="app-offer-letter">
            <div className="app-offer-letterhead">
              <span className="app-offer-logo">FUCKCORPO INC.</span>
              <span className="app-offer-dept">Asset Liberation Division</span>
            </div>

            <div className="app-offer-body">
              <p>Dear <strong>{fullName || 'Valued Applicant'}</strong>,</p>
              <p>
                We are pleased to extend this offer of employment for the position of{' '}
                <strong>Chief Bathroom Revenue Officer</strong>.
              </p>
              <p>
                Based on your <strong>{experienceLabel || 'impressive'}</strong> years of bathroom experience
                and <strong>{motivation || 'unwavering'}</strong> assessment, we believe you will be an
                exceptional asset to our organization.
              </p>
              <p>Please confirm your compensation details below to finalize your offer:</p>
            </div>
          </div>

          <form className="app-form" onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label" htmlFor="offer-salary">Salary / Wage</label>
              <div className="form-row">
                <input
                  id="offer-salary"
                  className="form-input"
                  type="number"
                  min="0"
                  step="any"
                  placeholder="e.g. 75000"
                  value={salary}
                  onChange={(e) => setSalary(e.target.value)}
                  required
                />
                <select
                  className="form-select"
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

            <div className="form-row">
              <div className="form-group form-input">
                <label className="form-label" htmlFor="offer-currency">Currency</label>
                <select
                  id="offer-currency"
                  className="form-select"
                  value={currency}
                  onChange={(e) => setCurrency(e.target.value)}
                >
                  {CURRENCIES.map((c) => (
                    <option key={c} value={c}>{c}</option>
                  ))}
                </select>
              </div>
              <div className="form-group form-input">
                <label className="form-label" htmlFor="offer-industry">Industry</label>
                <select
                  id="offer-industry"
                  className="form-select"
                  value={industry}
                  onChange={(e) => setIndustry(e.target.value)}
                >
                  {INDUSTRIES.map((i) => (
                    <option key={i} value={i}>{i}</option>
                  ))}
                </select>
              </div>
            </div>

            <div className="form-group">
              <label className="form-label" htmlFor="offer-state">State / Region (optional)</label>
              <input
                id="offer-state"
                className="form-input"
                type="text"
                placeholder="e.g. California"
                value={stateRegion}
                onChange={(e) => setStateRegion(e.target.value)}
              />
            </div>

            <div className="form-submit-row">
              <Button type="submit" variant="primary" size="lg">
                ACCEPT OFFER &amp; BEGIN
              </Button>
              <p className="form-fine-print">
                By accepting, you agree to earn money while using the restroom.
              </p>
            </div>
          </form>
        </div>
      )}
    </Card>
  );
}
