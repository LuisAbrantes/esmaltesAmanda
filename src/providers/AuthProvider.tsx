import React, { createContext, useState, useEffect, useContext } from 'react';
import { Session, User } from '@supabase/supabase-js';
import { supabase } from '../lib/supabase';

type AuthContextType = {
    session: Session | null;
    user: User | null;
    signIn: (email: string) => Promise<void>;
    signOut: () => Promise<void>;
    isLoading: boolean;
};

const AuthContext = createContext<AuthContextType>({
    session: null,
    user: null,
    signIn: async () => {},
    signOut: async () => {},
    isLoading: true
});

export function AuthProvider({ children }: { children: React.ReactNode }) {
    const [session, setSession] = useState<Session | null>(null);
    const [user, setUser] = useState<User | null>(null);
    const [isLoading, setIsLoading] = useState(true);

    useEffect(() => {
        supabase.auth.getSession().then(({ data: { session } }) => {
            setSession(session);
            setUser(session?.user ?? null);
            setIsLoading(false);
        });

        const {
            data: { subscription }
        } = supabase.auth.onAuthStateChange((_event, session) => {
            setSession(session);
            setUser(session?.user ?? null);
            setIsLoading(false);
        });

        return () => {
            subscription.unsubscribe();
        };
    }, []);

    const signIn = async (email: string) => {
        // Senha fixa silenciosa para v1
        const hardcodedPassword = 'DefaultAppPassword2026!';

        const { error } = await supabase.auth.signInWithPassword({
            email,
            password: hardcodedPassword
        });

        if (error) {
            if (error.message.includes('Invalid login credentials')) {
                // Se nao existir, tentamos cadastrar
                const signUpRes = await supabase.auth.signUp({
                    email,
                    password: hardcodedPassword
                });

                if (signUpRes.error) {
                    throw new Error(
                        'Erro ao criar conta: ' + signUpRes.error.message
                    );
                }

                // Com "Confirm Email" desativado no Supabase e "autoRefreshToken",
                // o session ja vira preenchido. As vezes precisamos logar de novo.
                if (!signUpRes.data.session) {
                    await supabase.auth.signInWithPassword({
                        email,
                        password: hardcodedPassword
                    });
                }
            } else {
                throw error;
            }
        }
    };

    const signOut = async () => {
        await supabase.auth.signOut();
    };

    return (
        <AuthContext.Provider
            value={{ session, user, signIn, signOut, isLoading }}
        >
            {children}
        </AuthContext.Provider>
    );
}

export const useAuth = () => useContext(AuthContext);
