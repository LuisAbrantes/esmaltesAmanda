# WORKLOG

## 2026-04-05 - Codex

- Criado o bootstrap completo do projeto iOS a partir de um repositório vazio
- Implementadas as features centrais da v1 com dados em memoria: auth, colecao, filtros, formulario, detalhe e perfil
- Criado o schema inicial do Supabase com tabelas, trigger, indices, RLS, bucket e policies
- Criados `PRD.md`, `ARCHITECTURE.md`, `TASKS.md`, `STATUS.md` e `README.md`
- Pendencia principal registrada: ligar a camada live do Supabase nas abstrações do app
- `plutil -lint` confirmou `Info.plist` e `.pbxproj` validos
- `xcodebuild -list -project EsmaltesAmanda.xcodeproj` falhou por problema do ambiente Xcode (`xcodebuild -runFirstLaunch` sugerido pelo proprio tooling)
- `swiftc -typecheck` com SDK de simulador esbarrou na expansao de macro do `Observation` por restricoes do sandbox
- Implementada a primeira versao da camada live do Supabase com bootstrap condicional, deep link e servicos de auth, banco e storage
- Adicionada a dependencia oficial `supabase-swift` ao projeto Xcode
- Estado atualizado: integracao live escrita, mas ainda pendente de validacao com package resolvido e projeto Supabase real
- `xcodebuild -runFirstLaunch` executado com sucesso para destravar o conteudo inicial do Xcode
- `xcodebuild -resolvePackageDependencies -project EsmaltesAmanda.xcodeproj` executado com sucesso; `supabase-swift` resolvido em `2.43.0`
- API real do SDK inspecionada localmente para confirmar o uso de `session(from:)`, `signInWithOTP`, `upload(_:data:options:)` e `FileOptions`
- Build ainda bloqueado por ambiente: o Xcode atual nao encontrou destino/plataforma iOS utilizavel para o scheme
- Bugs reais reportados pelo Xcode em `SupabaseLive.swift` foram registrados antes de qualquer nova implementacao:
  `Call to main actor-isolated initializer 'init(client:configuration:)' in a synchronous nonisolated context`
  `Conformance of 'SupabaseAuthService' to protocol 'AuthServiceProtocol' crosses into main actor-isolated code and can cause data races`
  `Result of 'try?' is unused` (2 ocorrencias)
- Proxima sessao deve comecar por esses erros de concorrencia/isolation antes de continuar a integracao live
- Correcao implementada:
  `AuthServiceProtocol` anotado com `@MainActor`
  `SupabaseServiceFactory` anotada com `@MainActor`
  `SupabaseAuthService` mantida explicitamente em `@MainActor`
  retornos ignorados de `try?` em storage trocados por `_ = try? ...`
- Pendencia honesta: falta validar no Xcode se a lista de issues do arquivo realmente zerou
- Novo diagnostico registrado antes de qualquer nova implementacao:
  o uso de `supabase-swift` no codigo foi conferido contra a source real resolvida em `2.43.0` e esta consistente
  o build falha por mismatch de arquitetura no simulador, nao por API incorreta do Supabase
  o package compila em `arm64-apple-ios-simulator`, enquanto o target do app ainda tenta gerar `x86_64-apple-ios-simulator`
  a proxima correcao sera nas build settings de Debug do simulador
- Correcao aplicada para o build local em Apple Silicon:
  `Config/Debug.xcconfig` recebeu `ONLY_ACTIVE_ARCH = YES`
  `Config/Debug.xcconfig` recebeu `EXCLUDED_ARCHS[sdk=iphonesimulator*] = x86_64`
  o build foi validado com `xcodebuild` para `iPhone 16 / iOS 18.3.1 / arm64`
  resultado final da validacao: `BUILD SUCCEEDED`
- Nova validacao executada:
  `xcodebuild test` no mesmo simulador falhou por configuracao de testabilidade
  erro principal: `Unable to find module dependency: 'EsmaltesAmanda'`
  hipotese registrada antes da mudanca: falta `ENABLE_TESTABILITY = YES` no Debug para suportar `@testable import`
- Correcao aplicada para a suite de testes:
  `Config/Debug.xcconfig` recebeu `ENABLE_TESTABILITY = YES`
  a suite foi repetida com `xcodebuild test` no `iPhone 16 / iOS 18.3.1 / arm64`
  resultado final da validacao: `TEST SUCCEEDED` com 3 testes executados e 0 falhas
- Novo achado funcional registrado antes de editar UI:
  o workspace nao possui `Config/Secrets.xcconfig`
  por isso `SupabaseConfiguration.fromBundle()` retorna `nil`
  o bootstrap cai para `DemoAuthService`, `InMemoryPolishRepository` e `InMemoryPhotoStorageService`
  isso explica o login sem magic link real e o comportamento local sem rede
- Nova implementacao iniciada:
  exibir miniatura da foto principal na esquerda de cada item da colecao
- Implementacao concluida:
  `CollectionView.swift` agora renderiza um thumbnail compacto na esquerda de cada linha
  o thumbnail tenta carregar `photoPath` pelo `PhotoStorageService` atual e cai para um placeholder visual quando nao houver imagem
  validacao final:
  `xcodebuild ... build` concluiu com `BUILD SUCCEEDED`
  `xcodebuild ... test` concluiu com `TEST SUCCEEDED`
- Nova etapa iniciada:
  usuario forneceu URL e chave do projeto Supabase para sair do modo demo
  observacao registrada antes da mudanca: a chave recebida com prefixo `sb_secret_` parece uma secret key, nao a anon key publica recomendada para app cliente
- `Config/Secrets.xcconfig` foi criado com os valores recebidos
- Validacao com `xcodebuild -showBuildSettings` mostrou que os placeholders ainda estavam ativos
- Diagnostico registrado antes da correcao: `Base.xcconfig` inclui `Secrets.xcconfig` no topo, mas redefine `SUPABASE_URL` e `SUPABASE_ANON_KEY` depois, sobrescrevendo as credenciais reais
- `Base.xcconfig` foi corrigido para deixar `#include? "Secrets.xcconfig"` no final
- Nova validacao mostrou leitura parcial de `SUPABASE_URL` e `SUPABASE_REDIRECT_URL`
- Diagnostico registrado antes da proxima correcao: os valores com `:` em `Secrets.xcconfig` precisam estar entre aspas para o parser de xcconfig preservar a string completa
- Correcao aplicada:
  `Config/Secrets.xcconfig` agora envolve `SUPABASE_URL` e `SUPABASE_REDIRECT_URL` com aspas
  isso deve permitir que `xcodebuild` e o bundle exponham os valores completos para o bootstrap live do Supabase
- Validacao posterior mostrou que a tentativa com aspas e depois com `\:` ainda gera `Info.plist` truncado
- Nova decisao tecnica registrada antes da proxima implementacao:
  parar de transportar `https://...` e `scheme://...` diretamente via `xcconfig`
  usar componentes simples sem `:` no `xcconfig` e montar as URLs no `SupabaseConfiguration.fromBundle()`
- Implementacao concluida:
  `Config/Base.xcconfig` passou a usar `SUPABASE_PROJECT_HOST`, `SUPABASE_REDIRECT_SCHEME` e `SUPABASE_REDIRECT_HOST`
  `Config/Secrets.xcconfig` foi atualizado com os valores reais nesses novos campos
  `Info.plist` passou a expor os novos campos em vez de `SUPABASE_URL` e `SUPABASE_REDIRECT_URL`
  `SupabaseSupport.swift` agora monta `https://<host>` e `<scheme>://<host>` em codigo
- Validacao concluida:
  `xcodebuild -showBuildSettings` confirmou os quatro valores corretos no target
  `plutil -p` no `Info.plist` processado confirmou host, scheme, redirect host e chave completos
  `xcodebuild build` concluiu com `BUILD SUCCEEDED`
  `xcodebuild test` concluiu com `TEST SUCCEEDED`

## 2026-04-05 - Codex (Login Simplificado)

- A pedido do usuário, a autenticacao via Magic Link com deep link foi inteiramente substituida por uma abordagem "Login Simplificado" para a v1.
- Agora, a interface exige apenas "Email", e injeta via codigo uma senha forte para "signIn" silencioso que provê fallback para "signUp" imediato caso a conta não exista.
- Isso elimina o atrito do e-mail de confirmacao, assumindo ser usado via conta da Amanda para testes e uso real no comeco.
- Documentacoes `PRD.md`, `ARCHITECTURE.md`, `STATUS.md`, `README.md` e `TASKS.md` atualizadas marcando o abandono do deep link em favor da retrocompatibilidade garantida se houver necessidade real no futuro de incluir senha.
- Um script python gerou um ícone básico letra 'A' sob um fundo AccentColor rosa para o `AppIcon.appiconset`, preparando a build para morar na Home do telefone com estética adequada.
- Resolvidos os status pendentes no fluxo de testes, que seguem passando apos a remocao das passagens relacionadas a OTPs e "mail sent".

## 2026-04-05 - Codex (React Native Transition)

- Todo codebase iOS/Swift native jogado fora, abrindo o caminho para Expo. Em decorrência do baixo atrito para deploy web/lan local via Expo Go.
- `temp-app` instanciado com Typecript Tabs no lugar das pastas SwiftUI e `.xcodeproj`.
- `react-native-url-polyfill`, `@react-native-async-storage/async-storage` e `@supabase/supabase-js` instalados e configurados na raiz do novo source (`src/lib/supabase.ts`) usando as variables de ambiente Expo (`EXPO_PUBLIC_`).
- Os docs (`ARCHITECTURE.md` e `README.md`) receberam refactor para apagar fluxos em Obj-C/SwiftUI e contemplar React Context, `AsyncStorage` e `app/` file-based routing.
- O Supabase (`/supabase/migrations`) e negócio da aplicação seguem os mesmos inalteráveis, preservando a identidade da documentação construida até aqui.
