module uart_tx #(
    parameter DATA_WIDTH = 8
) (
    input                  clk,
    input                  resetn,
    input                  baud_tick,
    input                  tx_start,        // may stay high for multiple cycles
    input [DATA_WIDTH-1:0] tx_data,
    output reg             tx,
    output reg             tx_busy
);

    // --- State encoding ---
    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    reg [1:0] state, next_state;
    reg [3:0] present_bit_index;
    reg [DATA_WIDTH-1:0] tx_data_reg;

    always @(posedge clk or negedge resetn) begin
        if (!resetn)
            state <= IDLE;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:  if (tx_start) next_state = START;
            START: if (baud_tick)      next_state = DATA;
            DATA:  if (baud_tick && present_bit_index == DATA_WIDTH-1) next_state = STOP;
            STOP:  if (baud_tick)      next_state = IDLE;
        endcase
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            tx <= 1'b1; // idle = high
            tx_busy <= 1'b0;
            present_bit_index <= 4'd0;
            tx_data_reg <= {DATA_WIDTH{1'b0}};
        end
        else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    tx_busy <= 1'b0;
                    present_bit_index <= 4'd0;
                end

                START: begin
                    tx <= 1'b0;           // start bit
                    tx_busy <= 1'b1;
                    tx_data_reg <= tx_data; // latch data on start
                end

                DATA: begin
                    if (baud_tick) begin
                        present_bit_index <= present_bit_index + 1;
                    end
                    tx <= tx_data_reg[present_bit_index];
                end

                STOP: begin
                    tx <= 1'b1;       // stop bit
                    tx_busy <= 1'b0;  // transmission done
                end
            endcase
        end
    end

endmodule
