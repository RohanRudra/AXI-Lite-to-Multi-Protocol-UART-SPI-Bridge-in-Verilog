# 🔗 Multi-Protocol AXI-Lite to UART/SPI Bridge

## 🧭 Overview
This project implements a **Multi-Protocol Communication Bridge** that allows a processor to dynamically switch between **UART** and **SPI** communication modes through an **AXI-Lite interface**.  
It serves as a configurable SoC peripheral that bridges high-level processor transactions (AXI-Lite) with low-level serial protocols (UART and SPI), enabling flexible data exchange with external devices.

The design is written entirely in **Verilog HDL** and functionally verified using **ModelSim**.

---

## ⚙️ Key Features
- **Dual-Protocol Support:** Seamless switching between UART and SPI communication without resynthesis.  
- **Memory-Mapped Control:** Fully software-configurable via AXI-Lite registers.  
- **Configurable Parameters:**
  - UART baud rate (e.g., 9600, 19200, 115200 bps, etc.)
  - SPI clock division and polarity/phase (CPOL, CPHA)
- **Full-Duplex Data Transfer:** Independent TX and RX paths for both protocols.
- **Synchronized Handshake:** Ensures valid data exchange between AXI domain and protocol-specific FSMs.
- **Status Monitoring:** Status register exposes `busy`, `tx_done`, and `rx_valid` flags to the software.
- **Modular Design:** Separate submodules for AXI-Lite, UART, SPI, and Control Unit, allowing easy extensibility.

---


---

## 🧠 Functional Description

### 1. **AXI-Lite Interface**
- Handles read/write transactions from the processor.  
- Maps control, configuration, and data registers for UART/SPI selection and operation.
- Synchronizes writes to prevent bus conflicts.

**Register Map Example:**
| Address | Register Name     | Description                              |
|----------|------------------|------------------------------------------|
| 0x00     | CONTROL          | Bit[0]: UART_TX_Start, Bit[1]: SPI_Start, Bit[2]: CPOL, CPHA   |
| 0x04     | STATUS           | Bit[0]: UART_TX_Busy,  Bit[1]: SPI_Done |
| 0x08     | UART_TX_DATA          | Byte to send via UART                   |
| 0x0C     | UART_RX_DATA          | Last received UART byte                            |
| 0x10     | SPI_TX_DATA         | Byte to send via SPI                |
| 0x14     | SPI_rX_DATA        | Last received SPI byte     |
| 0x18     | UART_BAUD   | Baud rate for UART(eg. 9600)  |
| 0x1C     | SPI_DIV     | Clock Divider value for SPI

---

### 2. **UART Core**
- Implements **start**, **data**, and **stop bit** framing.
- Baud generator divides the AXI clock to generate UART baud ticks.
- Supports full-duplex communication with buffering.

### 3. **SPI Core**
- Implements **SPI Master Mode** supporting both CPOL/CPHA combinations.
- Clock and data lines synchronized to selected SPI mode.
- Bit-indexed shift register ensures synchronized TX/RX transfers.

### 4. **Control Unit**
- Decodes AXI register writes and asserts the appropriate start signals.
- Routes TX/RX data to active protocol (UART or SPI).
- Updates the status register after each transaction.

---

## 🧪 Verification
The design was verified on **ModelSim** using a comprehensive testbench that:
- Performs AXI-Lite read/write transactions.
- Configures UART and SPI modes dynamically.
- Validates data transfer correctness and timing integrity.

✅ **Coverage Results:**
- 100% signal and timing coverage achieved.  
- Verified correct protocol switching without metastability.  
- Reliable full-duplex communication in both modes.

---



## 🧰 Tools Used
- **HDL:** Verilog  
- **Simulation:** ModelSim  
- **Synthesis (optional):** Vivado  
- **Interface Protocols:** AXI4-Lite, UART, SPI  

---

## 🚀 Future Enhancements
- Wrap the design into a **custom IP core** for Vivado integration.  
- Add **interrupt support** for TX/RX completion.  
- Extend to **I²C protocol** for tri-protocol support.  
- Hardware validation on FPGA (e.g., Artix-7 or Zynq board).

---

## 👨‍💻 Author
**Rohan Rudra**  
Designed and verified a multi-protocol AXI-Lite bridge enabling flexible serial communication in SoC environments.

---


