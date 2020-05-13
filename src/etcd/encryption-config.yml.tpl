apiVersion: v1
kind: EncryptionConfig
resources:
  - resources:
      - secrets
    providers:
      - identity: {}
      - aescbc:
          keys:
            - name: etcd_encryption_key
              secret: ${etcd_encryption_key}
