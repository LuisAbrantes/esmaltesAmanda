# Esmaltes Amanda

Aplicativo React Native com Expo para organizar a coleção de esmaltes da Amanda. O banco e as regras de acesso continuam no Supabase, com login direto por e-mail na v1.

## Como rodar

1. Instale as dependências:

   ```bash
   npm install
   ```

2. Crie um arquivo `.env` na raiz com:

   ```bash
   EXPO_PUBLIC_SUPABASE_URL=...
   EXPO_PUBLIC_SUPABASE_ANON_KEY=...
   ```

3. Inicie o app:

   ```bash
   npx expo start
   ```

4. Abra no celular com o app Expo Go ou emulador/simulador.

## Supabase

1. A migration principal segue em [supabase/migrations/20260405160000_initial_schema.sql](supabase/migrations/20260405160000_initial_schema.sql).
2. No dashboard do Supabase, desative a confirmação por e-mail em Authentication > Providers > Email.
3. Confirme também se o bucket `polish-photos` foi criado pela migration.

## Estrutura atual

- `app/`: rotas e telas do Expo Router
- `src/`: cliente Supabase e providers de estado
- `supabase/`: schema, RLS e storage
- `docs/`: arquitetura, backlog e status
