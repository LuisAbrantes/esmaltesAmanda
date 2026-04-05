# Arquitetura

## Stack

- iOS app em `SwiftUI`
- Estado com `Observation`
- `TabView` com `NavigationStack` por aba
- Backend em `Supabase`
- Fotos em `Supabase Storage`
- Auth por email magic link

## Modulos

- `App`: bootstrap, roteamento e injecao de dependencias
- `Core/Models`: tipos de dominio
- `Core/Services`: protocolos e orquestracao do estado global
- `Core/Data`: implementacoes de dados e bootstrap
- `Core/DesignSystem`: componentes de UI compartilhados
- `Features/Auth`
- `Features/Collection`
- `Features/PolishForm`
- `Features/PolishDetail`
- `Features/Profile`

## Fluxo de auth

1. App sobe e tenta restaurar sessao
2. Sem sessao, entra em `signedOut`
3. Login por magic link com Supabase Auth
4. O app trata o deep link `esmaltesamanda://login-callback` e tenta restaurar a sessao
5. Com sessao ativa, a usuaria carrega apenas seus registros
6. Logout limpa sessao e estado local

## Fluxo de dados

1. `AppModel` coordena auth, colecao e fotos
2. `PolishRepository` abstrai leitura/escrita de esmaltes
3. `PhotoStorageService` abstrai upload e leitura da foto principal
4. Views recebem `AppModel` e `TabRouter` via `@Environment`
5. Filtros sao aplicados no estado do app, sem duplicar a fonte de verdade

## Backend

- `profiles` espelha `auth.users`
- `brands`, `polishes`, `tags` e `polish_tags` pertencem a uma usuaria
- RLS em tudo que e user-owned
- Bucket `polish-photos` com caminho por usuaria e esmalte

## Decisoes tecnicas

- iOS minimo `17.0` para usar `Observation` e simplificar o projeto
- UI em PT-BR
- Estrutura preparada para multiplas usuarias desde o inicio
- Documentacao operacional obrigatoria para handoff entre IAs
- O bootstrap escolhe entre camada live do Supabase e fallback em memoria, para o app continuar abrindo mesmo se o package ainda nao estiver resolvido
- `supabase-swift` e a dependencia oficial prevista no projeto Xcode
- Em Apple Silicon, o build Debug de simulador deve evitar compilar a app em `x86_64` quando o package `Supabase` estiver sendo resolvido em `arm64`; essa compatibilidade local fica centralizada nas `xcconfig`
