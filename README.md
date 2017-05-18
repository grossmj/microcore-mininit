# microcore-mininit - stripped down Tiny Core Linux

Tiny Core Linux (http://tinycorelinux.net) is a very small and efficient
Linux distribution. But for use with GNS3 on a local Mac or Windows system
it's still relative slow, the linux-microcore-6.4 image takes about
25 seconds to boot. The reason is, that the qemu on those systems uses
the slow software virtualization.

microcore-mininit is a microcore variant with a stripped down initialization.
Additionally the IPv6 kernel modules, iproute2 and nano are added.
It boots in about 10s with the slow qemu of Mac / Windows.

But this results in a lower flexibility. For Linux (and GNS3 VM)
the normal microcore linux or a docker VM are better alternatives.


## Building the image

The image is downloadable from the GitHub releases area.

If you want to build it yourself, you need a linux system and install
packer (https://www.packer.io) and qemu.

Then build the image with
```
rm -rf output-qemu
packer build microcore-mininit.json
```


## Install the image in GNS3

As the image should run on the local system, the image can't be installed
as an appliance, it has to be installed manually.

* Copy the image to the GNS3/images/QEMU directory
* In GNS3 open the Qemu VM preferences
* With "New" start the Qemu VM template wizard
* Select "Run this Qemu VM on my local computer"
* Choose a name for the VM
* Select the Qemu binary (-i386 or -x86_64) and the RAM size  
  The RAM size can be as low as 64 MB
* Select the microcore-mininit.qcow2 disk image and finish the wizard
* Optionally modify the just created template
* Exit the preferences with "OK"

