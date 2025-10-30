# https://github.com/moroen/tradfricoap

wget https://go.dev/dl/go1.24.5.linux-arm64.tar.gz
sudo tar -C /usr/local -xzf ./go1.24.5.linux-arm64.tar.gz
echo 'export PATH="$PATH:/usr/local/go/bin"' >> ~/.zshrc
source ~/.zshrc

pip3 install tradfricoap