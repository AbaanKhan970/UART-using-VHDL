# UART-using-VHDL

**This repository contains a complete UART communication system implemented in VHDL for FPGA platforms. It includes:**

- **UART_RX**: Receives 8-bit serial data with start and stop bits (no parity).
- **UART_TX**: Transmits 8-bit serial data with one start and one stop bit.
- **Top_Loop**: Integrates both RX and TX modules to enable UART loopback. The received byte is displayed on two 7-segment displays (hex digits) and echoed back via UART.

### Features
- Baud Rate: 115200 (CLKS_PER_BIT = 217 for 25 MHz clock)
- Fully synchronous design
- Real-time display of received data on dual 7-segment displays
- Tested using Tera Term on a physical FPGA board

### Usage
Connect the FPGA's UART RX and TX pins to a USB-to-Serial adapter and open a terminal (e.g., Tera Term) at 115200 baud, 8N1, no flow control. Characters typed in the terminal will be echoed back and displayed on the FPGA's 7-segment displays.

---

