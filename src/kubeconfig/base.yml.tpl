apiVersion: v1
kind: Config
current-context: ${kube_cluster_id}
preferences: {}
contexts:
  - name: ${kube_cluster_id}
    context:
      cluster: kubernetes
      user: ${kube_user}
clusters:
  - name: kubernetes
    cluster:
      server: ${kube_api_server}
      certificate-authority-data: ${kube_api_server_ca_certificate}
users:
  - name: ${kube_user}
    user:
      client-certificate-data: ${kube_user_certificate}
      client-key-data: ${kube_user_private_key}
