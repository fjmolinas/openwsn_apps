## Initializing the repository:

RIOT is included as a submodule of this repository. We provide a `make` helper
target to initialize it.
From the root of this repository, issue the following command:

```
$ make init-submodules
```

### Building the firmwares:

From the root directory of this repository, simply issue the following command:

```
$ make
```

### Flashing the firmwares

For each firmware use the RIOT way of flashing them. For example, in
`openwsn_only`, use:

```
$ make -C openwsn_only flash
```
to flash the firmware on a `openmote-b` `BOARD`, if another `BOARD` is the target specify it in the command as:

```
$ BOARD=<BOARD> make -C openwsn_only flash
```

### Global cleanup of the generated firmwares

From the root directory of this repository, issue the following command:

```
$ make clean
```

