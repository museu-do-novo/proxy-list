#!/bin/bash

# ==============================================
# CONFIGURAÇÕES GLOBAIS
# ==============================================

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Valores Padrão
DEFAULT_OUTPUT="./proxies.txt"
DEFAULT_PROTOCOL="http"
DEFAULT_TIMEOUT="500"
DEFAULT_COUNTRY="all"
DEFAULT_PORT_CHECK="false"
DEFAULT_SPEED_TEST="false"
DEFAULT_PING_CHECK="false"
DEFAULT_CHECK_PROXIES="false"  # Verificação de proxies desativada por padrão
DEFAULT_LIST_PROXIES="true"   # Listagem de proxies desativada por padrão
API_URL="https://api.proxyscrape.com/v4/free-proxy-list/get"

# ==============================================
# FUNÇÕES
# ==============================================

show_help() {
    echo -e "${YELLOW}Uso: $0 [OPÇÕES]${NC}"
    echo "Opções:"
    echo "  -o <arquivo>    Saída (padrão: ${DEFAULT_OUTPUT})"
    echo "  -p <protocolo>  Protocolo (http, socks4, socks5) (padrão: ${DEFAULT_PROTOCOL})"
    echo "  -t <timeout>    Timeout em ms (padrão: ${DEFAULT_TIMEOUT})"
    echo "  -c <país>       Filtrar por país (ex: US, BR) (padrão: ${DEFAULT_COUNTRY})"
    echo "  -P              Verificar ping dos proxies"
    echo "  -S              Testar velocidade com speedtest-go"
    echo "  -C              Verificar proxies (ping, porta, velocidade)"
    echo "  -l              Listar proxies"
    echo "  -h              Ajuda"
    echo -e "\nExemplos:"
    echo "  $0 -p socks5 -c US -C"
    echo "  $0 -o fast_proxies.txt -t 10000 -l"
    exit 0
}

check_deps() {
    local deps=("curl" "nping" "nc" "speedtest-go")
    local missing_deps=()

    # Verifica se cada dependência está instalada
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            missing_deps+=("$dep")
        fi
    done

    # Se houver dependências faltando, tenta instalar com apt (sem sudo)
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        echo -e "${YELLOW}As seguintes dependências estão faltando:${NC}" >&2
        for dep in "${missing_deps[@]}"; do
            echo -e "${YELLOW}- ${dep}${NC}" >&2
        done

        echo -e "\n${GREEN}Tentando instalar as dependências com apt...${NC}" >&2
        if apt install -y "${missing_deps[@]}" &> /dev/null; then
            echo -e "${GREEN}Dependências instaladas com sucesso!${NC}" >&2
        else
            echo -e "${RED}Falha ao instalar as dependências.${NC}" >&2
            echo -e "\n${GREEN}Para instalar manualmente, execute:${NC}" >&2
            echo -e "${BLUE}sudo apt install -y ${missing_deps[*]}${NC}" >&2
            exit 1
        fi
    fi
}

fetch_proxies() {
    local params="request=display_proxies&protocol=${protocol}&proxy_format=protocolipport&format=text&timeout=${timeout}&country=${country}"
    local url="${API_URL}?${params}"
    
    echo -e "${BLUE}Baixando proxies ${protocol} (${country})...${NC}"
    
    if ! curl -s "$url" > "$output_file"; then
        echo -e "${RED}Falha ao baixar proxies!${NC}" >&2
        exit 1
    fi

    [[ $(wc -l < "$output_file") -eq 0 ]] && { echo -e "${RED}Nenhum proxy encontrado!${NC}"; exit 1; }
    echo -e "${GREEN}Proxies salvos em: ${output_file}${NC}"
}

check_port() {
    local proxy=$1
    local port=$2
    if nc -z -w 2 "$proxy" "$port" &> /dev/null; then
        echo -e "${GREEN}Porta ${port} aberta${NC}"
    else
        echo -e "${RED}Porta ${port} fechada${NC}"
    fi
}

test_speed() {
    local proxy=$1
    echo -e "\n${YELLOW}Testando velocidade via proxy: ${proxy}${NC}"
    
    # Executa o speedtest-go com proxy
    local result
    if ! result=$(speedtest-go --proxy="http://${proxy}" --json 2>&1); then
        echo -e "${RED}Falha ao executar speedtest-go!${NC}" >&2
        echo -e "${YELLOW}Detalhes: ${result}${NC}" >&2
        return
    fi

    # Processa o resultado
    local download=$(echo "$result" | jq -r '.download.bandwidth')
    local upload=$(echo "$result" | jq -r '.upload.bandwidth')
    local ping=$(echo "$result" | jq -r '.ping.latency')
    
    # Exibe os resultados
    echo -e "${BLUE}Download: $(echo "scale=2; $download / 125000" | bc) Mbps${NC}"
    echo -e "${BLUE}Upload: $(echo "scale=2; $upload / 125000" | bc) Mbps${NC}"
    echo -e "${BLUE}Ping: ${ping} ms${NC}"
}

check_ping() {
    local proxy=$1
    echo -e "\n${YELLOW}Verificando ping do proxy: ${proxy}${NC}"
    
    # Executa o speedtest-go para verificar o ping
    local result
    if ! result=$(speedtest-go --proxy="http://${proxy}" --ping-mode="http" --json 2>&1); then
        echo -e "${RED}Falha ao verificar ping!${NC}" >&2
        echo -e "${YELLOW}Detalhes: ${result}${NC}" >&2
        return
    fi

    # Processa o resultado
    local ping=$(echo "$result" | jq -r '.ping.latency')
    echo -e "${GREEN}Ping: ${ping} ms${NC}"
}

check_proxy() {
    local link=$1
    [[ -z "$link" ]] && return

    local proxy=$(echo "$link" | awk -F '//' '{print $2}')
    local host=${proxy%:*}
    local port=${proxy#*:}

    echo -e "\n${YELLOW}Proxy: ${host}:${port}${NC}"
    
    # Ping (opcional)
    [[ "$ping_check" == true ]] && check_ping "${host}:${port}"

    # Porta
    [[ "$check_port" == true ]] && check_port "$host" "$port"

    # Velocidade
    [[ "$speed_test" == true ]] && test_speed "${host}:${port}"
}

verify_proxies() {
    echo -e "${BLUE}Verificando proxies...${NC}"
    while read -r proxy; do
        check_proxy "$proxy"
    done < "$output_file"
}

list_proxies() {
    echo -e "\n${BLUE}Proxies encontrados (${protocol}):${NC}"
    cat -n "$output_file"
}

# ==============================================
# EXECUÇÃO PRINCIPAL
# ==============================================

main() {
    clear
    check_deps

    # Inicializa variáveis com valores padrão
    output_file="${DEFAULT_OUTPUT}"
    protocol="${DEFAULT_PROTOCOL}"
    timeout="${DEFAULT_TIMEOUT}"
    country="${DEFAULT_COUNTRY}"
    check_port="${DEFAULT_PORT_CHECK}"
    speed_test="${DEFAULT_SPEED_TEST}"
    ping_check="${DEFAULT_PING_CHECK}"
    check_proxies="${DEFAULT_CHECK_PROXIES}"
    list_proxies="${DEFAULT_LIST_PROXIES}"

    # Processar argumentos
    while getopts "o:p:t:c:PSClh" opt; do
        case "$opt" in
            o) output_file="${OPTARG:-${DEFAULT_OUTPUT}}" ;;
            p) protocol="${OPTARG:-${DEFAULT_PROTOCOL}}" ;;
            t) timeout="${OPTARG:-${DEFAULT_TIMEOUT}}" ;;
            c) country="${OPTARG:-${DEFAULT_COUNTRY}}" ;;
            P) ping_check=true ;;
            S) speed_test=true ;;
            C) check_proxies=true ;;
            l) list_proxies=true ;;
            h) show_help ;;
            *) echo -e "${RED}Opção inválida!${NC}"; exit 1 ;;
        esac
    done

    # Validações
    [[ ! "$protocol" =~ ^(http|socks4|socks5)$ ]] && { echo -e "${RED}Protocolo inválido!${NC}"; exit 1; }

    # Baixar proxies
    fetch_proxies

    # Verificar proxies (opcional)
    [[ "$check_proxies" == true ]] && verify_proxies

    # Listar proxies (opcional)
    [[ "$list_proxies" == true ]] && list_proxies

    echo -e "\n${GREEN}Concluído!${NC}"
}

# Executa o programa
main "$@"
