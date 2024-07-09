# OpenTofu Manifest for Provisioning Fedora CoreOS

### How to use

1. Create Iginition config for coreos

Refrence : https://docs.fedoraproject.org/en-US/fedora-coreos/producing-ign/

You can using example below

```yaml
variant: fcos
version: 1.5.0
passwd:
  users:
    - name: core
      ssh_authorized_keys:
        - ssh-rsa AAAA...
```

Save file to `example.bu` Then, generate `.ign` config for ignition

```sh
butane --pretty --strict example.bu > template.ign
```

2. Configure disk, network, etc

3. Provisioning with opentofu

```sh
tofu init # installing required provider
tofu plan
tofu apply # started provisioning

```