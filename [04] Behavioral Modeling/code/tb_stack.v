`timescale 1ns/1ps


module tb_stack #(
    parameter DEPTH = 8,
    parameter WIDTH = 4
);

    reg                  Clk;
    reg                  RstN;
    reg  [WIDTH-1:0]     Data_In;
    reg                  Push;
    reg                  Pop;

    wire [WIDTH-1:0]     Data_Out;
    wire                 Full;
    wire                 Empty;

    integer errors;
    integer i;
    reg [WIDTH-1:0] saved_data_out;

    stack #(
        .DEPTH(DEPTH),
        .WIDTH(WIDTH)
    ) dut (
        .Clk     (Clk),
        .RstN    (RstN),
        .Data_In (Data_In),
        .Push    (Push),
        .Pop     (Pop),
        .Data_Out(Data_Out),
        .Full    (Full),
        .Empty   (Empty)
    );

    // 10 ns clock period
    always #5 Clk = ~Clk;

    task push_value;
        input [WIDTH-1:0] value;
        begin
            @(negedge Clk);
            Data_In = value;
            Push    = 1'b1;
            Pop     = 1'b0;

            @(posedge Clk);
            #1;
            Push = 1'b0;

            $display("PUSH %0d | Full=%b Empty=%b", value, Full, Empty);
        end
    endtask

    task pop_and_check;
        input [WIDTH-1:0] expected;
        begin
            @(negedge Clk);
            Push = 1'b0;
            Pop  = 1'b1;

            @(posedge Clk);
            #1;
            Pop = 1'b0;

            if (Data_Out !== expected) begin
                errors = errors + 1;
                $display("ERROR: POP expected=%0d, got=%0d", expected, Data_Out);
            end
            else begin
                $display("POP  %0d | Full=%b Empty=%b", Data_Out, Full, Empty);
            end
        end
    endtask

    initial begin
        Clk     = 1'b0;
        RstN    = 1'b0;
        Data_In = {WIDTH{1'b0}};
        Push    = 1'b0;
        Pop     = 1'b0;
        errors  = 0;

        $display("===========================================");
        $display("Stack test started: DEPTH=%0d WIDTH=%0d", DEPTH, WIDTH);
        $display("===========================================");

        // 1) Reset
        repeat (2) @(posedge Clk);
        #1;
        if ((Full !== 1'b0) || (Empty !== 1'b0) ||
            (Data_Out !== {WIDTH{1'b0}})) begin
            errors = errors + 1;
            $display("ERROR: Reset state is incorrect.");
        end

        @(negedge Clk);
        RstN = 1'b1;

        // 2) Pop while empty -> ignored
        Pop = 1'b1;
        @(posedge Clk);
        #1;
        Pop = 1'b0;
        if ((Empty !== 1'b0) || (Full !== 1'b0)) begin
            errors = errors + 1;
            $display("ERROR: Empty-pop changed stack status.");
        end

        // 3) Fill exactly DEPTH locations
        for (i = 1; i <= DEPTH; i = i + 1)
            push_value(i);

        if ((Full !== 1'b1) || (Empty !== 1'b1)) begin
            errors = errors + 1;
            $display("ERROR: Full flag is incorrect after %0d pushes.", DEPTH);
        end

        // 4) Push while full -> ignored
        push_value({WIDTH{1'b1}});
        if (Full !== 1'b1) begin
            errors = errors + 1;
            $display("ERROR: Push while full changed stack status.");
        end

        // 5) Pop everything and verify LIFO order
        for (i = DEPTH; i >= 1; i = i - 1)
            pop_and_check(i);

        if ((Full !== 1'b0) || (Empty !== 1'b0)) begin
            errors = errors + 1;
            $display("ERROR: Stack is not empty after all pops.");
        end

        // 6) Pop while empty again -> ignored.
        //    Data_Out must also keep its previous valid value.
        saved_data_out = Data_Out;

        @(negedge Clk);
        Pop = 1'b1;
        @(posedge Clk);
        #1;
        Pop = 1'b0;

        if ((Empty !== 1'b0) || (Full !== 1'b0) ||
            (Data_Out !== saved_data_out)) begin
            errors = errors + 1;
            $display("ERROR: Empty-pop changed the stack or Data_Out.");
        end

        // 7) Simultaneous Push & Pop -> no operation by design.
        //    Use the internal pointer as an additional invariant check so
        //    this test cannot falsely pass if the DUT accidentally performs
        //    only a push or only a pop.
        push_value({WIDTH{1'b1}});

        @(negedge Clk);
        Data_In = {WIDTH{1'b0}};
        Push    = 1'b1;
        Pop     = 1'b1;
        @(posedge Clk);
        #1;
        Push = 1'b0;
        Pop  = 1'b0;

        if (dut.Stack_Pointer !== 1) begin
            errors = errors + 1;
            $display("ERROR: Simultaneous Push/Pop changed Stack_Pointer.");
        end

        // The previous top value must still be present.
        pop_and_check({WIDTH{1'b1}});

        $display("===========================================");
        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("TEST FAILED: %0d error(s)", errors);
        $display("===========================================");

        $finish;
    end

endmodule
