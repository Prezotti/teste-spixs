# Rota

App Flutter de roteirização de entregas. O usuário destrava o aparelho, informa os endereços, vê a ordem otimizada no mapa e navega até as paradas. Se sair do traçado, a rota dos pontos restantes é recalculada.

## Fluxo

1. **Bloqueio.** Face ID ou digital. Se não houver biometria, ou se a tentativa falhar ou for cancelada, dá para entrar com a senha ou o PIN do celular. Sem biometria e sem PIN, a tela de bloqueio não aparece.
2. **Localização.** O app pede permissão antes da home. "Agora não" segue sem GPS; a busca de endereço continua, só que sem viés de proximidade.
3. **Endereços.** Três campos obrigatórios e "Adicionar ponto" sem limite fixo. Tocar num campo abre a busca em tela cheia, com os endereços recentes até começar a digitar. Cada ponto extra pode ser removido. Só vale um endereço escolhido na lista, não texto livre.
4. **Rota otimizada.** A rota começa na localização atual, sem número. A Routes API reordena as entregas e os marcadores começam em 1.
5. **Navegação.** "Iniciar" abre o modo de curva a curva: banner da manobra, próximo destino, progresso "1 de N" e seta acompanhando o GPS.
6. **Recálculo.** Desvio confirmado gera uma rota nova só com as paradas que faltam. O banner laranja avisa o que aconteceu.

## Setup

Flutter stable 3.47, com Dart `^3.13` (ver `pubspec.yaml`). Android Studio ou Xcode para o dispositivo. O mapa nativo precisa de um emulador ou aparelho com Google Play Services. Sem isso os tiles não carregam, mesmo com a chave correta.

### Chave Google

No Google Cloud, ative:

- Places API (New)
- Routes API
- Maps SDK for Android
- Maps SDK for iOS

A chave fica fora do código. Copie o exemplo e preencha:

```bash
cp .env.example .env
```

```
GOOGLE_MAPS_API_KEY=sua_chave
```

`.env` está no `.gitignore`. Um `--dart-define=GOOGLE_MAPS_API_KEY=...` tem prioridade sobre o arquivo, o que permite CI ou um build sem depender do dotenv.

**Android.** O Gradle lê `../.env` e injeta a chave no `AndroidManifest` pelo placeholder `GOOGLE_MAPS_API_KEY`. Não há chave no manifest versionado.

**iOS.** Copie o exemplo e preencha a mesma chave:

```bash
cp ios/Flutter/MapsSecrets.xcconfig.example ios/Flutter/MapsSecrets.xcconfig
```

`Debug.xcconfig` e `Release.xcconfig` incluem esse arquivo com `#include?`, então o projeto abre mesmo sem ele. `MapsSecrets.xcconfig` não entra no git. O `Info.plist` lê `$(GOOGLE_MAPS_API_KEY)` e o `AppDelegate` entrega a chave ao Maps SDK.

### Rodar

```bash
flutter pub get
flutter run
```

Análise e testes locais:

```bash
flutter analyze
flutter test
```

### CI

O GitHub Actions (`.github/workflows/ci.yml`) roda em push na `main` e em pull request: `flutter analyze` e `flutter test`, no canal stable. O job copia `.env.example` para `.env` antes da análise, porque o `pubspec.yaml` declara esse arquivo como asset e o analyzer falha se ele não existir. A cópia está vazia. A chave real não vai para o CI, e os testes não chamam a API.

## Arquitetura

GetX para injeção, estado e navegação. Cada rota tem um `Bindings`. O que é compartilhado fica em `CoreBindings`, criado com o app.

```
Page (GetView)
  → Controller
    → Repository (interface no domain, impl no data)
      → Service (HTTP da API Google)
        → AppHttpClient
```

```
lib/
  core/
    config/          chave (.env ou dart-define)
    design/          cores, tipo, espaço, raio e widgets
    di/              CoreBindings
    errors/          NetworkException, PlacesException, DirectionsException
    location/        permissão e stream de GPS
    network/         HTTP com timeout
    routes/          rotas e páginas
  features/
    auth/            biometria
    location/        tela de permissão
    home/            endereços e Places
    route/           otimização, mapa e navegação
```

`core` não conhece uma feature. Places e Routes são registrados no binding da própria feature (`HomeBindings`, `RouteBindings`), não no core. `LocationPermissionService` e `AppHttpClient` ficam no core porque auth, home e rota usam os dois.

A tela não cria serviço. O binding registra a interface e a implementação. O controller pede a interface. Nos testes, o repositório falso entra direto no construtor, sem GetX.

| Rota | Binding | O que registra |
| --- | --- | --- |
| `/auth` | `AuthBindings` | `LocalAuthentication`, `AuthController` |
| `/location-permission` | `LocationBindings` | `LocationPermissionController` |
| `/home` | `HomeBindings` | Places service, `PlacesRepository`, recentes no Hive, `HomeController` |
| `/route` | `RouteBindings` | Routes service, `DirectionsRepository`, `RouteController` |

O HTTP só lança `NetworkException`. Cada service traduz isso para `PlacesException` ou `DirectionsException`. A tela mostra `error.message`. Timeout de 10 segundos. Falha de rede, resposta inválida e erro JSON da Google caem na mesma mensagem de "sem internet ou serviço indisponível", em vez do texto cru da API.

## Decisões técnicas

### Design system

Cores, tipo, espaço e raio vêm só de `lib/core/design` (`AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `UIText`, `UIPrimaryButton`, `UIPrimaryInput`). A tela de endereços segue o spec: fundo `surface100`, campos `surface200` com raio `md`, erro em `danger`, "Adicionar ponto" em `brand`, botão fixo inativo em `border` / `inkMuted`.

O modo de navegação não estava no spec escrito. Ele usa os mesmos tokens: banner verde `success`, recálculo `warning`, texto `onBrand`, card `surface200`, raio `lg`.

### Places API (New)

Autocomplete em `places.googleapis.com/v1/places:autocomplete`, não na API legada. Field mask curto, `languageCode` `pt-BR`, sessão por campo. A sessão fecha no Place Details, que é o modelo de cobrança da Google: várias sugestões e um detalhe contam como uma sessão.

A busca só dispara com 3 caracteres ou mais, com debounce de 400 ms. Uma resposta antiga é descartada se o usuário já digitou de novo. O viés é um círculo de 50 km em volta da posição atual, com `origin` para a API devolver `distanceMeters`. A lista é ordenada por essa distância.

O endereço escolhido fica numa lista de até 10 recentes, gravada com Hive. Na busca essa lista aparece enquanto não há uma consulta nova. Ao digitar, ela sai e entram as sugestões da API. Escolher um recente não chama a Places de novo.

### Routes API e a ordem otimizada

`computeRoutes` com `optimizeWaypointOrder`. A API só reordena waypoints intermediários, então o destino da requisição é a própria origem. Todas as paradas viram intermediários. A perna de volta até a origem é descartada na hora de somar distância, duração e polyline. A ordem exibida é a de `optimizedIntermediateWaypointIndex`, não a digitada.

O field mask pede duração, distância, polyline, a ordem otimizada e, na primeira perna, `navigationInstruction` para o texto da manobra em português.

Uma parada só, com origem GPS, é válida. Isso importa no recálculo, quando resta um único ponto.

### Mapa

O mapa é `google_maps_flutter`. A rota em si não vem do widget: o widget só desenha. O cálculo continua na Routes API.

O `GoogleMap` fica fora de `Obx`. Recriar o platform view a cada emissão derruba o mapa no emulador. Marcadores e a polyline atualizam por um `setState` estável quando a rota ou a posição mudam.

Os marcadores são círculos numerados na ordem otimizada, desenhados em bitmap. Na navegação, a seta usa a direção do GPS e a câmera aponta para o mesmo rumo, com a seta mais baixa na tela para mostrar o trecho à frente. O traço atrás da posição some; fica só o caminho que ainda falta. O ponto azul padrão do Maps fica desligado nesse modo, para não duplicar o usuário.

### Navegação e recálculo

Chegada: até 20 m da parada. Desvio: mais de 40 m da polyline, em duas leituras seguidas, com 20 s de intervalo entre chamadas da API. Leitura com precisão pior que 100 m não conta como chegada nem como desvio.

Enquanto a API responde, o banner mostra "Recalculando…". Sucesso vira "Rota recalculada" por 5 s e a linha fica tracejada em `warning`. Falha da API ou do GPS aparece no mesmo banner. Permissão negada e GPS desligado têm textos diferentes, e os dois são checados antes de abrir o stream.

O botão de volume alterna o ícone. Não há síntese de voz. O enunciado pedia o feedback visual do recálculo, não áudio.

### Bateria e GPS

O stream contínuo só existe depois de "Iniciar" e é cancelado ao encerrar, ao concluir as paradas ou ao descartar a tela.

| Momento | Comportamento |
| --- | --- |
| Busca de endereço | Última posição conhecida. Se não houver, uma leitura de precisão média com limite de 2 s. |
| Navegação no Android | Alta precisão, cerca de um ponto por segundo, depois de andar 5 m. |
| Navegação no iOS | Atualização a cada 5 m, pausa automática parado, sem update em background. |
| App em segundo plano | O stream é cancelado. Ao voltar, a navegação retoma. |
| Câmera | No máximo uma animação a cada 300 ms. O marcador continua atualizando a cada leitura válida. |

A navegação não continua com a tela desligada. Manter o GPS em background exigiria um serviço em primeiro plano e gastaria bateria sem o usuário olhando o mapa.

### Testes

Unitários cobrem a ordem da Routes API (incluindo o descarte da perna de volta), a polyline, o progresso na rota, a precisão do GPS, permissão negada, GPS desligado, recálculo, falha de API e a regra de "selecione um endereço da lista".

Widgets cobrem a tela de bloqueio, a home (três pontos, confirmar desligado, adicionar e remover) e a tela de permissão quando o usuário nega.

Não há teste de integração no dispositivo. Ele dependeria de Play Services, GPS e da chave, e o CI não tem nenhum dos três. O comportamento de navegação está no `RouteController`, com GPS e Routes API falsos.
