# Arquitetura

## Stack

- iOS/Android App em `React Native` (via `Expo`)
- Estado com `Context API` e Hooks padrao do React
- Navegacao baseada em diretorios com `Expo Router` (`app/`)
- Backend em `Supabase`
- Fotos em `Supabase Storage`
- Auth de Acesso via E-mail Direto (com senha pre-definida localmente)

## Modulos

- `src/lib/`: Instancias singleton do cliente web (`supabase.ts`)
- `src/components/`: Botoes genericos, modais, inputs de uso repetido
- `src/hooks/`: Controle de fetch das policies, cache de imagem local
- `app/`: Estrutura do App (shell, modais) usando file-based routing do Expo
    - `_layout.tsx`: Provider Global State Auth
    - `(tabs)/`: Menu principal
    - `login.tsx`: Area de Auth
    - `(modals)/`: Exbicao de tela de Editar Esmalte

## Fluxo de auth

1. App sobe e tenta restaurar sessao do Auth pelo `AsyncStorage` (provido pro supabase-js).
2. Sem sessao, o `_layout.tsx` barra o acesso e faz redirecionamento para `login.tsx`.
3. Login ou Criacao de conta integrados na mesma interface.
4. A tela de Acesso usa Email e uma senha pre-definida `DefaultAppPassword2026!` (hardcoded). O app tenta fazer Sign In, e se falhar (ex.: email nao existe), ele tenta fazer Sign Up. A intencao e ocultar a senha para a usuaria final, provendo acesso invisivel.
5. Com sessao ativa, a usuaria carrega apenas seus registros. O contexto provê as variaveis do perfil da conta.

> **Extensibilidade**: Como o registro no Supabase usa as APIs nativas atrelando o User ao UUID normal em `auth.users`, adicionar suporte a senhas reais no futuro mantem retrocompatibilidade total. Bastara adicionar o campo `Password` na UI, remover a senha fixa e solicitar confirmacao por email.

## Fluxo de dados

1. O App providencia um Context (`useAuth()`)
2. Views recuperam dados utilizando React local State (em versao posterior evoluido a algo como `React Query`).
3. Filtros sao aplicados no estado local via Memo(`useMemo`), sem pedir um request de search novo se os arrays ja estiverem completos.

## Backend

- `profiles` espelha `auth.users`
- `brands`, `polishes`, `tags` e `polish_tags` pertencem a uma usuaria
- RLS em tudo que e user-owned
- Bucket `polish-photos` com caminho por usuaria e esmalte

## Decisoes tecnicas

- Mudanca de Swift e Xcode para React Native/Expo para tirar vantagem de hot-reloading e facilidade do fluxo de entrega Web-like.
- Utilizar client `@supabase/supabase-js` em Typescript nativamente.
- O app suporta rodar direto no device da namorada lendo a URL do local dev server atravez do _Expo Go_, evitando burocracias de provisioning.
