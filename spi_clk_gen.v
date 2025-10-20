module spi_clk_gen #(
    parameter DEFAULT_DIV = 4
) (
    input clk, 
    input resetn,
    input enable,
    input [31:0] clk_div,
    input CPOL,
    output reg spi_clk
);
    
    reg [31:0] clk_counter;
    wire [31:0] clk_div_value;

    assign clk_div_value = (clk_div != 0) ? clk_div : DEFAULT_DIV;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            clk_counter <= 0;
            spi_clk <= CPOL; 
        end 
        else if (enable) begin
            if (clk_counter == (clk_div_value - 1)) begin
                clk_counter <= 0;
                spi_clk <= ~spi_clk; 
            end 
            else begin
                clk_counter <= clk_counter + 1;
            end
        end
        else begin
            clk_counter <= 0;
            spi_clk <= CPOL; 
        end
    end

endmodule