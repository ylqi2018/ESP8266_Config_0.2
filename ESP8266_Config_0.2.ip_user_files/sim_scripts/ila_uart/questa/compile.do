vlib work
vlib msim

vlib msim/xil_defaultlib

vmap xil_defaultlib msim/xil_defaultlib

vcom -work xil_defaultlib -64 \
"../../../../ESP8266_Config_0.2.srcs/sources_1/ip/ila_uart/sim/ila_uart.vhd" \


