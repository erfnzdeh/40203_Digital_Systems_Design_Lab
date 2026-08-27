`timescale 1ns/1ps

// ================================================================
// Experiment 9 - Self-checking testbench for the default TCAM
// Configuration: 16 entries x 16 bits
// ================================================================
module TB;
    localparam integer DATA_WIDTH = 16;
    localparam integer DEPTH      = 16;
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
            w_e     = 1'b0;
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
            r_e     = 1'b0;
        end
    endtask

    task expect_hit;
        input [DATA_WIDTH-1:0] expected_data;
        input [ADDR_WIDTH-1:0] expected_addr;
        input [DEPTH-1:0]      expected_vector;
        begin
            if (match !== 1'b1 ||
                matched_num !== expected_data ||
                matched_addr !== expected_addr ||
                match_vector !== expected_vector) begin
                $display("[FAIL] expected hit: data=%h addr=%0d vector=%b", 
                         expected_data, expected_addr, expected_vector);
                $display("       actual      : match=%b data=%h addr=%0d vector=%b",
                         match, matched_num, matched_addr, match_vector);
                errors = errors + 1;
            end
            else begin
                $display("[PASS] hit data=%h addr=%0d vector=%b",
                         matched_num, matched_addr, match_vector);
            end
        end
    endtask

    task expect_miss;
        begin
            if (match !== 1'b0 || match_vector !== {DEPTH{1'b0}}) begin
                $display("[FAIL] expected miss, got match=%b data=%h addr=%0d vector=%b",
                         match, matched_num, matched_addr, match_vector);
                errors = errors + 1;
            end
            else begin
                $display("[PASS] miss as expected");
            end
        end
    endtask

    initial begin
        errors  = 0;
        rstN    = 1'b0;
        r_e     = 1'b0;
        w_e     = 1'b0;
        data_in = {DATA_WIDTH{1'b0}};
        mask    = {DATA_WIDTH{1'b0}};
        addr_in = {ADDR_WIDTH{1'b0}};

        // --------------------------------------------------------
        // Test 1: reset / invalid entries must not cause false hits.
        // --------------------------------------------------------
        #12;
        rstN = 1'b1;
        search_key(16'h0000);
        expect_miss;

        // --------------------------------------------------------
        // Test 2: ordinary masked entries.
        // --------------------------------------------------------
        // addr 0: compare upper nibble and bits [7:4]; other bits are X.
        write_entry(4'd0, 16'hABCD, 16'h0F0F);

        // addr 1: upper byte is X; low byte must equal EF.
        write_entry(4'd1, 16'hCDEF, 16'hFF00);

        // addr 2: arbitrary bit-level mask.
        write_entry(4'd2, 16'h50C9, 16'hC32C);

        search_key(16'hAFC2);
        expect_hit(16'hABCD, 4'd0, 16'h0001);

        search_key(16'hD3C9);
        expect_hit(16'h50C9, 4'd2, 16'h0004);

        search_key(16'hCDFE);
        expect_miss;

        // --------------------------------------------------------
        // Test 3: exact match, mask = 0.
        // --------------------------------------------------------
        write_entry(4'd3, 16'h1234, 16'h0000);

        search_key(16'h1234);
        expect_hit(16'h1234, 4'd3, 16'h0008);

        search_key(16'h1235);
        expect_miss;

        // --------------------------------------------------------
        // Test 4: examples explicitly shown in the experiment sheet.
        // Search word: 01101110 = 8'h6E
        // Patterns: 0110XXXX, X1101XXX, 0X1X11X0
        // The upper byte is kept exact at 00 because this TCAM is 16-bit.
        // --------------------------------------------------------

        // addr 6: 0110XXXX
        // data = 01100000, mask = 00001111
        write_entry(4'd6, 16'h0060, 16'h000F);
        search_key(16'h006E);
        expect_hit(16'h0060, 4'd6, 16'h0040);

        // addr 7: X1101XXX
        // data = 01101000, mask = 10000111
        write_entry(4'd7, 16'h0068, 16'h0087);
        search_key(16'h006E);
        expect_hit(16'h0068, 4'd7, 16'h00C0);

        // addr 8: 0X1X11X0
        // data = 00101100, mask = 01010010
        write_entry(4'd8, 16'h002C, 16'h0052);
        search_key(16'h006E);
        expect_hit(16'h002C, 4'd8, 16'h01C0);

        // --------------------------------------------------------
        // Test 5: all-X entry matches every key.
        // --------------------------------------------------------
        write_entry(4'd4, 16'h0000, 16'hFFFF);
        search_key(16'hBEEE);
        expect_hit(16'h0000, 4'd4, 16'h0010);

        // --------------------------------------------------------
        // Test 6: multiple matches. Highest address must be selected,
        // while match_vector must report all matching entries.
        // --------------------------------------------------------
        write_entry(4'd5, 16'hFFFF, 16'hFFFF);
        search_key(16'hCAFE);
        expect_hit(16'hFFFF, 4'd5, 16'h0030);

        // --------------------------------------------------------
        // Test 7: overwrite an existing entry.
        // Entry 4 is still all-X, and entry 5 becomes exact CAFE.
        // Both match CAFE; highest address 5 is returned.
        // --------------------------------------------------------
        write_entry(4'd5, 16'hCAFE, 16'h0000);
        search_key(16'hCAFE);
        expect_hit(16'hCAFE, 4'd5, 16'h0030);

        if (errors == 0)
            $display("\n====================================");
        if (errors == 0)
            $display("ALL DEFAULT-CONFIGURATION TESTS PASSED");
        else
            $display("TESTS FINISHED WITH %0d ERROR(S)", errors);
        if (errors == 0)
            $display("====================================\n");

        #10;
        $finish;
    end
endmodule
