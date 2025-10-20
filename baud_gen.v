// module baud_gen #(
//     parameter CLK_FREQ = 50000000
// )(
//     input        clk,        
//     input        resetn,
//     input [31:0] baud_rate,
//     output reg   baud_tick   
// );
//     integer COUNT_MAX;
//     initial COUNT_MAX = CLK_FREQ / baud_rate;
    
//     reg [31:0] count;

//     always @(posedge clk or negedge resetn) begin
//         if (!resetn) begin
//             count <= 0;
//             baud_tick <= 0;
//         end 
//         else if (count == COUNT_MAX - 1) begin
//             count <= 0;
//             baud_tick <= 1;   // generate tick
//         end 
//         else begin
//             count <= count + 1;
//             baud_tick <= 0;
//         end
//     end
// endmodule


module baud_gen #(
    parameter CLK_FREQ = 50000000
)(
    input        clk,        
    input        resetn,
    input [31:0] baud_rate,
    output reg   baud_tick   
);
    reg [31:0] count;
    reg [31:0] count_max;

    always @(*) begin
        if (baud_rate != 0)
            count_max = CLK_FREQ / baud_rate;
        else
            count_max = 32'hFFFFFFFF; // avoid divide by zero
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            count <= 0;
            baud_tick <= 0;
        end 
        else if (count >= count_max - 1) begin
            count <= 0;
            baud_tick <= 1;   // generate tick
        end 
        else begin
            count <= count + 1;
            baud_tick <= 0;
        end
    end
endmodule

