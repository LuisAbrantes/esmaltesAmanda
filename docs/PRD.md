# PRD - Esmaltes Amanda

## Visao do produto

App iOS para catalogar esmaltes de forma pessoal, visual e facil de consultar. O foco inicial e a Amanda, mas a base deve suportar multiplas usuarias no futuro sem reescrever auth, ownership ou regras de acesso.

## Problema

- Colecoes fisicas crescem rapido e ficam dificeis de lembrar
- Marcas e nomes se repetem visualmente
- Falta contexto sobre acabamento, tom, combinacoes e preferencia pessoal
- Sem organizacao, fica facil comprar repetido ou esquecer o que ja existe

## Persona principal

- Amanda, usuaria iPhone, quer uma colecao bonita e pratica
- Valoriza nome, cor, marca, acabamento, tags e foto
- Nao precisa de recursos sociais agora, mas quer algo que possa crescer depois

## Escopo v1

- Login/Cadastro unificados apenas com email (sem senha exposta na UI para maxima praticidade, mantendo uma senha forte oculta em codigo local).
- Onboarding direto
- Lista da colecao com busca e filtros
- Cadastro e edicao de esmalte
- Foto principal por esmalte
- Campos: nome, marca, familia de cor, tom, acabamento, tags, notas
- Tela de detalhe
- Perfil e estado da conta

## Fora da v1

- Wishlist
- Historico de uso
- Compartilhamento entre amigas
- Emprestimos
- Alertas de validade e estoque
- Scanner por imagem

## Criterios de sucesso

- Cadastrar e consultar esmaltes com poucos toques
- Encontrar um esmalte por nome, marca, tom ou acabamento
- Manter separacao de dados por usuaria no backend
- Deixar o projeto legivel para continuidade por outras IAs ou sessoes futuras

## Backlog v2+

- Favoritos com destaque na home
- Wishlist com preco e onde comprar
- Timeline de uso
- Emprestimos entre amigas
- Notificacoes e lembretes
- Importacao por foto/IA
