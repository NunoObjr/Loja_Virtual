# Loja Virtual

Aplicativo de **e-commerce em Flutter** com **Firebase**: catálogo de produtos, carrinho, checkout com **cartão de crédito**, acompanhamento de pedidos, lojas físicas no mapa e um **painel administrativo** para gerenciar produtos, pedidos e usuários.

## Funcionalidades

**Cliente**
- Cadastro e login (e-mail/senha e Facebook)
- Home dinâmica, composta por **seções** configuráveis (carrosséis e grades de itens)
- Catálogo de produtos com tamanhos, estoque e busca
- Carrinho, **endereço de entrega por CEP**, checkout e confirmação
- **Pedidos** com status (`preparing`, `transporting`, `delivered`, `canceled`), cancelamento e exportação do endereço
- **Lojas** com horário de funcionamento e abertura de rota no mapa
- Notificações push (Firebase Messaging)

**Administrador**
- Cadastro/edição de produtos (imagens com *crop*, tamanhos e preços)
- Edição das seções da home
- Gestão de pedidos de todos os clientes e lista de usuários

## Conceitos técnicos

**Provider + `ChangeNotifier`.** O estado é distribuído por *managers* (`UserManager`, `ProductManager`, `CartManager`, `CheckoutManager`, `OrdersManager`, `HomeManager`, `StoresManager`, `AdminOrdersManager`, `AdminUsersManager`), cada um responsável por um domínio e consumido pelas telas via `Provider`.

**Firebase como backend.**
- *Authentication* — login e sessão
- *Cloud Firestore* — produtos, pedidos, usuários, home e lojas
- *Cloud Storage* — imagens
- *Cloud Messaging* — notificações
- *Cloud Functions* — regras que não podem rodar no cliente

**Pagamento seguro com Cloud Functions.** Os dados do cartão são enviados a funções *callable* (`authorizeCreditCard`, `captureCreditCard`, `cancelCreditCard`) que falam com a **Cielo**. As credenciais do comerciante ficam em `functions.config()` no servidor, nunca no app. A cobrança é **autorizada** no checkout e **capturada** depois; o cancelamento do pedido estorna.

**Triggers do Firestore.** `onNewOrder` e `onOrderStatusChanged` reagem à criação e à mudança de status dos pedidos para notificar o cliente.

**Endereço por CEP e frete por distância.** `CepAbertoService` consulta a API CEP Aberto para preencher o endereço; em seguida o `CartManager` calcula o frete com `Geolocator.distanceBetween` (distância entre a loja e o endereço), somando um valor base e um valor por km ao total do pedido.

**Edição de conteúdo em tempo real.** A home e o catálogo são lidos do Firestore, então o administrador altera o app sem publicar nova versão.

## Stack

Flutter · Dart · Provider · Firebase (Auth, Firestore, Storage, Messaging, Functions) · Cloud Functions em TypeScript · Cielo · CEP Aberto · `geolocator` · `image_picker` / `image_cropper`

## Estrutura

```
lib/
  main.dart            # providers e rotas
  models/              # entidades e managers (estado)
  screens/             # telas: home, products, cart, checkout, order, stores, admin_*...
  services/            # cielo_payment.dart, cepaberto_service.dart
  common/              # widgets reutilizáveis (drawer, cards, diálogos)
  helpers/             # validadores, extensões, mensagens de erro do Firebase
functions/src/index.ts # Cloud Functions (cartão e pedidos)
```

## Como executar

1. Crie um projeto no [Firebase](https://console.firebase.google.com/) e configure o app Android/iOS (`google-services.json` / `GoogleService-Info.plist`).
2. Configure as credenciais da Cielo nas Functions:
   ```bash
   firebase functions:config:set cielo.merchantid="..." cielo.merchantkey="..."
   ```
3. Implante as funções e rode o app:
   ```bash
   cd functions && npm install && cd ..
   firebase deploy --only functions
   flutter pub get
   flutter run
   ```

As funções estão em modo **sandbox** da Cielo; ajuste em `functions/src/index.ts` para produção.

> **Segurança:** o token da API CEP Aberto está escrito em `lib/services/cepaberto_service.dart`. Revogue-o, gere outro e leia-o de variável de build (`--dart-define`) ou de uma Function.
