// ================================================================
// Experiment 9 - Parameterized TCAM
// Default configuration: 16 entries x 16 bits
//
// mask bit = 1  -> stored bit is Don't-Care (X)
// mask bit = 0  -> stored bit must equal the search bit
//
// Search equation for each valid entry:
// ((search_key XOR stored_data) AND NOT stored_mask) == 0
// ================================================================

module TCAM #(
    parameter integer DATA_WIDTH = 16,
    parameter integer DEPTH      = 16,
    parameter integer ADDR_WIDTH = (DEPTH <= 1) ? 1 : $clog2(DEPTH)
)(
    input                           clk,
    input                           rstN,       // asynchronous active-low reset
    input                           r_e,        // search/read enable
    input                           w_e,        // write enable; has priority over r_e
    input      [DATA_WIDTH-1:0]     data_in,    // write data or search key
    input      [DATA_WIDTH-1:0]     mask,       // valid on write: 1 means X/Don't-Care
    input      [ADDR_WIDTH-1:0]     addr_in,    // write address

    output reg [DATA_WIDTH-1:0]     matched_num,
    output reg [ADDR_WIDTH-1:0]     matched_addr,
    output reg [DEPTH-1:0]          match_vector,
    output reg                      match
);

    // Each TCAM entry is represented by data bits plus mask bits.
    reg [DATA_WIDTH-1:0] data_mem [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] mask_mem [0:DEPTH-1];
    reg [DEPTH-1:0]      valid_mem;

    // Combinational search results. They are registered when r_e = 1.
    reg [DATA_WIDTH-1:0] search_matched_num;
    reg [ADDR_WIDTH-1:0] search_matched_addr;
    reg [DEPTH-1:0]      search_match_vector;
    reg                  search_match;

    integer i;
    integer j;

    // ------------------------------------------------------------
    // Parallel TCAM search.
    // All valid entries are compared with data_in simultaneously.
    // If multiple entries match, matched_num/matched_addr report the
    // highest matching address. match_vector reports every match.
    // ------------------------------------------------------------
    always @(*) begin
        search_matched_num  = {DATA_WIDTH{1'b0}};
        search_matched_addr = {ADDR_WIDTH{1'b0}};
        search_match_vector = {DEPTH{1'b0}};
        search_match        = 1'b0;

        for (i = 0; i < DEPTH; i = i + 1) begin
            if (valid_mem[i] &&
                (((data_in ^ data_mem[i]) & (~mask_mem[i])) == {DATA_WIDTH{1'b0}})) begin
                search_match_vector[i] = 1'b1;
                search_match           = 1'b1;
                search_matched_num     = data_mem[i];
                search_matched_addr    = i[ADDR_WIDTH-1:0];
            end
        end
    end

    // ------------------------------------------------------------
    // Storage and output registers.
    // Write has priority over search if w_e and r_e are both asserted.
    // ------------------------------------------------------------
    always @(posedge clk or negedge rstN) begin
        if (!rstN) begin
            matched_num  <= {DATA_WIDTH{1'b0}};
            matched_addr <= {ADDR_WIDTH{1'b0}};
            match_vector <= {DEPTH{1'b0}};
            match        <= 1'b0;
            valid_mem    <= {DEPTH{1'b0}};

            // valid_mem alone is enough to invalidate entries, but clearing
            // the arrays also keeps simulation state deterministic.
            for (j = 0; j < DEPTH; j = j + 1) begin
                data_mem[j] <= {DATA_WIDTH{1'b0}};
                mask_mem[j] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (w_e) begin
            // This check matters when DEPTH is not an exact power of two.
            if (addr_in < DEPTH) begin
                data_mem[addr_in]  <= data_in;
                mask_mem[addr_in]  <= mask;
                valid_mem[addr_in] <= 1'b1;
            end
        end
        else if (r_e) begin
            matched_num  <= search_matched_num;
            matched_addr <= search_matched_addr;
            match_vector <= search_match_vector;
            match        <= search_match;
        end
    end

endmodule
