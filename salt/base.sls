{% set version = '1.7.3' %}

vault_cli:
  archive.extracted:
    - name: /tmp/vault-{{version}}
    - enforce_toplevel: False
    - source: 'https://releases.hashicorp.com/vault/{{version}}/vault_{{version}}_linux_amd64.zip'
    - source_hash: 'https://releases.hashicorp.com/vault/{{version}}/vault_{{version}}_SHA256SUMS'
    - unless: 'vault --version | grep {{version}}'
  file.managed:
    - name: /usr/local/bin/vault
    - source: /tmp/vault-{{version}}/vault
    - mode: '0755'
    - unless: 'vault --version | grep {{version}}'
    - require:
      - archive: vault_cli
