# Makefile from stlink example projects
# point $(STM32F4_LIBS) to stlink/example/stm32f4

EXECUTABLE=mr_radar.elf
BIN_IMAGE=mr_radar.bin

CC=arm-none-eabi-gcc
OBJCOPY=arm-none-eabi-objcopy

CFLAGS=-g -O2 -mlittle-endian -mthumb
CFLAGS+=-mcpu=cortex-m4
CFLAGS+=-ffreestanding -nostdlib

#usb_conf.h
CFLAGS+=-DUSE_USB_OTG_FS=1

# to run from FLASH
CFLAGS+=-Wl,-T,stm32_flash.ld

CFLAGS+=-I./

# stm32f4_discovery lib
CFLAGS+=-I$(STM32F4_LIBS)/STM32F4xx_StdPeriph_Driver/inc
CFLAGS+=-I$(STM32F4_LIBS)/STM32F4xx_StdPeriph_Driver/inc/device_support
CFLAGS+=-I$(STM32F4_LIBS)/STM32F4xx_StdPeriph_Driver/inc/core_support

#STM32F4xx_StdPeriph_Driver\inc
CFLAGS+=-I$(STM32F4_LIBS)/STM32F4xx_StdPeriph_Driver/inc

#Utilities
CFLAGS+=-I$(STM32F4_LIBS)/Utilities/STM32F4-Discovery

all: $(BIN_IMAGE)

$(BIN_IMAGE): $(EXECUTABLE)
	$(OBJCOPY) -O binary $^ $@

$(EXECUTABLE): main.c system_stm32f4xx.c startup_stm32f4xx.s stm32f4xx_it.c \
	$(STM32F4_LIBS)/Utilities/STM32F4-Discovery/stm32f4_discovery.c \

		
	$(CC) $(CFLAGS) $^ -o $@  -L$(STM32F4_LIBS)/STM32F4xx_StdPeriph_Driver/build -lSTM32F4xx_StdPeriph_Driver -L$(STM32F4_LIBS)/STM32F_USB_OTG_Driver/build

clean:
	rm -rf $(EXECUTABLE)
	rm -rf $(BIN_IMAGE)

.PHONY: all clean
