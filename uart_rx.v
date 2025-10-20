module uart_rx #(
    parameter DATA_WIDTH = 8
) (
    input                       clk,          
    input                       resetn,          
    input                       rx_serial,    
    input                       baud_tick,    
    output reg [DATA_WIDTH-1:0] rx_data,  
    output reg                  rx_done  
);

    localparam IDLE = 2'd0,
               START = 2'd1,
               DATA = 2'd2,
               STOP = 2'd3;

    reg [3:0] present_bit_index;
    reg [1:0] state, next_state;
    reg [DATA_WIDTH-1:0] rx_data_reg;

    // State Transition
    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            state <= IDLE;
        else
            state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (!rx_serial) next_state = START; // Start bit detected
            START: if (baud_tick) next_state = DATA;
            DATA: if (baud_tick && present_bit_index == DATA_WIDTH-1) next_state = STOP;
            STOP: if (baud_tick) next_state = IDLE;
        endcase
    end

    // Output Logic and Bit Index Management
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            rx_data <= 0;
            rx_done <= 1'b0;
            present_bit_index <= 4'd0;
            rx_data_reg <= 0;
        end
        else begin
            rx_done <= 1'd0;
            case (state) 
                IDLE: present_bit_index <= 4'd0; // Reset bit index in IDLE state
            
                START: present_bit_index <= 4'd0; // Reset bit index on start bit detection

                DATA: begin
                    if (baud_tick) begin
                        rx_data_reg[present_bit_index] <= rx_serial; // Sample data bit
                        present_bit_index <= present_bit_index + 1;
                    end
                end

                STOP: begin
                    if (baud_tick && rx_serial == 1) begin
                        rx_data <= rx_data_reg; // Latch received data
                        rx_done <= 1'b1;        // Indicate data reception complete
                    end
                end
                    
            endcase
        end
    end

endmodule