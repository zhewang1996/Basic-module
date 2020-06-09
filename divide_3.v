module divide_3  
(	input clk , 	// system clock 50Mhz on board 4 
	input rst_n,	// system rst, low active 5 
	output out_clk 	// output signal 
);
 
parameter N = 3 ; 

reg [N/2 :0] cnt_1 ; 
reg [N/2 :0] cnt_2 ; 
reg out_clk1 ; 
reg out_clk2 ;
 
//===================================================================== 
// ------------------------- MAIN CODE ------------------------------- 
//===================================================================== 
 always @(posedge clk or negedge rst_n) begin //上升沿输出out_clk1 
	if(!rst_n) begin 
		out_clk1 <= 0; 
		cnt_1 <= 1; //这里计数器从1开始 
	end 
	else begin 
		if(out_clk1 == 0) begin 
			if(cnt_1 == N/2+1) begin 
				out_clk1 <= ~out_clk1; 
				cnt_1 <= 1; 
			end 
			else 
				cnt_1 <= cnt_1+1;
		end 
		else if(cnt_1 == N/2) begin 
			out_clk1 <= ~out_clk1; 
			cnt_1 <= 1; 
		end 
	else 
		cnt_1 <= cnt_1+1; 
	end 
end 

always @(negedge clk or negedge rst_n) begin //下降沿输出out_clk2 
	if(!rst_n) begin 
		out_clk2 <= 0; 
		cnt_2 <= 1; //这里计数器从1开始 
	end 
	else begin 
		if(out_clk2 == 0) begin 
			if(cnt_2 == N/2+1) begin 
				out_clk2 <= ~out_clk2;
				cnt_2 <= 1; 5
			end 
		else 
			cnt_2 <= cnt_2+1; 
		end 
		else if(cnt_2 == N/2) begin 
			out_clk2 <= ~out_clk2; 
			cnt_2 <= 1; 
		end 
		else 
			cnt_2 <= cnt_2+1; 
	end 
end 

assign out_clk = out_clk1 | out_clk2; 

endmodule