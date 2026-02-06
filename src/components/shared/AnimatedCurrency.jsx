import { useCountUp } from '../../hooks/useCountUp';
import { formatCurrency } from '../../utils/calculations';

export default function AnimatedCurrency({ value, currency = 'USD', className = '' }) {
  const animated = useCountUp(value, 1500, 2);
  return <span className={className}>{formatCurrency(animated, currency)}</span>;
}
