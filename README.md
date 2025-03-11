# BLE Scanner Plus

## Visão Geral

Este projeto foi desenvolvido para estudo do recurso Bluetooth Low Energy (BLE) em um aplicativo Flutter. Nele, demonstramos como escanear dispositivos BLE próximos, gerenciar as permissões necessárias, estimar a distância de um dispositivo com base no RSSI (Indicador de Intensidade de Sinal Recebido) e até reiniciar o app para atualizar seu estado.

## O que é BLE?

**Bluetooth Low Energy (BLE)** é uma tecnologia de comunicação sem fio projetada para baixo consumo de energia. Introduzido com o Bluetooth 4.0, ele é amplamente utilizado em:

- **Dispositivos IoT:** Sensores domésticos, monitoramento ambiental e dispositivos conectados.
- **Wearables:** Como rastreadores de fitness e relógios inteligentes.
- **Marketing de Proximidade e Navegação Interna:** Utilizando beacons para acionar ações baseadas na localização.
- **Aplicações Automotivas:** Para integração com sistemas embarcados.

O BLE é ideal para aplicações onde os dispositivos precisam funcionar por longos períodos com bateria e transmitir pequenas quantidades de dados de forma intermitente.

## Funcionalidades do Projeto

- **Escaneamento BLE:**  
  Utiliza o pacote [`flutter_blue_plus`](https://pub.dev/packages/flutter_blue_plus) para procurar dispositivos BLE próximos.

- **Gerenciamento de Permissões:**  
  Solicita e gerencia permissões de localização e de uso do Bluetooth por meio do pacote [`permission_handler`](https://pub.dev/packages/permission_handler).

- **Estimativa de Distância:**  
  Converte o valor de RSSI para uma distância estimada (em metros) usando uma fórmula empírica:
  
  \[
  \text{distância} = 10^\frac{(\text{TxPower} - \text{RSSI})}{10 \times n}
  \]
  
  Onde:
  - **TxPower** é o valor de RSSI medido a 1 metro (valor padrão: -59 dBm, podendo ser ajustado);
  - **n** é o expoente de perda do caminho (padrão: 2.0, típico para ambientes abertos).

- **Reinicialização do App:**  
  Implementa um botão para reiniciar o app usando o pacote [`flutter_phoenix`](https://pub.dev/packages/flutter_phoenix). Isso é útil para atualizar o estado interno do app (por exemplo, quando o Bluetooth é ligado após o app ser iniciado com ele desligado).

## Como o Projeto Funciona

1. **Inicialização:**  
   Ao iniciar, o app solicita as permissões necessárias (localização, scan e conexão Bluetooth). Após um breve atraso para garantir que o adaptador Bluetooth esteja pronto, o app inicia o escaneamento.

2. **Escaneamento:**  
   O app realiza o escaneamento por um período determinado e, para cada dispositivo encontrado, exibe:
   - Nome do dispositivo (se disponível);
   - ID do dispositivo;
   - Valor de RSSI (em dBm);
   - Distância estimada em metros (calculada a partir do RSSI).

3. **Exibição do Status e Reinicialização:**  
   Uma seção de status mostra, no topo da tela, se o Bluetooth, o GPS (serviço de localização) e as permissões estão ativos. Caso algum recurso não esteja ativo, o usuário pode reiniciar o app através do botão "Reiniciar App" para que o estado seja atualizado.

## Dependências

Certifique-se de incluir as seguintes dependências no seu arquivo `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_blue_plus: ^1.35.3
  permission_handler: ^11.4.0
  flutter_phoenix: ^1.0.0
