# name of your application
APPLICATION = suit

# If no BOARD is found in the environment, use this default:
BOARD ?= openmote-b

# This has to be the absolute path to the RIOT base directory:
RIOTBASE ?= $(CURDIR)/../RIOT

# Set this to 1 to enable code in RIOT that does safety checking
# which is not needed in a production environment but helps in the
# development process:
DEVELHELP ?= 1
# Change this to 0 show compiler invocation lines by default:
QUIET ?= 1

#
# OpenWSN spceficf stuff
#
USEPKG += openwsn
USEMODULE += openwsn_openstack
USEMODULE += openwsn_scheduler
USEMODULE += openwsn_6lo_fragmentation
USEMODULE += openwsn_adaptive_msf
# Optional Modules
USEMODULE += openwsn_leds
# Override OPENWSN default coap port to avoid potential conflicts
CFLAGS += -DOPENWSN_COAP_PORT_DEFAULT=5688
# Reduce threshold for adaptative msf to take place
CFLAGS += -DMSF_LIM_NUMCELLSUSED_HIGH=18
# Need to increasse COAP timeout since TiSCH latency can be quite high
CFLAGS += -DCONFIG_COAP_ACK_TIMEOUT=10
CFLAGS += -DCONFIG_COAP_MAX_RETRANSMIT=2

#
# SUIT update specific stuff
#
USEMODULE += nanocoap_sock sock_util
USEMODULE += suit suit_transport_coap suit_storage_flashwrite
# Shorten the manifest URL this will avoid fragmentation
# SUIT_MANIFEST_SIGNED_LATEST ?= latest.bin
# SUIT_NOTIFY_MANIFEST ?= latest.bin
# Default COAP manifest resource location when fetched through gpio trigger
CFLAGS += -DSUIT_MANIFEST_RESOURCE=\"$(SUIT_COAP_ROOT)/$(SUIT_NOTIFY_MANIFEST)\"
# If using openvisualizer this will the local endpoint
SUIT_COAP_SERVER ?= [bbbb::1]
SUIT_COAP_FSROOT ?= $(CURDIR)/coaproot

#
# Optional Modules
#
# Display a progress bar during firmware download
USEMODULE += progress_bar
# Optional feature to trigger suit update through gpio callback
FEATURES_OPTIONAL += periph_gpio_irq

#
# Other modules
#
# include this for printing IP addresses
USEMODULE += shell
USEMODULE += shell_commands
USEMODULE += ps

ifneq (,$(filter openwsn_serial,$(USEMODULE)))
# Uncomment to use STDIO_UART_DEV as the uart for OpenWSN openserial
# USEMODULE += stdio_null
  ifneq (,$(filter openmote-b,$(BOARD)))
    USEMODULE += stdio_null
  endif
endif

include $(RIOTBASE)/Makefile.include
