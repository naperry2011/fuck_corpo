import { X, CheckCircle, Info, Trophy, AlertTriangle } from 'lucide-react';
import './Toast.css';

const ICONS = {
  success: CheckCircle,
  info: Info,
  achievement: Trophy,
  warning: AlertTriangle,
};

export default function Toast({ toasts, onDismiss }) {
  if (toasts.length === 0) return null;

  return (
    <div className="toast-container" aria-live="polite">
      {toasts.map((toast) => {
        const Icon = ICONS[toast.type] || Info;
        return (
          <div
            key={toast.id}
            className={`toast toast-${toast.type} ${toast.exiting ? 'toast-exit' : 'toast-enter'}`}
            role="alert"
          >
            <Icon className="toast-icon" size={18} />
            <span className="toast-message">{toast.message}</span>
            <button
              className="toast-close"
              onClick={() => onDismiss(toast.id)}
              aria-label="Dismiss notification"
            >
              <X size={14} />
            </button>
          </div>
        );
      })}
    </div>
  );
}
