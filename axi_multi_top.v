`include "axi_lite_slave.v"
`include "baud_gen.v"
`include "spi_clk_gen.v"
`include "spi_master.v"
`include "uart_rx.v"
`include "uart_tx.v"

module axi_multi_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    parameter CLK_FREQ = 50000000
) (
    input                       ACLK, ARESETn,
    input [ADDR_WIDTH-1:0]      S_AXI_AWADDR,
    input                       S_AXI_AWVALID, 
    output                      S_AXI_AWREADY,
    input [DATA_WIDTH-1:0]      S_AXI_WDATA,
    input [3:0]                 S_AXI_WSTRB,
    input                       S_AXI_WVALID,
    output                      S_AXI_WREADY,
    output [1:0]                S_AXI_BRESP,
    output                      S_AXI_BVALID,
    input                       S_AXI_BREADY,  
    input [ADDR_WIDTH-1:0]      S_AXI_ARADDR,
    input                       S_AXI_ARVALID,
    output                      S_AXI_ARREADY,
    output  [DATA_WIDTH-1:0]    S_AXI_RDATA,
    output  [1:0]               S_AXI_RRESP,
    output                      S_AXI_RVALID,
    input                       S_AXI_RREADY,

    input rx_uart_serial,
    output tx_uart_serial,
    input MISO_spi,
    output MOSI_spi,
    output SCLK_spi,
    output CSn_spi
);

    wire baud_tick;
    wire tx_uart_busy;
    wire rx_uart_done;

    wire [DATA_WIDTH-1:0] control_reg ;
    reg [DATA_WIDTH-1:0] status_reg ;
    wire [7:0] tx_uart, rx_uart, tx_spi, rx_spi;
    wire [31:0] uart_baud;
    wire [31:0] spi_div;

    reg tx_uart_start_reg;
    reg rx_uart_done_reg;


    wire sclk_enable;
    wire done_spi;
    reg cpol_reg, cpha_reg, start_spi_reg, done_spi_reg;

    AXILite_slave_if #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) axi_lite_slave_inst (
        .ACLK(ACLK),
        .ARESETn(ARESETn),
        .S_AXI_AWADDR(S_AXI_AWADDR),
        .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_AWREADY(S_AXI_AWREADY),
        .S_AXI_WDATA(S_AXI_WDATA),
        .S_AXI_WSTRB(S_AXI_WSTRB),
        .S_AXI_WVALID(S_AXI_WVALID),
        .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP),
        .S_AXI_BVALID(S_AXI_BVALID),
        .S_AXI_BREADY(S_AXI_BREADY),
        .S_AXI_ARADDR(S_AXI_ARADDR),
        .S_AXI_ARVALID(S_AXI_ARVALID),
        .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA),
        .S_AXI_RRESP(S_AXI_RRESP),
        .S_AXI_RVALID(S_AXI_RVALID),
        .S_AXI_RREADY(S_AXI_RREADY),
        .control_reg(control_reg),
        .status_reg(status_reg),
        .tx_uart(tx_uart),
        .rx_uart(rx_uart),
        .tx_spi(tx_spi),
        .rx_spi(rx_spi),
        .uart_baud(uart_baud),
        .spi_div(spi_div)
    );
    

    //--------UART Modules--------//

    baud_gen #(
        .CLK_FREQ(CLK_FREQ)
    ) uart_baud_gen_inst (
        .clk(ACLK),
        .resetn(ARESETn),
        .baud_rate(uart_baud),
        .baud_tick(baud_tick) 
    );


    uart_tx #(
        .DATA_WIDTH(8)
    ) uart_tx_inst (
        .clk(ACLK),
        .resetn(ARESETn),
        .baud_tick(baud_tick), 
        .tx_start(tx_uart_start_reg),  
        .tx_data(tx_uart),
        .tx(tx_uart_serial),
        .tx_busy(tx_uart_busy)  
    );


    uart_rx #(
        .DATA_WIDTH(8)
    ) uart_rx_inst (
        .clk(ACLK),
        .resetn(ARESETn),
        .rx_serial(rx_uart_serial),
        .baud_tick(baud_tick),
        .rx_data(rx_uart),
        .rx_done(rx_uart_done)
    );


    //------SPI Modules------//

    spi_clk_gen #(
        .DEFAULT_DIV(4)
    ) spi_clk_gen_inst (
        .clk(ACLK),
        .resetn(ARESETn),
        .enable(sclk_enable),
        .clk_div(spi_div),
        .CPOL(cpol_reg),  
        .spi_clk(SCLK_spi)  
    );


    spi_master #(
        .DATA_WIDTH(8)
    ) spi_master_inst (
        .clk(ACLK),
        .resetn(ARESETn),
        .start(start_spi_reg),  
        .sclk(SCLK_spi),
        .CPOL(cpol_reg),
        .CPHA(cpha_reg),
        .tx_data(tx_spi),
        .MISO(MISO_spi),
        .MOSI(MOSI_spi),
        .CSn(CSn_spi),
        .rx_data(rx_spi),
        .done(done_spi),  
        .sclk_enable(sclk_enable)  
    );


    //------Internal Registers------//
    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            rx_uart_done_reg <= 1'b0;
            done_spi_reg <= 1'b0;
        end
        else begin
            if (rx_uart_done)
                rx_uart_done_reg <= 1'b1;
            else if ((S_AXI_ARADDR == 32'h0C) & S_AXI_ARVALID & S_AXI_ARREADY)
                rx_uart_done_reg <= 1'b0;

            if (done_spi)
                done_spi_reg <= 1'b1;
            else if ((S_AXI_ARADDR == 32'h14) & S_AXI_ARVALID & S_AXI_ARREADY)
                done_spi_reg <= 1'b0;
        end
    end


    always @(posedge ACLK or negedge ARESETn) begin
        if (!ARESETn) begin
            cpol_reg <= 1'b0;
            cpha_reg <= 1'b0;
            start_spi_reg <= 1'b0;
            tx_uart_start_reg <= 1'b0;
            status_reg <= 0;
        end
        else begin
            tx_uart_start_reg <= control_reg[0];
            start_spi_reg <= control_reg[1];
            cpol_reg <= control_reg[2];
            cpha_reg <= control_reg[3];

            status_reg[0] <= tx_uart_busy;
            status_reg[1] <= rx_uart_done_reg;
            status_reg[2] <= done_spi_reg;
        end
        
    end



endmodule