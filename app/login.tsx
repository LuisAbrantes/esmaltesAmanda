import {
    View,
    Text,
    TextInput,
    TouchableOpacity,
    StyleSheet,
    ActivityIndicator
} from 'react-native';
import { useState } from 'react';
import { useAuth } from '../src/providers/AuthProvider';

export default function LoginScreen() {
    const [email, setEmail] = useState('amanda@example.com');
    const [loading, setLoading] = useState(false);
    const [errorMsg, setErrorMsg] = useState('');
    const { signIn } = useAuth();

    const handleLogin = async () => {
        if (!email.includes('@')) {
            setErrorMsg('Digite um e-mail válido');
            return;
        }

        setLoading(true);
        setErrorMsg('');

        try {
            await signIn(email);
        } catch (e: any) {
            setErrorMsg(e.message || 'Erro ao tentar autenticar.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <View style={styles.container}>
            <Text style={styles.title}>Esmaltes da Amanda</Text>
            <Text style={styles.subtitle}>
                Uma coleção pessoal para organizar cores, marcas, acabamentos,
                fotos e lembranças.
            </Text>

            {errorMsg ? (
                <View style={styles.errorBox}>
                    <Text style={styles.errorText}>{errorMsg}</Text>
                </View>
            ) : null}

            <TextInput
                style={styles.input}
                placeholder="E-mail"
                value={email}
                onChangeText={setEmail}
                autoCapitalize="none"
                keyboardType="email-address"
                autoCorrect={false}
            />

            <TouchableOpacity
                style={[styles.button, loading && styles.buttonDisabled]}
                onPress={handleLogin}
                disabled={loading}
            >
                {loading ? (
                    <ActivityIndicator color="#fff" />
                ) : (
                    <Text style={styles.buttonText}>Entrar</Text>
                )}
            </TouchableOpacity>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        justifyContent: 'center',
        padding: 24,
        backgroundColor: '#fff'
    },
    title: {
        fontSize: 32,
        fontWeight: '900',
        color: '#1a1a1a',
        marginBottom: 8
    },
    subtitle: {
        fontSize: 16,
        color: '#666',
        marginBottom: 32,
        lineHeight: 24
    },
    input: {
        backgroundColor: '#f5f5f5',
        padding: 16,
        borderRadius: 12,
        fontSize: 16,
        marginBottom: 16,
        borderWidth: 1,
        borderColor: '#eee'
    },
    button: {
        backgroundColor: '#FF1493', // Um rosa mais forte parecido com AccentColor Apple
        padding: 16,
        borderRadius: 12,
        alignItems: 'center'
    },
    buttonDisabled: {
        opacity: 0.7
    },
    buttonText: {
        color: '#fff',
        fontSize: 16,
        fontWeight: 'bold'
    },
    errorBox: {
        backgroundColor: '#FFEBEE',
        padding: 12,
        borderRadius: 8,
        marginBottom: 16
    },
    errorText: {
        color: '#D8000C',
        fontSize: 14
    }
});
