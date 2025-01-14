#!/bin/bash

# limpa a tela
clear; 

list=./proxyscrape.txt
url="https://api.proxyscrape.com/v4/free-proxy-list/get?request=display_proxies&protocol=http&proxy_format=protocolipport&format=text&timeout=1000"

# puxa a lista pela api do proxiscrape
if curl -s "$url" > "$list"; then
  echo "lista salva em: $list"
  cat "$list"
  else 
    echo "erro"
    exit 1;
fi

conferir_ping(){
        while read -r link; do 
        proxy=$(echo $link | awk -F '//' '{print $2}' | cut -d: -f1);
        echo "";
        echo "$link";
        ping -c 1 $proxy; done < $list
}

if [[ "$1" == "-c" ]]; then 
  conferir_ping
fi
    
