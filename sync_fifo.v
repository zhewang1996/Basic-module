module sync_fifo(
    input sys_clk,
    input sys_rst_n,
    input [7:0] wr_data,
    input wr_en,
    input rd_en,

    output reg [7:0] rd_data,
    output reg empty,
    output reg full 
);

parameter WIDTH = 8 ;
parameter ADDRSIZE = 3;
parameter DEPTH = 1 << ADDRSIZE ;

reg [ADDRSIZE-1:0] wr_addr ;
reg [ADDRSIZE-1:0] rd_addr ;
reg [WIDTH-1:0] mem [DEPTH-1:0];
reg [DEPTH-1:0] count;

//read
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n)
        rd_data <= 0;
    else if(rd_en && empty==0)
        rd_data <= mem[rd_addr];
end

//write
always @(posedge sys_clk ) begin
    if(wr_en && full==0)
    mem[wr_addr] <= wr_data;
end

//更新读地址
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        rd_addr <= 0;
    else if (rd_en && empty == 0)
        rd_addr <= rd_addr + 1 ;
end

//更新写地址
always@ (posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        wr_addr <= 0;
    else if (wr_en && full == 0)
        wr_addr <= wr_addr + 1 ;
end

//更新标志位
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n)
        count <= 0;
    else begin
        case({wr_en,rd_en})
            2'b00:count <= count;
            2'b01:
                if (count != 0)
                count <= count -1;
            2'b10:
                if (count != (DEPTH-1))
                count <= count +1;
            2'b11:count <= count;
        endcase
    end
end

always@(count) begin
    if (count == 0)
        empty <= 1;
    else
        empty = 0;
end

always@(count) begin
    if (count == (DEPTH -1))
        full <= 1;
    else
        full = 0;
end

endmodule