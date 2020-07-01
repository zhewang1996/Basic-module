module iic_send(
    input sys_clk,
    input rst_n,
    input iic_send_en,

    input [7:0] dev_addr,
    input [7:0] word_addr,
    input [7:0] write_data,

    output  scl,
    output  reg done_flag,
    inout   sda
);

parameter DIV_SELECT = 500 ;
parameter DIV_SELECT0 = (DIV_SELECT >> 2) -1 , //产生SCL高电平中间的标志位
          DIV_SELECT1 = (DIV_SELECT >> 1) -1 ,
          DIV_SELECT2 = (DIV_SELECT0 + DIV_SELECT1) + 1, //产生SCL低电平中间的标志位
          DIV_SELECT3 = (DIV_SELECT >> 1) +1; //产生SCL下降沿标志位

reg [10:0] scl_cnt;
reg sda_mode;
reg scl_en;
reg sda_reg;
reg ack_flag;
reg [3:0] state;
reg [3:0] jump_state;
reg [3:0] bit_cnt;
reg [7:0] load_data;

assign sda = sda_mode ? sda_reg : 1'bz;

wire scl_low_mid,scl_high_mid,scl_full;

always @ (posedge sys_clk or negedge rst_n ) begin
    if (!rst_n)
        scl_cnt <= 0;
    else if(scl_en) begin
        else if(scl_cnt == DIV_SELECT - 1)
            scl_cnt <= 0;
        else 
            scl_cnt <= scl_cnt + 1;
    end
    else
        scl_cnt <= 0;
end

assign scl          = (scl_cnt <= DIV_SELECT1) ? 1'b1 : 1'b0;
assign scl_low_mid  = (scl_cnt == DIV_SELECT2) ? 1'b1 : 1'b0;
assign scl_high_mid = (scl_cnt == DIV_SELECT0) ? 1'b1 : 1'b0;
assign scl_full     = (scl_cnt == DIV_SELECT3) ? 1'b1 : 1'b0;

always @ (posedge sys_clk or negedge rst_n ) begin
    if (!rst_n) begin
        state <= 0;
        sda_mode <= 1;
        sda_reg <= 1;
        bit_cnt <= 0;
        done_flag <= 0;
        ack_flag <= 0;
        jump_state <= 0;
    end
    else if(iic_send_en) begin
        case(state)
            4'd0: begin//空闲拉高SCL和SDA
                scl_en <= 0;   //关闭SCL时钟线
                sda_reg <= 1; //设置SDA为高电平   
                sda_mode <= 1;//设置SDA为输出模式
                bit_cnt <=0; //发送计数清零
                state <= 4'd1;
                done_flag <= 0;
                jump_state <= 0;
            end
            4'd1:begin //加载IIC设备物理地址
                jump_state <= 4'd2;
                state <= 4'd4;
                load_data <= dev_addr;
            end
            4'd2:begin //加载IIC设备字地址
                jump_state <= 4'd3;
                state <= 4'd4;
                load_data <= word_addr;
            end
            4'd3:begin //加载IIC数据
                jump_state <= 4'd8;
                state <= 4'd4;
                load_data <= write_data;
            end
            4'd4:begin //发送起始信号
                scl_en <= 1;//打开scl时钟线
                if(scl_cnt == scl_high_mid) begin
                    sda_reg <= 0;
                    state <= 4'd5;
                end
                else
                    state <= state;
            end
            4'd5:begin //发送数据
                if(scl_cnt == scl_low_mid) begin
                    if(bit_cnt == 4'd8)begin
                        bit_cnt <= 0;
                        state <= 4'd6;
                    end
                    else begin
                    sda_reg <= load_data[7-bit_cnt];
                    bit_cnt <= bit_cnt +1 ;
                    end
                end
                else 
                    state <= state ;
            end
            4'd6：begin //接受应答位
                sda_mode <= 0;
                if(scl_cnt == scl_high_mid) begin
                    ack_flag <= sda;
                    state <= 4'd7;
                end
                else
                    state <= state ;
            end
            4'd7：begin //校验应答位
                sda_mode <= 1;
                sda_reg <= 0;
                if (ack_flag == 0) begin
                    if(scl_cnt== scl_full)
                        state <= jump_state;
                    else
                        state <= state;
                end
                else
                    state <= 0;
            end
            4'd8:begin //发送停止信号
                if(scl_high_mid) begin
                    sda_reg <= 1;
                    state <= 4'd9;
                end
                else 
                    state <= state;
            end
            4'd9:begin //iic写操作结束
                done_flag <=1;
                state <= 0;
                ack_flag <= 0;
            end
            default : state <= 0;
        endcase
    end
    else begin
        state <= 0;
        sda_mode <= 1;
        sda_reg <= 1;
        bit_cnt <= 0;
        done_flag <= 0;
        ack_flag <= 0;
        jump_state <= 0;  
    end
end
