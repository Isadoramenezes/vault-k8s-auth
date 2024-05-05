ui = true
api_addr = "http://0.0.0.0:8200"
cluster_addr = "http://127.0.0.1:8201"

storage "raft" {
  path = "/opt/vault/raft/data"
  node_id = "vault-01"
}

listener "tcp" {
  address = "0.0.0.0:8200"
  tls_disable = 1
}

#listener "tcp" {
#  address       = "0.0.0.0:8200"
#  tls_cert_file = "/etc/vault.d/vault.crt"
#  tls_key_file  = "/etc/vault.d/vault.key"
#  tls_disable   = true
#}

# Enterprise license_path
# This will be required for enterprise as of v1.8
#license_path = "/etc/vault.d/vault.hclic"
