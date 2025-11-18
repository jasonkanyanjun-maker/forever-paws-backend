import { create } from 'zustand';
import { persist } from 'zustand/middleware';
import { Admin } from '@/types';

interface AuthState {
  admin: Admin | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (admin: Admin, token: string) => void;
  logout: () => void;
  setLoading: (loading: boolean) => void;
  updateAdmin: (admin: Partial<Admin>) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      admin: null,
      token: null,
      isAuthenticated: false,
      isLoading: false,

      login: (admin: Admin, token: string) => {
        localStorage.setItem('admin_token', token);
        set({
          admin,
          token,
          isAuthenticated: true,
          isLoading: false,
        });
      },

      logout: () => {
        localStorage.removeItem('admin_token');
        set({
          admin: null,
          token: null,
          isAuthenticated: false,
          isLoading: false,
        });
      },

      setLoading: (loading: boolean) => {
        set({ isLoading: loading });
      },

      updateAdmin: (adminUpdate: Partial<Admin>) => {
        const currentAdmin = get().admin;
        if (currentAdmin) {
          set({
            admin: { ...currentAdmin, ...adminUpdate },
          });
        }
      },
    }),
    {
      name: 'auth-storage',
      partialize: (state) => ({
        admin: state.admin,
        token: state.token,
        isAuthenticated: state.isAuthenticated,
      }),
    }
  )
);