# TASKS

## Legenda

- `todo`
- `doing`
- `done`

## Backlog

- [x] `T001` Criar projeto iOS e estrutura base
  Status: `done`
  Owner: `Codex`
  Dependencias: nenhuma
  Definicao de pronto: projeto abre no Xcode com pasta organizada e build settings basicos

- [x] `T002` Adicionar configuracoes de ambiente e placeholders de segredo
  Status: `done`
  Owner: `Codex`
  Dependencias: `T001`
  Definicao de pronto: xcconfigs, Info.plist e template de secrets criados

- [x] `T003` Escrever `docs/PRD.md`
  Status: `done`
  Owner: `Codex`
  Dependencias: nenhuma
  Definicao de pronto: PRD com escopo v1, v2+, persona e metricas

- [x] `T004` Escrever `docs/ARCHITECTURE.md`
  Status: `done`
  Owner: `Codex`
  Dependencias: `T001`
  Definicao de pronto: arquitetura, modulos e fluxo de dados registrados

- [x] `T005` Criar `docs/TASKS.md`, `docs/STATUS.md`, `docs/WORKLOG.md`
  Status: `done`
  Owner: `Codex`
  Dependencias: nenhuma
  Definicao de pronto: backlog, status e log de sessoes prontos para uso

- [x] `T006` Configurar base do fluxo de autenticacao
  Status: `done`
  Owner: `Codex`
  Dependencias: `T001`, `T002`
  Definicao de pronto: onboarding/login e estado de sessao implementados com abstrações prontas para Supabase

- [x] `T007` Criar schema SQL inicial
  Status: `done`
  Owner: `Codex`
  Dependencias: `T003`, `T004`
  Definicao de pronto: migration com tabelas, indices e trigger

- [x] `T008` Configurar RLS e storage
  Status: `done`
  Owner: `Codex`
  Dependencias: `T007`
  Definicao de pronto: policies e bucket documentados em SQL

- [x] `T009` Implementar shell SwiftUI e roteamento
  Status: `done`
  Owner: `Codex`
  Dependencias: `T001`
  Definicao de pronto: `TabView` + `NavigationStack` por aba e rotas principais funcionando

- [x] `T010` Implementar fluxo de autenticacao
  Status: `done`
  Owner: `Codex`
  Dependencias: `T006`, `T009`
  Definicao de pronto: gate de sessao e tela de entrada ligadas ao estado global

- [x] `T011` Implementar listagem da colecao
  Status: `done`
  Owner: `Codex`
  Dependencias: `T009`
  Definicao de pronto: lista, resumo e estado vazio disponiveis

- [x] `T012` Implementar filtros e busca
  Status: `done`
  Owner: `Codex`
  Dependencias: `T011`
  Definicao de pronto: busca textual, filtros e ordenacao funcionando

- [x] `T013` Implementar formulario de esmalte
  Status: `done`
  Owner: `Codex`
  Dependencias: `T009`
  Definicao de pronto: criacao e edicao com validacoes basicas

- [x] `T014` Implementar upload de foto
  Status: `done`
  Owner: `Codex`
  Dependencias: `T013`
  Definicao de pronto: picker e servico de foto conectados na camada atual

- [x] `T015` Implementar tela de detalhe
  Status: `done`
  Owner: `Codex`
  Dependencias: `T011`, `T013`
  Definicao de pronto: detalhe, edicao e exclusao disponiveis

- [x] `T016` Criar testes unitarios iniciais
  Status: `done`
  Owner: `Codex`
  Dependencias: `T011`, `T012`, `T013`
  Definicao de pronto: cobertura inicial para filtros e repositório em memoria

- [ ] `T017` Conectar camada live do Supabase no app
  Status: `doing`
  Owner: `Codex`
  Dependencias: `T006`, `T007`, `T008`
  Definicao de pronto: auth, leitura/escrita e fotos passando pelo projeto Supabase real, com validacao em build e teste manual

- [ ] `T019` Corrigir erros de concorrencia e warnings em `SupabaseLive.swift`
  Status: `done`
  Owner: `Codex`
  Dependencias: `T017`
  Definicao de pronto: arquivo compila sem os erros de isolamento do actor principal e sem warnings de `try?` sem uso

- [x] `T020` Corrigir mismatch de arquitetura no build do simulador
  Status: `done`
  Owner: `Codex`
  Dependencias: `T017`
  Definicao de pronto: o target do app deixa de tentar compilar `x86_64` no simulador quando o package `Supabase` esta sendo gerado em `arm64`, permitindo validar o build Debug no Xcode

- [x] `T021` Corrigir configuracao de testes para `@testable import`
  Status: `done`
  Owner: `Codex`
  Dependencias: `T020`
  Definicao de pronto: `xcodebuild test` encontra o modulo `EsmaltesAmanda` no Debug do simulador sem falha de `Unable to find module dependency`

- [x] `T022` Exibir miniatura da foto na lista da colecao
  Status: `done`
  Owner: `Codex`
  Dependencias: `T013`, `T014`, `T015`
  Definicao de pronto: cada linha da colecao mostra a foto principal do esmalte na lateral esquerda, com fallback visual quando nao houver imagem

- [x] `T023` Corrigir injecao das credenciais do Supabase no app
  Status: `done`
  Owner: `Codex`
  Dependencias: `T017`
  Definicao de pronto: o bundle final expõe host, redirect e chave do projeto corretamente, sem truncar valores no `Info.plist`

- [ ] `T018` Polimento visual e backlog v2 priorizado
  Status: `todo`
  Owner: `Unassigned`
  Dependencias: `T011`, `T012`, `T013`, `T015`
  Definicao de pronto: empty/error states refinados e backlog v2 ordenado
