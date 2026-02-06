import { useState, useEffect, useRef } from 'react';

function easeOutExpo(t) {
  return t === 1 ? 1 : 1 - Math.pow(2, -10 * t);
}

export function useCountUp(target, duration = 1500, decimals = 2) {
  const [value, setValue] = useState(0);
  const prevTarget = useRef(0);
  const rafRef = useRef(null);

  useEffect(() => {
    const from = prevTarget.current;
    const to = target;
    prevTarget.current = target;

    if (from === to) return;

    const startTime = performance.now();

    function animate(currentTime) {
      const elapsed = currentTime - startTime;
      const progress = Math.min(elapsed / duration, 1);
      const easedProgress = easeOutExpo(progress);
      const current = from + (to - from) * easedProgress;
      setValue(current);

      if (progress < 1) {
        rafRef.current = requestAnimationFrame(animate);
      }
    }

    rafRef.current = requestAnimationFrame(animate);
    return () => { if (rafRef.current) cancelAnimationFrame(rafRef.current); };
  }, [target, duration]);

  return decimals >= 0 ? Number(value.toFixed(decimals)) : value;
}
