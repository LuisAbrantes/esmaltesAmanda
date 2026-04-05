# STATUS

## Ultima sessao

- Data: 2026-04-05
- Responsavel: Codex
- Estado geral: base do app criada a partir de um repositório vazio

## O que foi feito

- Projeto iOS inicial com app, testes, configs e assets
- Shell SwiftUI com autenticacao, colecao, formulario, detalhe e perfil
- Abstracoes de auth, repository e foto
- Implementacoes em memoria para permitir evolucao rapida
- Migration inicial do Supabase com schema, RLS, bucket e policies
- Documentacao operacional e de produto
- Integracao live do Supabase implementada em codigo com Auth, PostgREST, Storage e deep link
- Dependencia `supabase-swift` adicionada ao `.xcodeproj`
- Dependencia oficial resolvida com sucesso em `supabase-swift 2.43.0`
- API do SDK conferida localmente contra a versao resolvida para alinhar auth, session-from-url e storage upload
- Validacao estrutural do `Info.plist` e do `.pbxproj`
- Tentativa de validacao com `xcodebuild` e `swiftc` registrada com bloqueios de ambiente

## Onde parou

- O app agora tenta usar Supabase live quando houver config + package resolvido
- Se a SDK nao estiver resolvida, o bootstrap cai para fallback em memoria
- O package do Supabase ja esta resolvido e baixado
- A correcao dos erros de isolamento/warnings em `SupabaseLive.swift` ja foi aplicada no codigo
- O mismatch de arquitetura do simulador foi corrigido com ajuste no `Debug.xcconfig`
- A configuracao de testabilidade do Debug foi corrigida no `Debug.xcconfig`
- `xcodebuild build` e `xcodebuild test` agora passam em `platform=iOS Simulator,name=iPhone 16,OS=18.3.1,arch=arm64`
- O principal ponto pendente deixou de ser build/configuracao e voltou a ser validacao funcional contra o projeto Supabase real
- Diagnostico funcional importante: o workspace nao tem `Config/Secrets.xcconfig`, entao o app ainda esta em modo demo local e nao fala com o Supabase real neste momento
- A lista da colecao agora mostra a miniatura da foto principal do esmalte na lateral esquerda
- Credenciais reais do projeto Supabase foram recebidas para configurar a camada live no app
- A ordem de override em `Base.xcconfig` foi corrigida
- A configuracao do Supabase foi migrada para componentes seguros no `xcconfig`: host do projeto, redirect scheme e redirect host
- `SupabaseConfiguration.fromBundle()` agora monta `https://...` e `scheme://...` em codigo, evitando truncamento de `Info.plist`
- `xcodebuild build` e `xcodebuild test` continuam verdes apos a mudanca
- O `Info.plist` processado do app agora expoe `SUPABASE_PROJECT_HOST`, `SUPABASE_REDIRECT_SCHEME`, `SUPABASE_REDIRECT_HOST` e `SUPABASE_ANON_KEY` corretamente

## O que falta

- Validar auth por magic link, CRUD e upload/download de foto contra um projeto Supabase real
- Testar o fluxo real com `Secrets.xcconfig` preenchido: magic link, CRUD e upload de foto
- Conferir se a chave recebida e realmente uma anon key publica; o valor atual parece uma secret key e isso nao e ideal para app cliente
- Validar se o app realmente saiu do modo demo e entrou na camada live com as credenciais configuradas
- Verificar visualmente no app se o banner/estado saiu de demo e passou a refletir o modo live do Supabase

## Bugs documentados antes da proxima implementacao

- Arquivo: `EsmaltesAmanda/Core/Data/SupabaseLive.swift`
- Origem: lista de issues mostrada no Xcode em 2026-04-05
- Estado: corrigido em codigo e validado por build

Erros/warnings vistos:

- `Call to main actor-isolated initializer 'init(client:configuration:)' in a synchronous nonisolated context`
  Hipotese atual: `SupabaseServiceFactory.makeServices` instancia `SupabaseAuthService` fora de um contexto `@MainActor`, mas a classe foi marcada como `@MainActor`.
- `Conformance of 'SupabaseAuthService' to protocol 'AuthServiceProtocol' crosses into main actor-isolated code and can cause data races; this is an error in the Swift 6 language mode`
  Hipotese atual: `AuthServiceProtocol` nao esta anotado com `@MainActor`, mas a implementacao concreta esta.
- `Result of 'try?' is unused` (2 ocorrencias)
  Hipotese atual: chamadas com `try? await ...remove(...)` ou `try? await ...signOut()` estao sendo feitas sem capturar ou descartar explicitamente o retorno.

Implementacao aplicada nesta sessao:

- `AuthServiceProtocol` foi anotado com `@MainActor`
- `SupabaseServiceFactory` foi movida para `@MainActor`
- `SupabaseAuthService` foi mantido em `@MainActor` para isolamento explicito
- `try?` com retorno ignorado em operacoes de storage foi trocado por `_ = try? ...`

Validacao ainda pendente:

- Confirmar visualmente no Xcode que a issue list do arquivo tambem ficou limpa apos o rebuild

## Bug adicional reproduzido no build

- Arquivo visivel no erro: `EsmaltesAmanda/Core/Data/SupabaseLive.swift`
- Origem: tentativa de rodar o app no Xcode em 2026-04-05
- Estado: documentado antes da correcao

Erro visto:

- `Could not find module 'Supabase' for target 'x86_64-apple-ios-simulator'; found: arm64-apple-ios-simulator`
  Diagnostico atual: nao parece ser erro de uso da API do Supabase. O package `supabase-swift 2.43.0` foi inspecionado localmente e o codigo do app esta alinhado com `signInWithOTP`, `session(from:)` e `upload(_:data:options:)`. O problema reproduzido com `xcodebuild` foi de arquitetura: dependencias em `arm64` no simulador e target do app tambem tentando compilar slice `x86_64`.
  Correcao aplicada: `Config/Debug.xcconfig` passou a usar `ONLY_ACTIVE_ARCH = YES` e `EXCLUDED_ARCHS[sdk=iphonesimulator*] = x86_64`.
  Validacao: `xcodebuild -project EsmaltesAmanda.xcodeproj -scheme EsmaltesAmanda -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1,arch=arm64' build` concluiu com `BUILD SUCCEEDED`.

## Bug adicional reproduzido nos testes

- Arquivos visiveis no erro: `EsmaltesAmandaTests/FilterStateTests.swift` e `EsmaltesAmandaTests/InMemoryRepositoriesTests.swift`
- Origem: `xcodebuild test` em 2026-04-05
- Estado: documentado antes da correcao

Erro visto:

- `Unable to find module dependency: 'EsmaltesAmanda'`
  Diagnostico atual: o modulo do app foi compilado em Debug sem `-enable-testing`, o que impede `@testable import EsmaltesAmanda` nos testes.
  Correcao aplicada: `Config/Debug.xcconfig` passou a usar `ENABLE_TESTABILITY = YES`.
  Validacao: `xcodebuild -project EsmaltesAmanda.xcodeproj -scheme EsmaltesAmanda -destination 'platform=iOS Simulator,name=iPhone 16,OS=18.3.1,arch=arm64' test` concluiu com `TEST SUCCEEDED`.

## Riscos ou duvidas

- A camada live ja foi alinhada com a API da versao resolvida (`2.43.0`), mas ainda precisa de validacao real contra um projeto Supabase seu
- Sem `Config/Secrets.xcconfig`, o bootstrap usa `DemoAuthService`, `InMemoryPolishRepository` e `InMemoryPhotoStorageService`; esse nao parece mais ser o estado atual do workspace, mas continua sendo o fallback previsto
- A credencial enviada pelo usuario com prefixo `sb_secret_` parece ser uma chave secreta, nao a anon key publica normalmente usada em cliente iOS
- O sandbox atual tambem bloqueou a expansao de macro do `Observation` ao tentar typecheck por `swiftc`
- Como o projeto esta em Swift 6 mode no Xcode atual, erros de isolamento de concorrencia vao precisar de correcao limpa, nao apenas warning suppression
- Se esse workspace voltar a ser aberto num Mac Intel no futuro, a configuracao de arquitetura do simulador pode precisar ser revista
- Como as configs sao centralizadas em `xcconfig`, mudancas de Debug podem afetar app e testes ao mesmo tempo; isso e desejado aqui, mas deve ser lembrado em futuras alteracoes

## Proximo passo recomendado

- Abrir o app no simulador e validar o fluxo real do Supabase: login, sessao, CRUD e fotos
