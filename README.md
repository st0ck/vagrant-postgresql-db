# vagrant-postgresql-db

Unfortunatelly, virtualbox still can't change size of the `.vmdk` boxes. Here is one of the workarounds for changing image size:

```
vagrant box add ubuntu/trusty64 --box-version 20150609.0.9
cd ~/.vagrant.d/boxes/ubuntu-VAGRANTSLASH-trusty64/20150609.0.9/virtualbox/
VBoxManage clonehd box-disk1.vmdk tmp-disk.vdi --format vdi
VBoxManage modifyhd tmp-disk.vdi --resize 61440
VBoxManage clonehd tmp-disk.vdi resized-disk.vmdk --format vmdk
rm tmp-disk.vdi box-disk1.vmdk
mv resized-disk.vmdk box-disk1.vmdk
```

For more information read [this issue](https://github.com/mitchellh/vagrant/issues/2339#issuecomment-112402297)
