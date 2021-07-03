# SaltStack and Vault HCP demo

Vault on the HashiCorp Cloud Platform runs Vault Enterprise, which requires a namespace for most operations.

[saltstack/salt#58586](https://github.com/saltstack/salt/pull/58586) added namespace capabilities to SaltStack's Vault module, which will be available in version 3004.
This repo demonstrates how to backport it to 3003.

# Setup

## Get a HCP Vault cluster

Sign up for the [HashiCorp Cloud Platform](https://portal.cloud.hashicorp.com/) and create a Vault Cluster.
Make sure to allow public access so it is reachable by the Vagrant boxes.

## Mount a KV secrets engine and create a secret

Login to the Vault UI and create a new KV secrets engine.
Use `kv` for the path and version 2.

Create a simple secret, e.g. `kv/user` with the values `name=test` and `password=hunter2`.

## Add Vault policies

These are basic policies that grant a lot of access by default.
For a production system, you may wish to create policies for different minion types.

Create a `salt-master` policy:

```hcl
path "auth/*" {
  capabilities = ["read", "list", "sudo", "create", "update", "delete"]
}
```

and a `saltstack/minions` policy:

```hcl
path "kv/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
```

The names of these policies must match the policy names in the Salt master's configuration.

## Create and provision the vagrant boxes

You'll need Vagrant and VirtualBox installed.
Feel free to tweak the `Vagrantfile` to work with your system.

Create the VMs, SSH into the master, and become root:

```bash
vagrant up
vagrant ssh master
sudo -i
```

Connect the minion and the master's minion to the master, then test they're connected:

```bash
salt-key -A

# The following keys are going to be accepted:
# Unaccepted Keys:
# master.local
# minion.local
# Proceed? [n/Y] y
# Key for minion master.local accepted.
# Key for minion minion.local accepted.

salt \* test.ping
```

Run a highstate on both machines:

```bash
salt \* state.apply
```

This will install the `vault` binary on both machines (for manual debugging), configure the master to use the Vault modules, and patch Salt to work with Vault namespaces.

Create a Vault token with the `salt-master` policy:

```bash
export VAULT_ADDR=https://<your-cluster>.aws.hashicorp.cloud:8200
export VAULT_NAMESPACE=admin

vault login
# (enter your admin token)

vault token create -policy salt-master
```

Update `/etc/salt/master.d/vault.conf` with your cluster's URL and the token you just generated.
Make sure the URL has no trailing slash.

Then restart the master and the minions:

```bash
vi /etc/salt/master.d/vault.conf

systemctl restart salt-master
# May need to wait a short while for the minions to reconnect

salt \* service.restart salt-minion
# May not return
```

# Grab secrets from Vault

We should now be ready to read secrets from Vault.

## With Salt

```bash
salt \* vault.read_secret kv/user

# minion.local:
#     ----------
#     name:
#         test
#     password:
#         hunter2
# master.local:
#     ----------
#     name:
#         test
#     password:
#         hunter2
```

```bash
salt \* vault.read_secret kv/user metadata=True

# minion.local:
#     ----------
#     data:
#         ----------
#         name:
#             test
#         password:
#             hunter2
#     metadata:
#         ----------
#         created_time:
#             2021-07-03T14:11:29.877306297Z
#         deletion_time:
#         destroyed:
#             False
#         version:
#             2
# master.local:
#     ----------
#     data:
#         ----------
#         name:
#             test
#         password:
#             hunter2
#     metadata:
#         ----------
#         created_time:
#             2021-07-03T14:11:29.877306297Z
#         deletion_time:
#         destroyed:
#             False
#         version:
#             2
```

Both the minion and the minion on the master should return the secret from Vault.

## With the Vault binary

```bash
vault login

vault kv get kv/user

# ====== Metadata ======
# Key              Value
# ---              -----
# created_time     2021-07-03T14:11:29.877306297Z
# deletion_time    n/a
# destroyed        false
# version          2
#
# ====== Data ======
# Key         Value
# ---         -----
# name        test
# password    hunter2
```

# Use the patch in your Salt environment

* Copy `salt/patch_salt.sls` to a location in your environment, e.g. `/srv/salt/vault/patch_namespaces.sls`
* Copy `salt/files/58586-vault-namespace.diff` too, e.g. `/srv/salt/vault/files/58586-vault-namespace.diff`
* Update the file path referenced in the state file:

```diff
  vault_patch:
    file.patch:
      - name: '{{grains.saltpath}}'
-     - source: salt://files/58586-vault-namespace.diff
+     - source: salt://vault/files/58586-vault-namespace.diff
      - strip: 2
```

* Run the state: `salt \* state.sls vault.patch_namespaces`
