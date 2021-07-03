patch:
  pkg.installed

# Patch Salt to add namespace support to the Vault module.
# Added in https://github.com/saltstack/salt/pull/58586, so not
# available in Salt 3003.
vault_patch:
  file.patch:
    - name: '{{grains.saltpath}}'
    - source: salt://files/58586-vault-namespace.diff
    - strip: 2
