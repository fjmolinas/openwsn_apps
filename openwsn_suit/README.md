# Overview

This example shows how to integrate SUIT-compliant firmware updates into a
RIOT application running on top of the OpenWSN network stack.

It implements basic support of the SUIT architecture using
the manifest format specified in [draft-ietf-suit-manifest-09](https://tools.ietf.org/id/draft-ietf-suit-manifest-09.txt).

**WARNING**: This code should not be considered production ready for the time being.
             It has not seen much exposure or security auditing.

Table of contents:

- [Prerequisites][prerequisites]
- [Setup][setup]
  - [Signing key management][key-management]
  - [Setup a wireless device behind a border router][setup-wireless]
    - [Provision the device][setup-wired-provision]
    - [Configure the wireless network][setup-wireless-network]
  - [Start aiocoap fileserver][start-aiocoap-fileserver]
- [Perform an update][update]
  - [Build and publish the firmware update][update-build-publish]
  - [Notify an update to the device][update-notify]
- [Detailed explanation][detailed-explanation]
- [Troubleshooting][troubleshooting]
- [Port Documentation][port-documentation]

## Prerequisites
[prerequisites]: #Prerequisites

- Install python dependencies (only Python3.6 and later is supported):

      $ pip3 install --user ed25519 pyasn1 cbor

- Install aiocoap from the source

      $ pip3 install --user --upgrade "git+https://github.com/chrysn/aiocoap#egg=aiocoap[all]"

  See the [aiocoap installation instructions](https://aiocoap.readthedocs.io/en/latest/installation.html)
  for more details.

- add `~/.local/bin` to PATH

  The aiocoap tools are installed to `~/.local/bin`. Either add
  "export `PATH=$PATH:~/.local/bin"` to your `~/.profile` and re-login, or execute
  that command *in every shell you use for this tutorial*.

- install openvisualizer

    This port currently needs `openvisualizer`, please make sure you follow the
    [pre-requisites](../../dist/tools/openvisualizer/makefile.openvisualizer.inc.mk) to install a patched version of `openvisualizer`.

## Setup
[setup]: #Setup

### Key Management
[key-management]: #Key-management

SUIT keys consist of a private and a public key file, stored in `$(SUIT_KEY_DIR)`.
Similar to how ssh names its keyfiles, the public key filename equals the
private key file, but has an extra `.pub` appended.

`SUIT_KEY_DIR` defaults to the `keys/` folder at the top of a RIOT checkout.

If the chosen key doesn't exist, it will be generated automatically.
That step can be done manually using the `suit/genkey` target.

### Setup a wireless device behind a border router
[setup-wireless]: #Setup-a-wireless-device-behind-a-border-router

#### Configure the wireless network

[setup-wireless-network]: #Configure-the-wireless-network

A wireless node has no direct connection to the Internet so a border router (BR)
between 802.15.4E and Ethernet must be configured.

An OpenWSN root node acts as a border router, it tunnels IEEE80215.4.E
between `openvisualizer` and the network without looking at the frame content.
This means that a root node will not be reachable when 'pinging' from the host
or if trying to send udp packets to it.

To set up a root node flash the [`openwsn_only`](../openwsn_only/README.md) application (this is another compagnion RIOT application, see doc
[here](../openwsn_only/README.md)):

    $ make -C openwsn_only/ flash -j3

Then launch openvisualizer, this can be done with make targets:

    $ make -C openwsn_only/ openv-termtun

Or manually from the command line with the `--opentun` argument.

    [MoteProbe:SUCCESS] Discovered serial-port(s): ['/dev/riot/tty-openmote-b_1']
    [OpenVisualizerServer:INFO] extracting firmware definitions.
    [Utils:VERBOSE] extracting firmware component names
    [Utils:VERBOSE] extracting firmware log descriptions.
    [Utils:VERBOSE] extracting 6top return codes.
    [Utils:VERBOSE] extracting 6top states.
    [OpenVisualizerServer:INFO] Setting DAG root...
    [OpenVisualizerServer:SUCCESS] Setting mote 7d12 as root
    [OpenVisualizerServer:INFO] starting RPC server
    [RPL:INFO] registering DAGroot ae-8d-fe-e1-e0-52-d7-d7

With this your Border Router is ready setup.

#### Configure the wireless network with a Vanilla OpenWSN border router

Optionally you can use a Vanilla OpenWSN border router but make sure that:

- The correct PANID is used (see [troubleshooting](troubleshooting))
- The same modules are enabled, the openwsn_suit application selects the
  following optional OpenWSN modules:
    - openwsn_6lo_fragmentation: this enable 6LoWPAN fragmentation
    - openwsn_adaptive_msf: allow the MSF algorithm to dynamically remove
    and allocate slots
- Channel hopping is by default enabled.

### Provision the device
[setup-wired-provision]: #Provision-the-device

In order to get a SUIT capable firmware onto the node, run

    $ make -C openwsn_suit clean flash -j4

This command also generates the cryptographic keys (private/public) used to
sign and verify the manifest and images. See the "Key generation" section in
[SUIT detailed explanation][detailed-explanation] for details.

In another terminal, run:

    $ make -C openwsn_suit/ term

### Start aiocoap-fileserver
[Start-aiocoap-fileserver]: #start-aiocoap-fileserver

`aiocoap-fileserver` is used for hosting the firmwares available for updates.
Devices retrieve the new firmware using the CoAP protocol.

Start `aiocoap-fileserver`:

    $ mkdir -p coaproot
    $ aiocoap-fileserver coaproot

Keep the server running in the terminal.

_NOTE_: `$(SUIT_COAP_FSROOT)` is set too `openwsn_suit/coaproot`, it must match
the location of above created directory, override accordingly if modified.

## Perform an update
[update]: #Perform-an-update

### Build and publish the firmware update
[update-build-publish]: #Build-and-publish-the-firmware-update

Currently, the build system assumes that it can publish files by simply copying
them to a configurable folder.

For this example, aiocoap-fileserver serves the files via CoAP.

- To publish an update for a device:

      $ SUIT_COAP_SERVER=[bbbb::1] make -C openwsn_suit suit/publish

This publishes into the server a new firmware for a samr21-xpro board. You should
see 6 pairs of messages indicating where (filepath) the file was published and
the corresponding coap resource URI

```
    ...
published "{PATH}/openwsn_suit/bin/openmote-b/suit-riot.suit_signed.latest.bin"
       as "coap://[bbbb::1]/fw/openmote-b/suit-riot.suit_signed.latest.bin"
published "{PATH}/openwsn_suit/bin/openmote-b/suit-slot0.1607611778.riot.bin"
       as "coap://[bbbb::1]/fw/openmote-b/suit-slot0.1607611778.riot.bin"
published "{PATH}/openwsn_suit/bin/openmote-b/suit-slot1.1607611778.riot.bin"
       as "coap://[bbbb::1]/fw/openmote-b/suit-slot1.1607611778.riot.bin"
    ...
```

### Notify an update to the device
[update-notify]: #Norify-an-update-to-the-device

Once a node has joined the network when issuing `ifconfig` you should see:

    ifconfig
    Iface  3      HWaddr: 0F:F4  NID: CA:FE

                Long HWaddr: 06:84:F6:65:10:6B:11:14
                inet6 addr: bbbb::684:f665:106b:1114

                IEEE802154E sync: 1
                6TiSCH joined: 1

                RPL rank: 2816
                RPL parent: 2A:BA:F7:65:10:6B:11:14
                RPL children:
                RPL DODAG ID: bbbb::2aba:f765:106b:1114

But a node is not reachable until the RPL root has received DAO's for such
node, something like

    [RPL:INFO] received RPL DAO from bbbb:0:0:0:ab8:fc65:106b:1114
        - parents:
        bbbb:0:0:0:2aba:f765:106b:1114
        - children:
        bbbb:0:0:0:684:f665:106b:1114

The node will be reachable by its inet6 address, which once joined should
be a global ipv6 address, in this case `bbbb::684:f665:106b:1114`, so
SUIT_CLIENT=[bbbb::684:f665:106b:1114].


- To trigger the update process issue the following command:

      $ SUIT_COAP_SERVER=[bbbb::1] SUIT_CLIENT=[bbbb::684:f665:106b:1114] make -C openwsn_suit suit/notify

This notifies the node of a new available manifest. Once the notification is
received by the device, it fetches it.

The device will hang for a couple of seconds when verifying the signature:

    ....
    suit_coap: got manifest with size 470
    suit: verifying manifest signature
    ....

Once the signature is validated it continues validating other parts of the
manifest.
Among these validations it checks some conditions like firmware offset position
in regards to the running slot to see witch firmware image to fetch.

    ....
    suit: validated manifest version
    )suit: validated sequence number
    )validating vendor ID
    Comparing 547d0d74-6d3a-5a92-9662-4881afd9407b to 547d0d74-6d3a-5a92-9662-4881afd9407b from manifest
    validating vendor ID: OK
    validating class id
    ....

Once the manifest validation is complete, the application fetches the image
and starts writing the incoming payload to the idle slot.
This step takes some time to fetch and write to flash. A progress bar is
displayed during this step:

    ....
    Fetching firmware |█████████████            |  50%
    ....

Once the new image is written, a final validation is performed and, in case of
success, the application reboots on the new slot:

    Finalizing payload store
    Verifying image digest
    Starting digest verification against image
    Install correct payload
    Verifying image digest
    Starting digest verification against image
    Install correct payload
    Image magic_number: 0x544f4952
    Image Version: 0x5fa52bcc
    Image start address: 0x00201400
    Header chksum: 0x53bb3d33
    suit_coap: rebooting...

    main(): This is RIOT! (Version: <version xx>))
    RIOT SUIT update example application
    Running from slot 1
    ...


The slot number should have changed from after the application reboots.
You can do the publish-notify sequence several times to verify this.

_NOTE_: if the device has a configured user button you can trigger an update by pressing such button.

## Detailed explanation
[detailed-explanation]: #Detailed-explanation

### Node

For the suit_update to work there are important modules that aren't normally built
in a RIOT application:

* riotboot
    * riotboot_flashwrite
* suit
    * suit_transport_coap

#### riotboot

To be able to receive updates, the firmware on the device needs a bootloader
that can decide from witch of the firmware images (new one and olds ones) to boot.

For suit updates you need at least two slots in the current conception on riotboot.
The flash memory will be divided in the following way:

```
|------------------------------- FLASH ------------------------------------------------------------|
|-RIOTBOOT_LEN-|------ RIOTBOOT_SLOT_SIZE (slot 0) ------|------ RIOTBOOT_SLOT_SIZE (slot 1) ------|
               |----- RIOTBOOT_HDR_LEN ------|           |----- RIOTBOOT_HDR_LEN ------|
 --------------------------------------------------------------------------------------------------|
|   riotboot   | riotboot_hdr_1 + filler (0) | slot_0_fw | riotboot_hdr_2 + filler (0) | slot_1_fw |
 --------------------------------------------------------------------------------------------------|
```

The riotboot part of the flash will not be changed during suit_updates but
be flashed a first time with at least one slot with suit_capable fw.

    $ make -C openwsn_suit clean flash

When calling make with the `flash` argument it will flash the bootloader
and then to slot0 a copy of the firmware you intend to build.

New images must be of course written to the inactive slot, the device mist be able
to boot from the previous image in case the update had some kind of error, eg:
the image corresponds to the wrong slot.

On boot the bootloader will check the `riotboot_hdr` and boot on the newest
image.

`riotboot_flashwrite` module is needed to be able to write the new firmware to
the inactive slot.

riotboot is not supported by all boards. The default board is `samr21-xpro`,
but any board supporting `riotboot`, `flashpage` and with 256kB of flash should
be able to run the demo.

#### suit

The suit module encloses all the other suit_related module. Formally this only
includes the `sys/suit` directory into the build system dirs.

- **suit_transport_coap**

To enable support for suit_updates over coap a new thread is created.
This thread will expose 4 suit related resources:

* /suit/slot/active: a resource that returns the number of their active slot
* /suit/slot/inactive: a resource that returns the number of their inactive slot
* /suit/trigger: this resource allows POST/PUT where the payload is assumed
tu be a url with the location of a manifest for a new firmware update on the
inactive slot.
* /suit/version: this resource is currently not implemented and return "NONE",
it should return the version of the application running on the device.

When a new manifest url is received on the trigger resource a message is resent
to the coap thread with the manifest's url. The thread will then fetch the
manifest by a block coap request to the specified url.

- **suit**

This includes manifest support. When a url is received in the /suit/trigger
coap resource it will trigger a coap blockwise fetch of the manifest. When this
manifest is received it will be parsed. The signature of the manifest will be
verified and then the rest of the manifest content. If the received manifest is valid it
will extract the url for the firmware location from the manifest.

It will then fetch the firmware, write it to the inactive slot and reboot the device.
Digest validation is done once all the firmware is written to flash.
From there the bootloader takes over, verifying the slot riotboot_hdr and boots
from the newest image.

#### Key Generation

To sign the manifest and for the device to verify the manifest a pair of keys
must be generated. Note that this is done automatically when building an
updatable RIOT image with `riotboot` or `suit/publish` make targets.

This is simply done using the `suit/genkey` make target:

    $ make -C openwsn_suit suit/genkey

You will get this message in the terminal:

    Generated public key: 'a0fc7fe714d0c81edccc50c9e3d9e6f9c72cc68c28990f235ede38e4553b4724'

### Server and file system variables

The following variables are defined in makefiles/suit.inc.mk:

    SUIT_COAP_BASEPATH ?= firmware/$(APPLICATION)/$(BOARD)
    SUIT_COAP_SERVER ?= localhost
    SUIT_COAP_ROOT ?= coap://$(SUIT_COAP_SERVER)/$(SUIT_COAP_BASEPATH)
    SUIT_COAP_FSROOT ?= $(RIOTBASE)/coaproot
    SUIT_PUB_HDR ?= $(BINDIR)/riotbuild/public_key.h

The following convention is used when naming a manifest

    SUIT_MANIFEST ?= $(BINDIR_APP)-riot.suitv3.$(APP_VER).bin
    SUIT_MANIFEST_LATEST ?= $(BINDIR_APP)-riot.suitv3.latest.bin
    SUIT_MANIFEST_SIGNED ?= $(BINDIR_APP)-riot.suitv3_signed.$(APP_VER).bin
    SUIT_MANIFEST_SIGNED_LATEST ?= $(BINDIR_APP)-riot.suitv3_signed.latest.bin

The following default values are using for generating the manifest:

    SUIT_VENDOR ?= "riot-os.org"
    SUIT_SEQNR ?= $(APP_VER)
    SUIT_CLASS ?= $(BOARD)
    SUIT_KEY ?= default
    SUIT_KEY_DIR ?= $(RIOTBASE)/keys
    SUIT_SEC ?= $(SUIT_KEY_DIR)/$(SUIT_KEY).pem

All files (both slot binaries, both manifests, copies of manifests with
"latest" instead of `$APP_VER` in riotboot build) are copied into the folder
`$(SUIT_COAP_FSROOT)/$(SUIT_COAP_BASEPATH)`. The manifests contain URLs to
`$(SUIT_COAP_ROOT)/*` and are signed that way.

The whole tree under `$(SUIT_COAP_FSROOT)` is expected to be served via CoAP
under `$(SUIT_COAP_ROOT)`. This can be done by e.g., `aiocoap-fileserver $(SUIT_COAP_FSROOT)`.

### Makefile recipes

The following recipes are defined in makefiles/suit.inc.mk:

#### suit/manifest

suit/manifest: creates a non signed and signed manifest, and also a latest tag for these.
    It uses following parameters:

    - $(SUIT_KEY): name of key to sign the manifest
    - $(SUIT_COAP_ROOT): coap root address
    - $(SUIT_CLASS)
    - $(SUIT_VERSION)
    - $(SUIT_VENDOR)

#### suit/publish

suit/publish: makes the suit manifest, `slot*` bin and publishes it to the
    aiocoap-fileserver

    1.- builds slot0 and slot1 bin's
    2.- builds manifest
    3.- creates $(SUIT_COAP_FSROOT)/$(SUIT_COAP_BASEPATH) directory
    4.- copy's binaries to $(SUIT_COAP_FSROOT)/$(SUIT_COAP_BASEPATH)
    - $(SUIT_COAP_ROOT): root url for the coap resources

#### suit/notify

suit/notify: triggers a device update, it sends two requests:

    1.- COAP get to check which slot is inactive on the device
    2.- COAP POST with the url where to fetch the latest manifest for
    the inactive slot

    - $(SUIT_CLIENT): define the client ipv6 address
    - $(SUIT_COAP_ROOT): root url for the coap resources
    - $(SUIT_NOTIFY_MANIFEST): name of the manifest to notify, `latest` by
    default.

#### suit/genkey

suit/genkey: this recipe generates a ed25519 key to sign the manifest

**NOTE**: to plugin a new server you would only have to change the suit/publish
recipe, respecting or adjusting to the naming conventions.**

### Troubleshooting
[troubleshooting]: #Troubleshooting

1. Vanilla OpenWSN nodes are not synchronizing

This might be because the PANID handling in Vanilla OpenWSN is inverted, this
means that if its set to `0xCAFE` the node actually interpreted as `0xFECA`.
The easiest way to handle this is to change the RIOT assigned PANID, so since
by default OpenWSN PANID is `0xCAFE` add to your Makefile application:

```
CFLAGS += -DOPENWSN_PANID=0xFECA
```

More troubleshooting tips are specified ini the RIOT Port Documentation [here](http://riot-os.org/api/group__pkg__openwsn.html).

### Port Documentation
[port-documentation]: #Port-Documentation

The OpenWSN RIOT port documentation is available [here](http://riot-os.org/api/group__pkg__openwsn.html)
