import { useCallback, useRef } from 'react';
import { useApp } from '../context/AppContext';

export default function useSound() {
  const { state } = useApp();
  const ctxRef = useRef(null);

  const getContext = useCallback(() => {
    if (!ctxRef.current || ctxRef.current.state === 'closed') {
      ctxRef.current = new (window.AudioContext || window.webkitAudioContext)();
    }
    if (ctxRef.current.state === 'suspended') {
      ctxRef.current.resume();
    }
    return ctxRef.current;
  }, []);

  const playTone = useCallback((ctx, frequency, startTime, duration, gain = 0.3) => {
    const osc = ctx.createOscillator();
    const gainNode = ctx.createGain();
    osc.type = 'sine';
    osc.frequency.value = frequency;
    gainNode.gain.setValueAtTime(0, startTime);
    gainNode.gain.linearRampToValueAtTime(gain, startTime + 0.01);
    gainNode.gain.exponentialRampToValueAtTime(0.001, startTime + duration);
    osc.connect(gainNode);
    gainNode.connect(ctx.destination);
    osc.start(startTime);
    osc.stop(startTime + duration);
  }, []);

  const chaChing = useCallback(() => {
    if (state.settings.soundEnabled === false) return;
    const ctx = getContext();
    const now = ctx.currentTime;
    playTone(ctx, 800, now, 0.1, 0.3);
    playTone(ctx, 1200, now + 0.12, 0.15, 0.3);
  }, [state.settings.soundEnabled, getContext, playTone]);

  const achievementSound = useCallback(() => {
    if (state.settings.soundEnabled === false) return;
    const ctx = getContext();
    const now = ctx.currentTime;
    playTone(ctx, 523, now, 0.15, 0.25);
    playTone(ctx, 659, now + 0.12, 0.15, 0.25);
    playTone(ctx, 784, now + 0.24, 0.2, 0.3);
  }, [state.settings.soundEnabled, getContext, playTone]);

  const soundEnabled = state.settings.soundEnabled !== false;

  return { chaChing, achievementSound, soundEnabled };
}
