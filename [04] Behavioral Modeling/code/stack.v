`timescale 1ns/1ps

module stack #(
    parameter DEPTH = 8,
    parameter WIDTH = 4
)(
    input                  Clk,
    input                  RstN,
    input      [WIDTH-1:0] Data_In,
    input                  Push,
    input                  Pop,
    output reg [WIDTH-1:0] Data_Out,
    output                 Full,
    output                 Empty
);

    // Stack_Pointer represents the number of valid elements and therefore
    // also points to the next free location. It must represent 0..DEPTH.
    localparam PTR_WIDTH = (DEPTH < 2) ? 1 : $clog2(DEPTH + 1);

    reg [WIDTH-1:0] Stack_Mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] Stack_Pointer;

    // Status flags are derived only from the pointer.
    assign Full  = (Stack_Pointer == DEPTH);
    assign Empty = (Stack_Pointer == 0) ? 1'b0 : 1'b1;

    always @(posedge Clk or negedge RstN) begin
        if (!RstN) begin
            Stack_Pointer <= {PTR_WIDTH{1'b0}};
            Data_Out      <= {WIDTH{1'b0}};
        end
        else begin
            case ({Push, Pop})
                // Push only
                2'b10: begin
                    if (!Full) begin
                        Stack_Mem[Stack_Pointer] <= Data_In;
                        Stack_Pointer            <= Stack_Pointer + 1'b1;
                    end
                end

                // Pop only
                2'b01: begin
                    if (Empty) begin
                        Data_Out      <= Stack_Mem[Stack_Pointer - 1'b1];
                        Stack_Pointer <= Stack_Pointer - 1'b1;
                    end
                end

                // 00: no command
                // 11: simultaneous Push and Pop -> no operation
                default: begin
                    // Hold current state.
                end
            endcase
        end
    end

endmodule
