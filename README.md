# Proxy Latency Filter

Este projeto é um script Python que baixa proxies da API **ProxyScrape**, mede a latência de cada proxy utilizando `ping` e salva os melhores proxies (com menor latência) em um arquivo de saída.

## Funcionalidades

- Obtém proxies HTTP/HTTPS da ProxyScrape.
- Mede a latência dos proxies utilizando o comando `ping`.
- Filtra os proxies com menor latência.
- Salva os proxies obtidos e filtrados em arquivos separados.

## Requisitos

- Python 3.7 ou superior
- Sistema operacional que suporte o comando `ping` no terminal.

## Instalação

1. Clone este repositório:
   ```bash
   git clone https://github.com/seu-usuario/proxy-latency-filter.git
   cd proxy-latency-filter
