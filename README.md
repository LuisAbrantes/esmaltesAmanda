# Esmaltes Amanda

Aplicativo iOS em `SwiftUI` para organizar a colecao de esmaltes da Amanda com base pronta para evoluir para multiplas usuarias. O projeto nasce com shell moderno de iOS, documentacao de handoff entre IAs e backend planejado em Supabase com auth, RLS e storage.

## O que ja existe

- Projeto iOS base em `SwiftUI`, alvo `iOS 17+`
- Fluxo de autenticacao inicial
- Catalogo com busca, filtros, detalhe, cadastro e perfil
- Estrutura de backend em `supabase/migrations`
- Documentacao operacional em `docs/`
- Testes iniciais para filtros e repositório em memoria

## Como abrir

1. Duplicar `Config/Secrets.template.xcconfig` para `Config/Secrets.xcconfig`
2. Preencher `SUPABASE_URL`, `SUPABASE_ANON_KEY` e `SUPABASE_REDIRECT_URL`
3. Garantir que o Xcode resolva o package `https://github.com/supabase/supabase-swift.git`
4. Abrir [EsmaltesAmanda.xcodeproj](/Users/luisabrantes/Documents/Code/esmaltesAmanda/EsmaltesAmanda.xcodeproj)
5. Selecionar um simulador de iPhone com iOS 17 ou superior
6. Rodar o scheme `EsmaltesAmanda`

## Backend Supabase

1. Criar um projeto no Supabase
2. Habilitar Auth por email magic link
3. Adicionar `esmaltesamanda://login-callback` nas Redirect URLs do Auth
4. Aplicar a migration [20260405160000_initial_schema.sql](/Users/luisabrantes/Documents/Code/esmaltesAmanda/supabase/migrations/20260405160000_initial_schema.sql)
5. Revisar as politicas de storage do bucket `polish-photos`

## Convencoes

- Toda sessao deve ler `docs/PRD.md`, `docs/TASKS.md` e `docs/STATUS.md`
- Toda sessao deve atualizar `docs/WORKLOG.md` e `docs/STATUS.md`
- Se mudar fluxo, schema ou arquitetura, registrar tambem em `docs/ARCHITECTURE.md`

## Estrutura

- `EsmaltesAmanda/`: app iOS
- `EsmaltesAmandaTests/`: testes unitarios
- `Config/`: configuracao de build e segredos locais
- `supabase/`: schema, policies e material de backend
- `docs/`: PRD, arquitetura, backlog e handoff
