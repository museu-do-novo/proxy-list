# Proxy Tool

Ferramenta para coleta e análise de proxies públicos via linha de comando.

## 📦 Instalação
1. **Dependências**:
   - O script tenta instalar automaticamente as dependências necessárias (`curl`, `nping`, `nc`, `speedtest-go`) usando `apt`.
   - Caso a instalação automática falhe, o script sugere o comando manual para instalação.

2. **Download**:
   ```bash
   git clone https://github.com/seu-usuario/proxy-tool.git
   cd proxy-list
   chmod +x proxytool.sh
   ```

## 🚀 Funcionalidades
- **Coleta de Proxies**:
  - Suporta HTTP, SOCKS4, SOCKS5
  - Filtro por país
  - Customização de timeout

- **Análise**:
  - Verificação de ping (via `speedtest-go`)
  - Teste de portas abertas
  - Medição de velocidade de conexão (via `speedtest-go`)
  - Listagem detalhada

- **Saída**:
  - Exportação para arquivo
  - Mensagens coloridas
  - Tratamento de erros robusto

## 🛠 Uso
```bash
./proxytool.sh [OPÇÕES]
```

### Opções Principais
| Opção | Descrição                          | Exemplo               |
|-------|------------------------------------|-----------------------|
| `-o`  | Arquivo de saída                   | `-o meus_proxies.txt` |
| `-p`  | Protocolo (http, socks4, socks5)   | `-p socks5`           |
| `-t`  | Timeout em milissegundos           | `-t 10000`            |
| `-c`  | Filtrar por país (código ISO)      | `-c BR`               |
| `-P`  | Verificar portas abertas           | `-P`                  |
| `-S`  | Testar velocidade de conexão       | `-S`                  |
| `-l`  | Listar proxies encontrados         | `-l`                  |
| `-h`  | Ajuda                              | `-h`                  |

### Exemplos
1. **Coletar proxies SOCKS5 dos EUA**:
   ```bash
   ./proxytool.sh -p socks5 -c US
   ```

2. **Testar velocidade e portas**:
   ```bash
   ./proxytool.sh -PS -o fast_proxies.txt
   ```

3. **Listar proxies HTTP brasileiros**:
   ```bash
   ./proxytool.sh -p http -c BR -l
   ```

## 📝 Notas
- Proxies públicos podem ser instáveis: sempre verifique antes de usar.
- Para melhor performance, ajuste o timeout conforme sua conexão.
- Use `-P` e `-S` juntos para filtrar proxies rápidos e funcionais.
```

---

### Fluxo do Código

O script é modularizado em funções para facilitar a manutenção e o entendimento. Aqui está o fluxo principal:

---

#### 1. **Inicialização**
   - O script começa definindo variáveis globais, como cores para formatação, valores padrão e a URL da API de proxies.
   - Em seguida, ele processa os argumentos da linha de comando usando `getopts`.

---

#### 2. **Verificação de Dependências (`check_deps`)**
   - A função `check_deps` verifica se as dependências (`curl`, `nping`, `nc`, `speedtest-go`) estão instaladas.
   - Se alguma dependência estiver faltando:
     - Tenta instalá-la automaticamente usando `apt` (sem `sudo`).
     - Se a instalação automática falhar, exibe uma mensagem de erro e sugere o comando manual com `sudo`.

---

#### 3. **Coleta de Proxies (`fetch_proxies`)**
   - A função `fetch_proxies` faz uma requisição à API do ProxyScrape para obter uma lista de proxies.
   - Os proxies são salvos em um arquivo de texto (`output_file`).

---

#### 4. **Análise de Proxies (`check_proxy`)**
   - Para cada proxy na lista:
     - **Ping**: Usa o `speedtest-go` para verificar se o proxy está ativo.
     - **Portas**: Verifica se a porta do proxy está aberta (se a opção `-P` estiver habilitada).
     - **Velocidade**: Testa a velocidade de conexão usando o `speedtest-go` (se a opção `-S` estiver habilitada).

---

#### 5. **Listagem de Proxies (`list_proxies`)**
   - Se a opção `-l` estiver habilitada, o script lista todos os proxies encontrados, numerados.

---

#### 6. **Execução Principal (`main`)**
   - A função `main` orquestra o fluxo do script:
     1. Limpa a tela.
     2. Verifica dependências.
     3. Processa argumentos da linha de comando.
     4. Valida as entradas (protocolo, país, etc.).
     5. Baixa a lista de proxies.
     6. Analisa os proxies (se necessário).
     7. Lista os proxies (se necessário).
     8. Exibe uma mensagem de conclusão.

---

### Exemplo de Fluxo Completo

1. **Entrada do Usuário**:
   ```bash
   ./proxytool.sh -p socks5 -c US -PS -o fast_proxies.txt
   ```

2. **Fluxo**:
   - O script verifica as dependências. Se faltar algo, tenta instalar com `apt`.
   - Baixa uma lista de proxies SOCKS5 dos EUA e salva em `fast_proxies.txt`.
   - Para cada proxy:
     - Verifica o ping.
     - Testa a porta.
     - Mede a velocidade de conexão.
   - Exibe os resultados na tela.

3. **Saída**:
   ```
   Baixando proxies socks5 (US)...
   Proxies salvos em: fast_proxies.txt

   Proxy: 123.45.67.89:1080
   Ping OK
   Porta 1080 aberta
   Download: 12.34 Mbps
   Upload: 5.67 Mbps
   Ping: 45 ms

   Concluído!
   ```

---
