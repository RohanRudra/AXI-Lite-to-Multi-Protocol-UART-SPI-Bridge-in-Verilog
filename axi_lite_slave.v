module AXILite_slave_if #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
) (
    //Global signals
    input                       ACLK, ARESETn,

    //Write Address Channel
    input [ADDR_WIDTH-1:0]      S_AXI_AWADDR,
    input                       S_AXI_AWVALID, 
    output                      S_AXI_AWREADY,

    //Write Data Channel
    input [DATA_WIDTH-1:0]      S_AXI_WDATA,
    input [3:0]                 S_AXI_WSTRB,
    input                       S_AXI_WVALID,
    output                      S_AXI_WREADY,

    //Write Response Channel
    output reg [1:0]            S_AXI_BRESP,
    output reg                  S_AXI_BVALID,
    input                       S_AXI_BREADY,  

    //Read Address Channel
    input [ADDR_WIDTH-1:0]      S_AXI_ARADDR,
    input                       S_AXI_ARVALID,
    output                      S_AXI_ARREADY,

    //Read Data Channel
    output reg [DATA_WIDTH-1:0] S_AXI_RDATA,
    output reg [1:0]            S_AXI_RRESP,
    output reg                  S_AXI_RVALID,
    input                       S_AXI_RREADY,

    // AXI <-> UART control signals
    output [DATA_WIDTH-1:0]  control_reg,
    input [DATA_WIDTH-1:0]  status_reg,
    output [7:0]  tx_uart,
    input [7:0]  rx_uart,
    output [7:0] tx_spi,
    input [7:0] rx_spi,
    output [31:0] uart_baud,
    output [31:0] spi_div
);

    assign S_AXI_ARREADY = 1'b1;
    assign S_AXI_AWREADY = 1'b1;
    assign S_AXI_WREADY = 1'b1;

    reg [DATA_WIDTH-1:0] mem [0:7]; // 8 x 32-bit memory

    //Write Operation
    integer i;
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            
            for (i = 0; i < 8; i = i+1) begin
                mem[i] <= 0;
            end
            S_AXI_BRESP <= 2'b00;
            S_AXI_BVALID <= 1'b0;
        end
        else begin
            if (S_AXI_AWVALID && S_AXI_WVALID) begin
                mem[S_AXI_AWADDR[4:2]] <= S_AXI_WDATA;

                S_AXI_BVALID <= 1'b1;  //Indicate write response is valid
                S_AXI_BRESP <= 2'b00; // OKAY response
            end
            else if (S_AXI_BREADY) begin 
                S_AXI_BVALID <= 1'b0; //Clear write response valid flag
            end
        end
    end

    //Read Operation
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            S_AXI_RVALID <= 1'b0;
            S_AXI_RRESP <= 2'b00;
            S_AXI_RDATA <= 0;
        end
        else begin
            if (S_AXI_ARVALID) begin
                S_AXI_RDATA <= mem[S_AXI_ARADDR[4:2]];
                S_AXI_RVALID <= 1'b1; //Indicate read data is valid
                S_AXI_RRESP <= 2'b00; // OKAY response
            end
            else if (S_AXI_RREADY) begin
                S_AXI_RVALID <= 1'b0; //Clear read data valid flag
            end
        end
    end


    // 0x00	CONTROL	        [0] UART_TX_START, [1] SPI_START, [2] SPI_CPOL, [3] SPI_CPHA
    // 0x04	STATUS	        [0] UART_TX_BUSY, [1] UART_RX_DONE, [2] SPI_DONE
    // 0x08	UART_TXDATA	    Byte to send via UART
    // 0x0C	UART_RXDATA	    Last received UART byte
    // 0x10	SPI_TXDATA	    Data to send via SPI
    // 0x14	SPI_RXDATA	    Last received SPI data
    // 0x18	UART_BAUD	    Baud rate for UART
    // 0x1C	SPI_DIV	        clock divider value for SPI


    //Controlling AXI <-> UART signals
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            mem[1] <= 0;
            mem[3] <= 0;
            mem[5] <= 0;
        end else begin
            mem[1] <= status_reg; // Status Register
            mem[3] <= {24'd0, rx_uart}; // RX Data from UART
            mem[5] <= {24'd0, rx_spi}; // RX Data from SPI
        end
    end

    assign control_reg = mem[0]; // Control Register
    assign tx_uart = mem[2][7:0]; // TX Data Register
    assign tx_spi = mem[4][7:0]; // SPI TX Data Register
    assign uart_baud = mem[6]; // UART Baud Rate 
    assign spi_div = mem[7]; // SPI Div value
    
endmodule