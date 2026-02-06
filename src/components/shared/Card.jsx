import './Card.css';

export default function Card({ children, elevated, className = '', ...props }) {
  return (
    <div className={`card ${elevated ? 'card-elevated' : ''} ${className}`} {...props}>
      {children}
    </div>
  );
}
