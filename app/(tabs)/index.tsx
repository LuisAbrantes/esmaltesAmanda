import { useMemo, useState } from 'react';
import { FlatList, Pressable, StyleSheet, Text, TextInput, View } from 'react-native';

const polishes = [
  { id: '1', name: 'Ballet Slipper', brand: 'Risqué', color: 'Nude', finish: 'Cremoso' },
  { id: '2', name: 'Vinho Chic', brand: 'Impala', color: 'Vermelho', finish: 'Metalico' },
  { id: '3', name: 'Brisa Rosa', brand: 'Colorama', color: 'Rosa', finish: 'Cintilante' },
];

export default function CollectionScreen() {
  const [query, setQuery] = useState('');

  const filtered = useMemo(() => {
    const normalized = query.trim().toLowerCase();

    if (!normalized) return polishes;

    return polishes.filter(
      (item) =>
        item.name.toLowerCase().includes(normalized) ||
        item.brand.toLowerCase().includes(normalized) ||
        item.color.toLowerCase().includes(normalized)
    );
  }, [query]);

  return (
    <View style={styles.container}>
      <Text style={styles.title}>Coleção</Text>
      <Text style={styles.subtitle}>Organize esmaltes, marcas e fotos em um só lugar.</Text>

      <TextInput
        value={query}
        onChangeText={setQuery}
        placeholder="Buscar por nome ou marca"
        style={styles.search}
      />

      <View style={styles.metricsRow}>
        <Metric label="Na tela" value={filtered.length} />
        <Metric label="Marcas" value={new Set(polishes.map((item) => item.brand)).size} />
      </View>

      <FlatList
        data={filtered}
        keyExtractor={(item) => item.id}
        contentContainerStyle={styles.list}
        renderItem={({ item }) => (
          <Pressable style={styles.card}>
            <View style={styles.dot} />
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>{item.name}</Text>
              <Text style={styles.cardMeta}>
                {item.brand} • {item.color} • {item.finish}
              </Text>
            </View>
          </Pressable>
        )}
        ListEmptyComponent={<Text style={styles.empty}>Nenhum esmalte encontrado.</Text>}
      />
    </View>
  );
}

function Metric({ label, value }: { label: string; value: number }) {
  return (
    <View style={styles.metricCard}>
      <Text style={styles.metricValue}>{value}</Text>
      <Text style={styles.metricLabel}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#fff',
    padding: 20,
    paddingTop: 60,
  },
  title: { fontSize: 32, fontWeight: '900', color: '#111' },
  subtitle: { marginTop: 8, fontSize: 15, color: '#666', marginBottom: 18 },
  search: {
    backgroundColor: '#f2f2f2',
    borderRadius: 14,
    paddingHorizontal: 14,
    paddingVertical: 14,
    fontSize: 16,
  },
  metricsRow: { flexDirection: 'row', gap: 12, marginTop: 16, marginBottom: 12 },
  metricCard: {
    flex: 1,
    backgroundColor: '#FFF6FB',
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: '#F6D4E7',
  },
  metricValue: { fontSize: 24, fontWeight: '900', color: '#111' },
  metricLabel: { marginTop: 4, color: '#666' },
  list: { paddingTop: 8, paddingBottom: 40, gap: 12 },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    padding: 14,
    borderRadius: 18,
    backgroundColor: '#fff',
    borderWidth: 1,
    borderColor: '#eee',
  },
  dot: { width: 44, height: 44, borderRadius: 22, backgroundColor: '#FF1493' },
  cardTitle: { fontSize: 17, fontWeight: '800', color: '#111' },
  cardMeta: { marginTop: 2, color: '#666' },
  empty: { textAlign: 'center', color: '#777', marginTop: 28 },
});
