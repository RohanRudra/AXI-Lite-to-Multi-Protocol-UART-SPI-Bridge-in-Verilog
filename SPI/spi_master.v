module spi_master #(
    parameter DATA_WIDTH = 8
) (
    input clk, //system clock
    input resetn, 
    input start, 
    input sclk,
    input CPOL,
    input CPHA,
    input [DATA_WIDTH-1:0] tx_data,
    input MISO,
    output reg MOSI,
    output reg CSn,
    output reg [DATA_WIDTH-1:0] rx_data,
    output reg done,
    output reg sclk_enable
);

    localparam IDLE = 2'b00;
    localparam TRANSFER = 2'b01;
    localparam COMPLETE = 2'b10;

    reg [1:0] state;
    reg [DATA_WIDTH-1:0] temp_reg;
    reg [$clog2(DATA_WIDTH)-1:0] tx_bit_index;
    reg [$clog2(DATA_WIDTH)-1:0] rx_bit_index;


    //-------Generating SCLK edges for sampling and shifting-------
    reg sclk_d;
    wire sclk_rising  = ( sclk & ~sclk_d );
    wire sclk_falling = (~sclk &  sclk_d);

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            sclk_d <= CPOL;
            sclk_enable <= 1'b0;
        end
        else begin
            sclk_d <= sclk;
            sclk_enable <= (state == TRANSFER);
        end
    end
    

    //-------State Machine for SPI Master Operation-------
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= IDLE;
            CSn <= 1'b1;
            done <= 1'b0;
            MOSI <= 1'b0;
            rx_data <= 0;
            temp_reg <= 0;
            tx_bit_index <= DATA_WIDTH - 1; //MSB first
            rx_bit_index <= DATA_WIDTH - 1;
        end
        else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    CSn <= 1'b1;

                    if (start) begin
                        state <= TRANSFER;
                        CSn <= 1'b0; // Activate chip select
                        temp_reg <= tx_data; // Load data to transmit
                        rx_bit_index <= DATA_WIDTH - 1;

                        if (CPHA == 0) begin
                            MOSI <= tx_data[DATA_WIDTH-1]; // preload first bit
                            tx_bit_index <= DATA_WIDTH - 2; // Point to next bit
                        end
                        else tx_bit_index <= DATA_WIDTH - 1; 
                    end
                end

                TRANSFER: begin
                    if (CPHA == 0) begin // Sample on leading edge
                        if ((CPOL ? sclk_falling : sclk_rising)) begin // Sampling Edge
                            rx_data[rx_bit_index] <= MISO; 
                            if(rx_bit_index == 0) state <= COMPLETE;
                            else rx_bit_index <= rx_bit_index - 1;
                        end
                        if ((CPOL ? sclk_rising : sclk_falling)) begin// Shifting Edge
                            // if(tx_bit_index == 0) state <= COMPLETE; 
                            // else begin
                                MOSI <= temp_reg[tx_bit_index];
                                tx_bit_index <= tx_bit_index - 1;
                            //end
                        end  
                    end
                    else begin // Sample on trailing edge
                        if ((CPOL ? sclk_falling : sclk_rising)) begin //Shifting Edge
                            MOSI <= temp_reg[tx_bit_index];
                            tx_bit_index <= tx_bit_index - 1;  
                        end
                        if ((CPOL ? sclk_rising : sclk_falling)) begin //Sampling Edge
                            rx_data[rx_bit_index] <= MISO;  
                            if(rx_bit_index == 0) state <= COMPLETE;
                            else rx_bit_index <= rx_bit_index - 1;
                        end
                    end
                end

                COMPLETE: begin
                    CSn <= 1'b1;
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end


endmodule