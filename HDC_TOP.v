module HDC_TOP (clk,rst_n,result,error
);

parameter MAX_LENGTH = 200;

input clk;
input rst_n;
//wire clk_2;

output wire signed [1:0] result;
 output error;


    wire [MAX_LENGTH*8-1:0] msg;
  wire  msg_valid;
    wire [7:0] length;
 wire [1:0] label;
 wire compute_done;


//div_clk u_div_clk(
//.clk(clk),
//.rst_n(rst_n),
//.out(clk_2)
//);


MsgSend u_MsgSend (
    .clk                     ( clk                              ),
    .rst_n                   ( rst_n                            ),
    .compute_done            ( compute_done                     ),
    .msg                     ( msg           [MAX_LENGTH*8-1:0] ),

    .msg_valid               ( msg_valid                        ),
    .length                  ( length        [7:0]              ),
    .label                   ( label         [1:0]              )
);


HDC u_HDC (
    .msg                     ( msg           [MAX_LENGTH*8-1:0] ),
    .msg_valid               ( msg_valid                        ),
    .length                  ( length        [7:0]              ),
    .label                   ( label         [1:0]              ),
    .clk                     ( clk                              ),
    .rst_n                   ( rst_n                            ),

    .result                  ( result        [1:0]              ),
    .compute_done            ( compute_done                     ),
    .error                   ( error                            )
);


ila_0 u_ila (
    .clk (clk),
    .probe0(msg_valid),
   .probe1(label),
   .probe2(compute_done),
    .probe3(result),
    .probe4(error)
);
    
endmodule
