import {
    ScrollView,
    StyleSheet,
    Text,
    TouchableOpacity,
    View
} from 'react-native';

import { useAuth } from '../../src/providers/AuthProvider';

export default function ProfileScreen() {
    const { user, signOut } = useAuth();

    return (
        <ScrollView contentContainerStyle={styles.container}>
            <Text style={styles.title}>Perfil</Text>
            <Text style={styles.subtitle}>
                Configurações da conta e do catálogo.
            </Text>

            <View style={styles.card}>
                <Text style={styles.label}>Sessão ativa</Text>
                <Text style={styles.value}>
                    {user?.email ?? 'Sem usuário logado'}
                </Text>
            </View>

            <View style={styles.card}>
                <Text style={styles.label}>Checklist</Text>
                <Text style={styles.value}>• Auth direto por email</Text>
                <Text style={styles.value}>• Banco Supabase preservado</Text>
                <Text style={styles.value}>• UI pronta para ligar ao CRUD</Text>
            </View>

            <TouchableOpacity style={styles.button} onPress={signOut}>
                <Text style={styles.buttonText}>Sair</Text>
            </TouchableOpacity>
        </ScrollView>
    );
}

const styles = StyleSheet.create({
    container: {
        flexGrow: 1,
        backgroundColor: '#fff',
        padding: 20,
        paddingTop: 60
    },
    title: { fontSize: 32, fontWeight: '900', color: '#111' },
    subtitle: { marginTop: 8, marginBottom: 24, fontSize: 15, color: '#666' },
    card: {
        backgroundColor: '#FFF6FB',
        borderRadius: 18,
        padding: 16,
        borderWidth: 1,
        borderColor: '#F6D4E7',
        marginBottom: 14
    },
    label: { fontWeight: '800', marginBottom: 8, color: '#111' },
    value: { color: '#444', marginBottom: 4 },
    button: {
        marginTop: 8,
        backgroundColor: '#111',
        paddingVertical: 16,
        borderRadius: 16,
        alignItems: 'center'
    },
    buttonText: { color: '#fff', fontSize: 16, fontWeight: '800' }
});
