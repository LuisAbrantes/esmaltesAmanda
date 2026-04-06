import { useState } from 'react';
import { Alert, ScrollView, StyleSheet, Text, TextInput, TouchableOpacity, View } from 'react-native';

export default function AddPolishScreen() {
  const [name, setName] = useState('');
  const [brand, setBrand] = useState('');
  const [notes, setNotes] = useState('');

  const handleSave = () => {
    Alert.alert('Em breve', 'O formulário está pronto para ligar ao Supabase.');
  };

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <Text style={styles.title}>Adicionar</Text>
      <Text style={styles.subtitle}>Cadastre um novo esmalte para a coleção.</Text>

      <Field label="Nome" value={name} onChangeText={setName} placeholder="Ex: Ballet Slipper" />
      <Field label="Marca" value={brand} onChangeText={setBrand} placeholder="Ex: Risqué" />
      <Field
        label="Notas"
        value={notes}
        onChangeText={setNotes}
        placeholder="Detalhes, contexto, combinações..."
        multiline
      />

      <TouchableOpacity style={styles.button} onPress={handleSave}>
        <Text style={styles.buttonText}>Salvar esmalte</Text>
      </TouchableOpacity>
    </ScrollView>
  );
}

function Field({
  label,
  value,
  onChangeText,
  placeholder,
  multiline,
}: {
  label: string;
  value: string;
  onChangeText: (text: string) => void;
  placeholder: string;
  multiline?: boolean;
}) {
  return (
    <View style={styles.fieldWrap}>
      <Text style={styles.label}>{label}</Text>
      <TextInput
        value={value}
        onChangeText={onChangeText}
        placeholder={placeholder}
        multiline={multiline}
        style={[styles.input, multiline && styles.multiline]}
      />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: '#fff',
    padding: 20,
    paddingTop: 60,
  },
  title: { fontSize: 32, fontWeight: '900', color: '#111' },
  subtitle: { marginTop: 8, marginBottom: 24, fontSize: 15, color: '#666' },
  fieldWrap: { marginBottom: 16 },
  label: { marginBottom: 8, fontWeight: '700', color: '#222' },
  input: {
    backgroundColor: '#f2f2f2',
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 14,
    fontSize: 16,
    minHeight: 52,
  },
  multiline: { minHeight: 120, textAlignVertical: 'top' },
  button: {
    marginTop: 10,
    backgroundColor: '#FF1493',
    paddingVertical: 16,
    borderRadius: 16,
    alignItems: 'center',
  },
  buttonText: { color: '#fff', fontSize: 16, fontWeight: '800' },
});
