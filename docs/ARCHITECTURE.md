# Arquitetura

## Stack

- iOS app em `SwiftUI`
- Estado com `Observation`
- `TabView` com `NavigationStack` por aba
- Backend em `Supabase`
- Fotos em `Supabase Storage`
- Auth de Acesso via E-mail Direto (com senha pre-definida)

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
3. Login ou Criacao de conta integrados na mesma interface.
4. A tela de Acesso usa Email e uma senha pre-definida `DefaultAppPassword2026!` (hardcoded). O app tenta fazer Sign In, e se falhar (ex.: email nao existe), ele tenta fazer Sign Up. A intencao e ocultar a senha para a usuaria final, provendo acesso invisivel.
5. Com sessao ativa, a usuaria carrega apenas seus registros. O deep link/magic link foi removido por extrema simplificacao.

> **Extensibilidade**: Como o registro no Supabase usa as APIs nativas atrelando o User ao UUID normal em `auth.users`, adicionar suporte a senhas reais no futuro mantem retrocompatibilidade total. Bastara adicionar o campo `Password` na UI, remover a senha fixa e solicitar confirmacao por email.

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
