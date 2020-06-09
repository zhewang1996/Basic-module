module  fifo
#(
parameter WIDTH = 8,   //数据位宽为8
parameter ADDRSIZE = 8 //地址位宽为8，则FIFO深度为2^8
)
(
	input I_rst_n, //复位信号，低电平有效
	input I_w_clk, //写时钟
	input I_w_en,  //写使能	
	input I_r_clk, //读时钟
	input I_r_en,  //读使能
	input [WIDTH-1 : 0]I_data,//位宽为8的并行数据输入
	output [WIDTH-1 : 0]O_data,//并行数据输出
	output reg O_r_empty,//读空信号
	output reg O_w_full  //写满信号
);

(*KEEP = "TRUE"*)wire [ADDRSIZE-1 : 0] waddr,raddr;//读写地址
reg [ADDRSIZE : 0] w_ptr,r_ptr;//读指针，写指针,格雷码(位宽为9，最高两位用来比较是否写了一圈)
reg [ADDRSIZE : 0] wp_to_rp1,wp_to_rp2;//写指针同步至读时钟域，格雷码，1与2指的是经过两级D触发器，消除亚稳态
reg [ADDRSIZE : 0] rp_to_wp1,rp_to_wp2;//读指针同步至写时钟域，格雷码，1与2指的是经过两级D触发器，消除亚稳态

//RAM模块-----------------------------------------------------------------------------------------
localparam RAM_DEPTH = 1 << ADDRSIZE; //RAM深度=2^ADDRSIZE, 深度=256
reg [WIDTH-1 : 0] mem[RAM_DEPTH-1 : 0]; //声明一个位宽为8，深度为256的RAM

always @(posedge I_w_clk)
begin
	if(I_w_en)
		mem[waddr] <= I_data;
end
assign O_data = mem[raddr];

//同步模块,将读指针同步至写时钟域-----------------------------------------------------------------------
always @(posedge I_w_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
	begin
		rp_to_wp1 <= 0;
		rp_to_wp2 <= 0;
	end
	else
	begin
		rp_to_wp1 <= r_ptr;
		rp_to_wp2 <= rp_to_wp1;
	end
end

//同步模块,将写指针同步至读时钟域--------------------------------------------------
always @(posedge I_r_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
	begin
		wp_to_rp1 <= 0;
		wp_to_rp2 <= 0;
	end
	else
	begin
		wp_to_rp1 <= w_ptr;
		wp_to_rp2 <= wp_to_rp1;
	end
end
		
//读空信号的产生------------------------------------------------------------------
(*KEEP = "TRUE"*)reg  [ADDRSIZE : 0] raddr_cnt;
(*KEEP = "TRUE"*)wire [ADDRSIZE : 0]raddr_cnt_next;
(*KEEP = "TRUE"*)wire [ADDRSIZE : 0] r_ptr_next;
(*KEEP = "TRUE"*)wire empty_val;
always @(posedge I_r_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
	begin
		raddr_cnt <= 0;
		r_ptr <= 0;
	end
	else
	begin
		raddr_cnt <= raddr_cnt_next;
		r_ptr <= r_ptr_next;
	end
end

assign raddr_cnt_next = raddr_cnt + (I_r_en & ~O_r_empty);//读地址不断+1
assign r_ptr_next = (raddr_cnt_next >> 1) ^ raddr_cnt_next; //地址计数(二进制)=>地址指针(格雷码)
assign raddr = raddr_cnt[ADDRSIZE-1 : 0]; //实际地址比地址计数器少一位，最高位用来比较是否写了一圈
assign empty_val = (r_ptr_next == wp_to_rp2);//若读指针与同步过来的写指针相等，则读空信号产生

always @(posedge I_r_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
	O_r_empty <= 1'b1;
	else
	O_r_empty <= empty_val;
end


//写满信号的产生------------------------------------------------------------------
(*KEEP = "TRUE"*)reg  [ADDRSIZE : 0] waddr_cnt;
(*KEEP = "TRUE"*)wire [ADDRSIZE : 0]waddr_cnt_next;
wire [ADDRSIZE : 0]w_ptr_next;
wire full_val;

always @(posedge I_w_clk or negedge I_rst_n)
begin
	if (!I_rst_n)
	begin
		waddr_cnt <= 0;
		w_ptr <= 0;
	end
	else
	begin
		waddr_cnt <= waddr_cnt_next;
		w_ptr <= w_ptr_next;
	end
end

assign waddr_cnt_next = waddr_cnt + (I_w_en & ~O_w_full);//写地址不断+1
assign w_ptr_next = (waddr_cnt_next >> 1) ^ waddr_cnt_next;
assign waddr = waddr_cnt[ADDRSIZE-1 : 0];//实际地址比地址计数器少一位，最高位用来比较是否写了一圈
assign full_val = (w_ptr_next == {~rp_to_wp2[ADDRSIZE : ADDRSIZE-1],rp_to_wp2[ADDRSIZE-2 : 0]});//若写指针与同步过来的读指针最高两位不同，其他位都相等，则写满信号产生

always @(posedge I_w_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
	O_w_full <= 1'b0;
	else
	O_w_full <= full_val;
end

endmodule
