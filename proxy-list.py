import requests
import subprocess

def get_proxies(url):
    """Obtém a lista de proxies da ProxyScrape."""
    response = requests.get(url)
    if response.status_code == 200:
        proxies = response.text.strip().split('\n')
        with open("proxies.txt", "w") as file:
            file.write("\n".join(proxies))
        print(f"{len(proxies)} proxies salvos em 'proxies.txt'")
        return proxies
    else:
        print("Falha ao obter proxies.")
        return []

def test_proxy_latency(proxy):
    """Testa a latência de um proxy utilizando ping."""
    try:
        host, port = proxy.split(':')
        # Pinga o host para medir a latência
        result = subprocess.run(["ping", "-c", "1", host], capture_output=True, text=True, timeout=5)
        if "time=" in result.stdout:
            latency = float(result.stdout.split("time=")[-1].split(" ")[0])
            return latency
    except Exception as e:
        pass
    return float('inf')

def filter_proxies(proxies, count=10):
    """Filtra os proxies com menor latência."""
    filtered_proxies = sorted(proxies, key=test_proxy_latency)[:count]
    with open("filtered_proxies.txt", "w") as file:
        file.write("\n".join(filtered_proxies))
    print(f"{len(filtered_proxies)} proxies filtrados salvos em 'filtered_proxies.txt'")
    return filtered_proxies

if __name__ == "__main__":
    # URL do ProxyScrape
    url = "https://api.proxyscrape.com/?request=getproxies&proxytype=http&timeout=1000&country=all&ssl=all&anonymity=all"
    
    # Passos
    print("Obtendo proxies...")
    proxies = get_proxies(url)
    
    if proxies:
        print("Testando latência dos proxies...")
        best_proxies = filter_proxies(proxies)
        print("Processo concluído!")
    else:
        print("Nenhum proxy foi processado.")
