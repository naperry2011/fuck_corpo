import { createContext, useContext, useReducer, useEffect } from 'react';
import { loadData, saveData } from '../utils/storage';
import { salaryToPerMinute } from '../utils/calculations';

const AppContext = createContext(null);

const initialState = loadData();

function reducer(state, action) {
  switch (action.type) {
    case 'SET_SALARY':
      return { ...state, salary: { ...state.salary, ...action.payload } };

    case 'ADD_BREAK':
      return { ...state, breaks: [...state.breaks, action.payload] };

    case 'DELETE_BREAK':
      return { ...state, breaks: state.breaks.filter((b) => b.id !== action.payload) };

    case 'UPDATE_SETTINGS':
      return { ...state, settings: { ...state.settings, ...action.payload } };

    case 'ADD_ACHIEVEMENT':
      if (state.achievements.includes(action.payload)) return state;
      return { ...state, achievements: [...state.achievements, action.payload] };

    case 'SET_ONBOARDED':
      return { ...state, onboarded: true };

    case 'IMPORT_DATA':
      return { ...loadData(), ...action.payload };

    case 'RESET':
      return loadData();

    default:
      return state;
  }
}

export function AppProvider({ children }) {
  const [state, dispatch] = useReducer(reducer, initialState);

  // Persist on every state change
  useEffect(() => {
    saveData(state);
  }, [state]);

  // Derived values
  const perMinuteRate = salaryToPerMinute(state.salary.amount, state.salary.type);

  const value = { state, dispatch, perMinuteRate };

  return <AppContext.Provider value={value}>{children}</AppContext.Provider>;
}

export function useApp() {
  const ctx = useContext(AppContext);
  if (!ctx) throw new Error('useApp must be used within AppProvider');
  return ctx;
}
