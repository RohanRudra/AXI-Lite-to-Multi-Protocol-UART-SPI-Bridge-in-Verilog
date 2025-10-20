`timescale 1ns/1ps
`include "axi_multi_top.v"

module axi_multiprotocol_tb ();

    localparam CLK_PERIOD = 20;
    localparam CLK_FREQ = 50000000;
    localparam uart_div = CLK_FREQ / 9600;

    reg ACLK, ARESETn;

    reg [31:0] S_AXI_AWADDR, S_AXI_WDATA, S_AXI_ARADDR;
    wire [31:0] S_AXI_RDATA;
    reg S_AXI_AWVALID, S_AXI_WVALID, S_AXI_BREADY, S_AXI_ARVALID, S_AXI_RREADY;
    wire S_AXI_AWREADY, S_AXI_WREADY, S_AXI_BVALID, S_AXI_ARREADY, S_AXI_RVALID;
    wire [1:0] S_AXI_BRESP, S_AXI_RRESP;
    reg [3:0] S_AXI_WSTRB;

    reg rx_uart_serial; 
    reg MISO_spi;
    wire tx_uart_serial, MOSI_spi, SCLK_spi, CSn_spi;


    axi_multi_top #(
        .ADDR_WIDTH(32),
        .DATA_WIDTH(32),
        .CLK_FREQ(CLK_FREQ)
    ) dut (
        .ACLK(ACLK), .ARESETn(ARESETn),
        .S_AXI_AWADDR(S_AXI_AWADDR), .S_AXI_AWREADY(S_AXI_AWREADY), .S_AXI_AWVALID(S_AXI_AWVALID),
        .S_AXI_WDATA(S_AXI_WDATA), .S_AXI_WSTRB(S_AXI_WSTRB), .S_AXI_WVALID(S_AXI_WVALID), .S_AXI_WREADY(S_AXI_WREADY),
        .S_AXI_BRESP(S_AXI_BRESP), .S_AXI_BVALID(S_AXI_BVALID), .S_AXI_BREADY(S_AXI_BREADY), 
        .S_AXI_ARADDR(S_AXI_ARADDR), .S_AXI_ARVALID(S_AXI_ARVALID), .S_AXI_ARREADY(S_AXI_ARREADY),
        .S_AXI_RDATA(S_AXI_RDATA), .S_AXI_RRESP(S_AXI_RRESP), .S_AXI_RVALID(S_AXI_RVALID), .S_AXI_RREADY(S_AXI_RREADY),
        .rx_uart_serial(rx_uart_serial), .tx_uart_serial(tx_uart_serial),
        .MISO_spi(MISO_spi), .MOSI_spi(MOSI_spi), .SCLK_spi(SCLK_spi), .CSn_spi(CSn_spi)
    );


    initial begin
        ACLK = 1'b0;
        forever #(CLK_PERIOD/2) ACLK = ~ACLK;
    end

    initial begin
        ARESETn = 1'b0;
        #500 ARESETn = 1'b1;
    end


    //AXI Write task
    task axi_write(input [31:0] addr, input [31:0] data);
        begin
            @(posedge ACLK); // Wait for rising edge of clock
            S_AXI_AWADDR <= addr;
            S_AXI_AWVALID <= 1'b1;
            S_AXI_WDATA <= data;
            S_AXI_WVALID <= 1'b1;
            S_AXI_WSTRB <= 4'b1111;
            
            wait(S_AXI_AWREADY && S_AXI_WREADY);
            @(posedge ACLK);
            S_AXI_AWVALID <= 1'b0;
            S_AXI_WVALID <= 1'b0;

            wait(S_AXI_BVALID);
            if (S_AXI_BRESP != 2'b00)
                $display("AXI WRITE ERROR: Address %h, BRESP = %b", addr, S_AXI_BRESP);
            else
                $display("AXI WRITE OK: Address %h, Data %h", addr, data);

            S_AXI_BREADY <= 1'b1;
            @(posedge ACLK);
            S_AXI_BREADY <= 1'b0;
        end
    endtask


    //AXI Read task
    task axi_read(input [31:0] addr, output [31:0] data);
        begin
            @(posedge ACLK);
            S_AXI_ARADDR <= addr;
            S_AXI_ARVALID <= 1'b1;

            wait(S_AXI_ARREADY);
            @(posedge ACLK);
            S_AXI_ARVALID <= 1'b0;

            wait(S_AXI_RVALID);
            if (S_AXI_RRESP != 2'b00)
                $display("AXI READ ERROR: Addr %h, RRESP = %b", addr, S_AXI_RRESP);
            else
                $display("AXI READ OK: Addr %h, Data %h", addr, S_AXI_RDATA);

            data = S_AXI_RDATA;

            S_AXI_RREADY <= 1'b1;
            @(posedge ACLK);
            S_AXI_RREADY <= 1'b0;
        end
    endtask


    task send_byte_to_uart(input [7:0] data);
    integer i;
        begin
            // Start bit
            rx_uart_serial = 1'b0;
            repeat(uart_div) @(posedge ACLK); // Wait for one bit duration (approx 5208 clock cycles at 50MHz for 9600 baud)
            
            // 8 Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx_uart_serial = data[i];
                repeat(uart_div) @(posedge ACLK);
            end
            
            // Stop bit
            rx_uart_serial = 1'b1;
            repeat(uart_div) @(posedge ACLK);
        end
    endtask


    task send_byte_to_spi(input [7:0] data);
    integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                MISO_spi = data[i];
                repeat(4) @(posedge ACLK);
            end 
        end
    endtask


    reg [31:0] temp_reg;
    initial begin
        S_AXI_AWADDR = 0;
        S_AXI_AWVALID = 1'b0;
        S_AXI_WDATA = 0;
        S_AXI_WSTRB = 0;
        S_AXI_WVALID = 0;
        S_AXI_BREADY = 0;
        S_AXI_ARADDR = 0;
        S_AXI_ARVALID = 0;
        S_AXI_RREADY = 0;
        rx_uart_serial = 1'b1; // idle high


        @(posedge ARESETn); // Wait for reset deassertion
        #60

        axi_write(32'h18, 32'd9600); //Setting baud rate as 9600 bits/sec
        //UART TX
        axi_write(32'h08, 32'h41); //load uart tx data first
        axi_write(32'h00, 32'h01);
        axi_write(32'h00, 32'h00);

        repeat(2000) @(posedge ACLK); 
        axi_read(32'h04, temp_reg);
        $display("Status Register = %h", temp_reg);


        //UART RX
        send_byte_to_uart(8'h83);

        axi_read(32'h04, temp_reg); 
        $display("Status Register = %h", temp_reg);
        axi_read(32'h0C, temp_reg); 
        $display("Received UART Data = %h", temp_reg[7:0]);


        //SPI full duplex
        axi_write(32'h1C, 32'h2); // sclk_freq = global_clk_freq / 2(2) = global_clk_freq / 4
        axi_write(32'h10, 32'h43); //laod spi tx data first
        axi_write(32'h00, 32'h0A); //cpol = 0, cpha = 1
        axi_write(32'h00, 32'h08);

        send_byte_to_spi(8'h27);
        axi_read(32'h04, temp_reg); 
        $display("Status Register = %h", temp_reg);
        axi_read(32'h14, temp_reg); 
        $display("Received SPI Data = %h", temp_reg[7:0]);


        $finish;
    end


endmodule