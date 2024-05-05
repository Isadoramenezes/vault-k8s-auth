# Bonde pelo Rio Grande do Sul

O Rio Grande do Sul enfrenta uma tragédia sem precedentes com as cheias. Toda a solidariedade, ajuda e suporte são bem vindos. Para ajudar: https://www.instagram.com/p/C6g2f4XOpMP/?igsh=a3NiZjE4Z2J6OHI3.


## Habilitando Kubernetes Auth no Hashicorp Vault

Esse repo contem os manifestos e arquivos de configuração utilizados pra configurar o método de autenticação do Kubernetes.

Vault Docs: https://developer.hashicorp.com/vault/docs


## No Kubernetes

1. Service Account - Identidade do processo rodando em um pod, ela permite que as aplicações se identifiquem na API e obtenham acesso aos recursos que lhes cabem. Importante lembrar que após a versão 1.24 do kubernetes a criação de uma conta de serviço não cria um token automaticamente.

https://kubernetes.io/docs/concepts/security/service-accounts/

```
kubectl apply -f linuxtips-vault-sva.yml
kubectl get sa | grep linuxtips-vault
kubectl get sa linuxtips-vault -o json
```

2. Cluster Role Binding - É a associação de uma capacidade a uma conta de serviço.
https://kubernetes.io/docs/reference/access-authn-authz/rbac/

```
kubectl apply -f linuxtips-vault-crb.yml
kubectl get clusterrolebinding | grep role-tokenreview-binding
kubectl get clusterrolebinding -o wide | grep role-tokenreview-binding
```

3. Service Account Token - É o token relacionado com a service account.
https://kubernetes.io/docs/tasks/configure-pod-container/configure-service-account/#manually-create-a-long-lived-api-token-for-a-serviceaccount

```
kubectl apply -f linuxtips-vault-token.yml
kubectl describe secret linuxtips-vault
kubectl get secret linuxtips-vault -o json
```

## Instalar o Vault no Ubuntu 

https://developer.hashicorp.com/vault/tutorials/getting-started/getting-started-install
```
sudo apt update && sudo apt install gpg wget
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
gpg --no-default-keyring --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg --fingerprint
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install vault
```
## Criar a estrutura de diretorios para o raft
https://developer.hashicorp.com/vault/docs/configuration/storage/raft
```
mkdir -p /opt/vault/raft/data/
touch  /opt/vault/raft/data/vault.db
chown -R vault:vault /opt/vault/
chown -R vault:vault /opt/vault/raft/
```

## Inicializar o líder

*** Não faça isso em produção
```
export VAULT_ADDR=http://127.0.0.1:8200
vault operator init -key-shares=1 -key-threshold=1
vault operator unseal <key>
```

## Criar um Segredo e Uma policy

```
vault secrets enable kv
vault secrets list
vault kv put -mount=kv segredos/segredo-um segredo-um=essesopodeler
vault kv put -mount=kv segredos/segredo-dois segredo-dois=essepodeatualizar
vault policy write read-secrets segredos-policy.hcl
```

`vi segredos-policy`
```
path "kv/segredos/segredo-um" {
  capabilities = ["read", "list"]
}


path "kv/segredos/segredo-dois" {
  capabilities = ["read", "list", "update"]
}

```

## Habilitar e configurar o K8s Auth

```
vault auth enable kubernetes
export JWT_TOKEN=
export CA_CRT=
export K8S_HOST=

## Pra pegar o JWT e a CA
kubectl -n default get secret linuxtips-vault -o json | jq -r .data.token | base64 --decode
export JWT=< Content >
kubectl get secret linuxtips-vault -o json
echo -n "< Content>" | base64 --decode > ca.crt


export CA_CRT=$(cat ca.crt)

vault write auth/kubernetes/config \
        token_reviewer_jwt="$JWT_TOKEN" \
        kubernetes_host="$K8S_HOST" \
        kubernetes_ca_cert="$CA_CRT"


vault write auth/kubernetes/role/linuxtips \
        bound_service_account_names=linuxtips-vault \
        bound_service_account_namespaces='*' \
        policies=read-secrets \
        ttl=768h
```

## Rodar um pod de debug

```
kubectl apply -f pod.yml

kubectl get po

kubectl exec -it debug -- bash

export VAULT_ADDR=http://$VAULT_IP:8200

cat /var/run/secrets/kubernetes.io/serviceaccount/token/token

curl -s -kubectl --request POST --header "Content-Type: application/json" --data '{"jwt": "", "role": "linuxtips"}' http://$VAULT_IP:8200/v1/auth/kubernetes/login

curl -s --request GET --header "X-Vault-Token: "  http://$VAULT_IP:8200/v1/kv/segredos/segredo-um

curl -s --request POST --header "X-Vault-Token: <seu_token_vault>"  --header "Content-Type: application/json" --data '{"segredo-dois": "agora-e-outro-valor"}' http://$VAULT_IP:8200/v1/kv/segredos/segredo-dois
```