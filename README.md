# FireWatch – Monitoramento de Queimadas via Satélite
> Aplicativo mobile para monitoramento de focos de incêndio em tempo real com dados satelitais da NASA.

---

## Sobre o Projeto

O **FireWatch** consome dados da [NASA FIRMS API](https://firms.modaps.eosdis.nasa.gov/) para exibir focos de incêndio ativos em um mapa interativo. O app envia alertas automáticos quando focos são detectados próximos à localização do usuário, apoiando cidadãos, agricultores, bombeiros e a defesa civil.

Desenvolvido como parte da **Global Solution 2026 – FIAP**, com foco em soluções da economia espacial aplicadas ao monitoramento ambiental.

---

## Funcionalidades

- **Mapa interativo** com focos de incêndio em tempo real
- **Alertas por proximidade** (raio configurável de 10 a 200 km)
- **Dashboard** com estatísticas regionais e tendências
- **Filtros** por período (24h, 48h, 7 dias)
- **Denúncia de focos** com foto e localização GPS
- **Modo offline** com cache dos últimos dados

---

## Tecnologias

| Tecnologia | Versão |
|------------|--------|
| Flutter | 3.x |
| Dart | 3.x |
| NASA FIRMS API | - |
| Google Maps SDK | 2.x |
| BLoC | 8.x |
| sqflite | 2.x |

---

## Como Executar

### Pré-requisitos

- Flutter SDK 3.x instalado ([guia oficial](https://docs.flutter.dev/get-started/install))
- Android Studio ou VS Code com extensão Flutter
- Chave de API do Google Maps
- Chave de API da NASA FIRMS (gratuita em https://firms.modaps.eosdis.nasa.gov/api/)

### Passos

```bash
# 1. Clone o repositório
git clone https://github.com/gabmarki/firewatch-app.git
cd firewatch-app

# 2. Instale as dependências
flutter pub get

# 3. Configure as variáveis de ambiente

# 4. Execute o app
flutter run
```
---

## Estrutura do Projeto

```
lib/
├── core/
│   ├── constants/
│   ├── errors/
│   └── utils/
├── data/
│   ├── datasources/      # NASA FIRMS API, SQLite
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── blocs/
    ├── pages/
    │   ├── map/
    │   ├── dashboard/
    │   ├── alerts/
    │   └── report/
    └── widgets/
```

---

## Repositorio

https://github.com/gabmarki/firewatch-app

---

## Equipe

| Nome | RM |
|------|----|
| Gabriel Marki] | 558969 |

---
