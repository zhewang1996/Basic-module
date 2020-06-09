module  fifo
#(
parameter WIDTH = 8,   //����λ��Ϊ8
parameter ADDRSIZE = 8 //��ַλ��Ϊ8����FIFO���Ϊ2^8
)
(
	input I_rst_n, //��λ�źţ��͵�ƽ��Ч
	input I_w_clk, //дʱ��
	input I_w_en,  //дʹ��	
	input I_r_clk, //��ʱ��
	input I_r_en,  //��ʹ��
	input [WIDTH-1 : 0]I_data,//λ��Ϊ8�Ĳ�����������
	output [WIDTH-1 : 0]O_data,//�����������
	output reg O_r_empty,//�����ź�
	output reg O_w_full  //д���ź�
);

(*KEEP = "TRUE"*)wire [ADDRSIZE-1 : 0] waddr,raddr;//��д��ַ
reg [ADDRSIZE : 0] w_ptr,r_ptr;//��ָ�룬дָ��,������(λ��Ϊ9�������λ�����Ƚ��Ƿ�д��һȦ)
reg [ADDRSIZE : 0] wp_to_rp1,wp_to_rp2;//дָ��ͬ������ʱ���򣬸����룬1��2ָ���Ǿ�������D����������������̬
reg [ADDRSIZE : 0] rp_to_wp1,rp_to_wp2;//��ָ��ͬ����дʱ���򣬸����룬1��2ָ���Ǿ�������D����������������̬

//RAMģ��-----------------------------------------------------------------------------------------
localparam RAM_DEPTH = 1 << ADDRSIZE; //RAM���=2^ADDRSIZE, ���=256
reg [WIDTH-1 : 0] mem[RAM_DEPTH-1 : 0]; //����һ��λ��Ϊ8�����Ϊ256��RAM

always @(posedge I_w_clk)
begin
	if(I_w_en)
		mem[waddr] <= I_data;
end
assign O_data = mem[raddr];

//ͬ��ģ��,����ָ��ͬ����дʱ����-----------------------------------------------------------------------
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

//ͬ��ģ��,��дָ��ͬ������ʱ����--------------------------------------------------
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
		
//�����źŵĲ���------------------------------------------------------------------
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

assign raddr_cnt_next = raddr_cnt + (I_r_en & ~O_r_empty);//����ַ����+1
assign r_ptr_next = (raddr_cnt_next >> 1) ^ raddr_cnt_next; //��ַ����(������)=>��ַָ��(������)
assign raddr = raddr_cnt[ADDRSIZE-1 : 0]; //ʵ�ʵ�ַ�ȵ�ַ��������һλ�����λ�����Ƚ��Ƿ�д��һȦ
assign empty_val = (r_ptr_next == wp_to_rp2);//����ָ����ͬ��������дָ����ȣ�������źŲ���

always @(posedge I_r_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
	O_r_empty <= 1'b1;
	else
	O_r_empty <= empty_val;
end


//д���źŵĲ���------------------------------------------------------------------
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

assign waddr_cnt_next = waddr_cnt + (I_w_en & ~O_w_full);//д��ַ����+1
assign w_ptr_next = (waddr_cnt_next >> 1) ^ waddr_cnt_next;
assign waddr = waddr_cnt[ADDRSIZE-1 : 0];//ʵ�ʵ�ַ�ȵ�ַ��������һλ�����λ�����Ƚ��Ƿ�д��һȦ
assign full_val = (w_ptr_next == {~rp_to_wp2[ADDRSIZE : ADDRSIZE-1],rp_to_wp2[ADDRSIZE-2 : 0]});//��дָ����ͬ�������Ķ�ָ�������λ��ͬ������λ����ȣ���д���źŲ���

always @(posedge I_w_clk or negedge I_rst_n)
begin
	if(!I_rst_n)
	O_w_full <= 1'b0;
	else
	O_w_full <= full_val;
end

endmodule
