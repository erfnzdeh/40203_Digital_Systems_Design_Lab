`timescale 1ns/1ps

// ================================================================
// Extra parameterization test.
// Uses a non-default configuration to prove the module is generic:
// DATA_WIDTH = 8, DEPTH = 5, automatically calculated ADDR_WIDTH = 3.
// ================================================================
module TB_param;
    localparam integer DATA_WIDTH = 8;
    localparam integer DEPTH      = 5;
    localparam integer ADDR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    reg                       clk;
    reg                       rstN;
    reg                       r_e;
    reg                       w_e;
    reg  [DATA_WIDTH-1:0]     data_in;
    reg  [DATA_WIDTH-1:0]     mask;
    reg  [ADDR_WIDTH-1:0]     addr_in;

    wire [DATA_WIDTH-1:0]     matched_num;
    wire [ADDR_WIDTH-1:0]     matched_addr;
    wire [DEPTH-1:0]          match_vector;
    wire                      match;

    integer errors;

    TCAM #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rstN(rstN),
        .r_e(r_e),
        .w_e(w_e),
        .data_in(data_in),
        .mask(mask),
        .addr_in(addr_in),
        .matched_num(matched_num),
        .matched_addr(matched_addr),
        .match_vector(match_vector),
        .match(match)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task write_entry;
        input [ADDR_WIDTH-1:0] a;
        input [DATA_WIDTH-1:0] d;
        input [DATA_WIDTH-1:0] m;
        begin
            @(negedge clk);
            addr_in = a;
            data_in = d;
            mask    = m;
            r_e     = 1'b0;
            w_e     = 1'b1;
            @(posedge clk);
            #1;
            w_e = 1'b0;
        end
    endtask

    task search_key;
        input [DATA_WIDTH-1:0] key;
        begin
            @(negedge clk);
            data_in = key;
            r_e     = 1'b1;
            w_e     = 1'b0;
            @(posedge clk);
            #1;
            r_e = 1'b0;
        end
    endtask

    initial begin
        errors  = 0;
        rstN    = 1'b0;
        r_e     = 1'b0;
        w_e     = 1'b0;
        data_in = 8'h00;
        mask    = 8'h00;
        addr_in = {ADDR_WIDTH{1'b0}};

        #12;
        rstN = 1'b1;

        // Write to the highest legal address of DEPTH=5.
        // Pattern: 1010XXXX
        write_entry(3'd4, 8'b10100000, 8'b00001111);

        search_key(8'b10101111);
        if (match !== 1'b1 || matched_addr !== 3'd4 || match_vector !== 5'b10000) begin
            $display("[FAIL] parameterized masked-match test");
            errors = errors + 1;
        end
        else
            $display("[PASS] parameterized masked-match test");

        search_key(8'b10110000);
        if (match !== 1'b0 || match_vector !== 5'b00000) begin
            $display("[FAIL] parameterized miss test");
            errors = errors + 1;
        end
        else
            $display("[PASS] parameterized miss test");

        // Exact entry at another address.
        write_entry(3'd1, 8'h5A, 8'h00);
        search_key(8'h5A);
        if (match !== 1'b1 || matched_addr !== 3'd1 || matched_num !== 8'h5A || match_vector !== 5'b00010) begin
            $display("[FAIL] parameterized exact-match test");
            errors = errors + 1;
        end
        else
            $display("[PASS] parameterized exact-match test");

        // Illegal address for DEPTH=5 must be ignored safely.
        write_entry(3'd7, 8'h3C, 8'h00);
        search_key(8'h3C);
        if (match !== 1'b0 || match_vector !== 5'b00000) begin
            $display("[FAIL] out-of-range write-address test");
            errors = errors + 1;
        end
        else
            $display("[PASS] out-of-range write-address test");

        if (errors == 0)
            $display("\nALL PARAMETERIZATION TESTS PASSED.\n");
        else
            $display("\nPARAMETERIZATION TEST FINISHED WITH %0d ERROR(S).\n", errors);

        #10;
        $finish;
    end
endmodule
