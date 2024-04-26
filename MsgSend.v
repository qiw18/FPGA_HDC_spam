
module MsgSend (
clk,rst_n,msg,msg_valid,length,label,compute_done
);
    parameter MAX_LENGTH = 200;
    parameter MSG_NUMS = 100;

    input clk;
    input rst_n;
    input compute_done;
    output [MAX_LENGTH*8-1:0] msg;
    output  msg_valid;
    output [7:0] length;
    output [1:0] label;


reg [6:0] MSG_ROM_addr;
wire [MAX_LENGTH*8-1:0] MSG_ROM_data;

//reg [6:0] LENGHT_ROM_addr;
wire [7:0] LENGHT_ROM_data;

//reg [6:0] TAG_ROM_addr;
wire [1:0] TAG_ROM_data;

    MSG_ROM u_MSG_ROM(
            .clka(clk),
            .addra(MSG_ROM_addr),
            .douta(MSG_ROM_data),
            .ena(1)
    );


    
    LENGTH_ROM u_LENGTH_ROM(
            .clka(clk),
            .addra(MSG_ROM_addr),
            .douta(LENGHT_ROM_data),
            .ena(1)
    );

    
    TAG_ROM u_TAG_ROM(
            .clka(clk),
            .addra(MSG_ROM_addr),
            .douta(TAG_ROM_data),
            .ena(1)
    );


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        MSG_ROM_addr <= 0;
      //  LENGHT_ROM_addr <= 0;
      //  TAG_ROM_addr <= 0;
    end
    else if(compute_done)begin
        MSG_ROM_addr <= (MSG_ROM_addr==MSG_NUMS-1) ? 0 : MSG_ROM_addr +1;
      //  LENGHT_ROM_addr <= (TAG_ROM_addr==MSG_NUMS-1) ? 0 :LENGHT_ROM_addr +1;
       // TAG_ROM_addr <= (TAG_ROM_addr==MSG_NUMS-1) ? 0 :TAG_ROM_addr +1;
    end
end

assign msg = MSG_ROM_data;
assign length = LENGHT_ROM_data;
assign label = TAG_ROM_data;

reg [1:0] compute_done_delay;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        compute_done_delay <= 0;
    end
    else begin
        compute_done_delay<= {compute_done_delay[0],compute_done};
    end
end


reg initial_pluse;
reg flag;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        initial_pluse <= 0;
        flag <= 0;
    end
    else if(MSG_ROM_addr == MSG_NUMS-1)begin
        initial_pluse <= 0;
        flag <= 0;
    end
    else if(initial_pluse && flag)begin
        initial_pluse <= 0;
        flag <= 1;
    end
    else if(MSG_ROM_addr == 0 && flag==0 )begin
        initial_pluse <= 1;
        flag <= 1;
    end
end
assign msg_valid = (MSG_ROM_addr ==0)? initial_pluse : compute_done_delay[1];


endmodule
