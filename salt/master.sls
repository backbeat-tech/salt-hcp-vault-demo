master_vault_config:
  file.managed:
    - name: /etc/salt/master.d/vault.conf
    - source: salt://files/master_vault.conf
    # Won't overwrite your changes
    - replace: False

master_peer_run_config:
  file.managed:
    - name: /etc/salt/master.d/peer_run.conf
    - source: salt://files/peer_run.conf
