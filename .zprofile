
eval "$(/opt/homebrew/bin/brew shellenv zsh)"
export NODE_EXTRA_CA_CERTS="$(mkcert -CAROOT)/rootCA.pem"
export PATH="$PATH:/Users/chrisprzytocki/.dotnet/tools"
