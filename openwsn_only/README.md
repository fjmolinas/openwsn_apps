# OpenWSN only Application

This application will setup a node that will only be running the OpenWSN
stack. This is ideal to use as an OpenWSN border router since no other
threads, ISR will interrupt the stack operation.

The application will by default include `openwsn_serial` and `stdio_null`,
so by default there will be no RIOT `stdio` output but only output
that [OpenVisualzier](https://github.com/openwsn-berkeley/openvisualizer) can
understand.

## Prerequisites

- install openvisualizer
    This port currently needs `openvisualizer`, please make sure you follow the
    [pre-requisites](../../dist/tools/openvisualizer/makefile.openvisualizer.inc.mk) to install a patched version of `openvisualizer`.

## Setup

To set up a root node flash the `openwsn_only` application:

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

## Comparison to OpenWSN Vanilla

Most optional features are disabled in Vanilla OpenWSN by default, in this
application we enable a few, as is seen in the
[Makefile](Makefile)

    - openwsn_6lo_fragmentation: this enable 6LoWPAN fragmentation
    - openwsn_adaptive_msf: allow the MSF algorithm to dynamically remove
    and allocate slots

### Troubleshooting

1. Vanilla OpenWSN nodes are not synchronizing

This might be because the PANID handling in Vanilla OpenWSN is inverted, this
means that if its set to `0xCAFE` the node actually interpreted as `0xFECA`.
The easiest way to handle this is to change the RIOT assigned PANID, so since
by default OpenWSN PANID is `0xCAFE` add to your Makefile application:

```
CFLAGS += -DOPENWSN_PANID=0xFECA
```

### Documentation

Please checkout the OpenWSN RIOT port documentation [here](http://riot-os.org/api/group__pkg__openwsn.html)
