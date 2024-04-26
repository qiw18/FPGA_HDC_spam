module HDC (msg,msg_valid, length, label, clk, rst_n, result,compute_done,error);

// PARAMETER DEFINE 
    parameter MAX_LENGTH = 200;
    parameter NUM_CHAR = 37;
    parameter DIM = 500;
    parameter BITS_PER_CHAR = 8;
    parameter BITS_PER_INT = 16;




    parameter normHam = 70792; //
    parameter normSpam = 11031;
    



// PORTS
    input [MAX_LENGTH*8-1:0] msg;
    input msg_valid;
    input[7:0] length;
    input[1:0] label;
    input clk, rst_n;
    output reg signed [1:0] result;
    output reg compute_done;
    output reg error;



    wire signed[BITS_PER_INT-1:0] hamVector_data;
    wire signed[BITS_PER_INT-1:0] spamVector_data;
    //reg signed[BITS_PER_INT-1:0] msgVector [DIM-1:0];

    reg signed [20 :0] prodHam;
    reg signed [20 :0] prodSpam;
    reg [8:0] Vector_addr;
    wire [7:0] dictMem_addr;
    wire [DIM-1 :0] dictMem_data;
    reg prod_done;
    reg [8:0] dim_cnt;
    wire signed [7 :0] avg;
    reg signed [7 :0] sum;

   // wire signed[BITS_PER_INT-1:0] dictMem [NUM_CHAR-1:0] [DIM-1:0]; // change to [10000:0] later
   

    genvar  i;

        
// wire [7:0] dictMem_addr1 [0 : DIM-1];
// wire [7:0] dictMem_addr2 [0 : DIM-1];
// wire [0:0] dictMem_result [0 : DIM-1 ];

// generate
//     for (i = 0; i < DIM; i = i + 1) begin
//         dictMem_Lut u_dictMem_Lut(
//             .a(dictMem_addr1[i]),
//             .b(dictMem_addr2[i]),
//             .out(dictMem_result[i])
//         );
//     end
// endgenerate

    dictMem u_dictMem(
            .clka(clk),
            .addra(dictMem_addr),
            .douta(dictMem_data),
            .ena(1)
    );




    hamVector u_ham(
        .clka(clk),
        .addra(Vector_addr),
        .douta(hamVector_data),
        .ena(1)
    );

    spamVector u_spam(
        .clka(clk),
        .addra(Vector_addr),
        .douta(spamVector_data),
        .ena(1)
    );



wire sum_done_pos;
reg signed[BITS_PER_INT-1:0] num_msg[MAX_LENGTH:0];
reg [7:0] lower_letter [MAX_LENGTH  : 0];
wire prod_done_pos;
reg msg_valid_delay;

//GENERATE NUM_MSG  (MSG------>> NUM_MAG)

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        msg_valid_delay <= 0;
    end
    else begin
        msg_valid_delay <= msg_valid;
    end
end

generate
    for(i = 0;i < MAX_LENGTH; i = i+1)begin



        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)begin
                lower_letter[i] <= 0;
            end
            else if(msg_valid)begin
                lower_letter[i] <= (msg[ i*BITS_PER_CHAR +: 8] > 64) && (msg[ i*BITS_PER_CHAR +: 8] < 91)?
                        msg[ i*BITS_PER_CHAR +: 8] +32 : msg[ i*BITS_PER_CHAR +: 8] ;
            end
        end


        // assign lower_letter[i] = (msg[ i*BITS_PER_CHAR +: 8] > 64) && (msg[ i*BITS_PER_CHAR +: 8] < 91)?
        //                 msg[ i*BITS_PER_CHAR +: 8] +32 : msg[ i*BITS_PER_CHAR +: 8] ;



        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)begin
                num_msg[i] <= 0;
            end
            else if(msg_valid_delay)begin
                if (lower_letter[i]>="a" && lower_letter[i]<="z") begin
                    num_msg[i] <= lower_letter[i]-"a"+11;
                end
                else if (lower_letter[i]>="0" && lower_letter[i]<="9") begin
                    num_msg[i] <= lower_letter[i]-"0"+1;
                end 
                else begin
                    num_msg[i] <= 0;
                end
            end

        end
    end
endgenerate



reg [7:0] length_cnt;
//reg msg_valid ;
reg length_cnt_valid;
reg length_cnt_flag;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        length_cnt <= 0;
        length_cnt_valid <= 0;
        length_cnt_flag <= 0;
    end
    else if(msg_valid_delay)begin
        length_cnt <= 0;
        length_cnt_valid <= 1;
        length_cnt_flag <= 0;
    end
    else if(length_cnt == length-1)begin
        length_cnt <= 0;
        length_cnt_valid <= 0;
        length_cnt_flag <= 1;
    end
    else if(length_cnt_flag==0 && length_cnt_valid==1) begin
        length_cnt_valid <= 1 ;
        length_cnt <=  length_cnt +1 ;
        length_cnt_flag <= length_cnt_flag;
    end
end

reg length_cnt_valid_delay;
reg start_sum;
reg [1:0] start_sum_delay;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        length_cnt_valid_delay <= 0;
        start_sum_delay <= 0;
    end
    else begin
        length_cnt_valid_delay <= length_cnt_valid;
        start_sum_delay <= {start_sum_delay[0],start_sum};
    end
end
//








wire signed  [15 :0 ] HV_SHIFT [DIM-1:0];

reg sum_done;
reg sum_done_delay;
reg  signed [7:0] HV [DIM-1:0] ;
generate
    for (i = 0; i < DIM; i = i + 1) begin
        assign HV_SHIFT[i] = HV[DIM-1-i] << 8;
        always @(posedge clk or negedge rst_n) begin
            if(!rst_n)begin
                HV[i] <= 0;
            end
            else if(msg_valid)begin
                HV[i] <= 0;
            end
            else if (sum_done_pos) begin
                if ( HV_SHIFT[i] > avg) begin
                    HV[i] <= 1;
                end 
                else if ( HV_SHIFT[i] < avg) begin
                    HV[i] <= -1;
                end 
                else begin
                    HV[i] <= 0;
                end


                // if ( {HV[DIM-1-i],10'b0} > avg) begin
                //     HV[i] <= 1;
                // end 
                // else if ( {HV[DIM-1-i],10'b0} < avg) begin
                //     HV[i] <= -1;
                // end 
                // else begin
                //     HV[i] <= 0;
                // end


            end
            else if(length_cnt_valid_delay)begin
                // HV[i] <= HV[i] + dictMem[ num_msg[length_cnt-1] ] [i] ;
                if(dictMem_data[i]==1)begin
                    //HV[i] <= HV[i] + $signed (1) ;
                    HV[i] <= HV[i] + 8'b11111111 ;
                end
                else begin
                    HV[i] <= HV[i] + 8'b00000001 ;
                   // HV[i] <= HV[i] - $signed (1) ;
                end 
            end
        end

        // assign dictMem_addr2[i] = i;
    end

     assign dictMem_addr = num_msg[length_cnt];
endgenerate

// wire signed [BITS_PER_INT-1:0] HV0;
// assign HV0 = HV[0];
// assign HV0test = HV[0]*1000 < avg;
// wire signed [31-1:0] HV0_test_data;
// assign HV0_test_data = HV[0]*1000;

// wire signed [BITS_PER_INT-1:0] HV1;
// assign HV1 = HV[1];
// assign HV1test = HV[1]*1000 < avg;
// wire signed [31-1:0] HV1_test_data;
// assign HV1_test_data = HV[1]*1000;


// wire signed [BITS_PER_INT-1:0] HV2;
// assign HV2 = HV[2];
// assign HV2test = HV[2]*1000 < avg;
// wire signed [31-1:0] HV2_test_data;
// assign HV2_test_data = HV[2]*1000;
//sum 



always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        start_sum <= 0;
    end
    else if(msg_valid || dim_cnt == DIM-3)begin
        start_sum <= 0 ;
    end
    else if(length_cnt == length-1)begin
        start_sum <= 1;
    end
end









always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        dim_cnt <= 0;
    end
    else if(start_sum_delay[1])begin
        dim_cnt <= (dim_cnt == DIM-1)?0:dim_cnt+1;
    end
end



always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        sum <= 0;
    end
    else if(msg_valid)begin
        sum <= 0;
    end
    else if(start_sum_delay[1])begin
        sum <= sum + HV[dim_cnt];
    end
end


 

//  assign avg = (sum*1000) / DIM ;
// assign avg = (sum<<12) / DIM ;

// assign avg = (sum << 6) / 125 ;  //  assign avg = (sum*1024) / DIM ;
//assign avg = sum << 1 ; 
assign avg = sum>>>1  ;
//assign avg = (sum <<7) /125; 





always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        sum_done <= 0;
    end
    else if(msg_valid)begin
        sum_done <= 0;
    end
    else if(Vector_addr == DIM )begin
        sum_done <= 0;
    end
    else if(dim_cnt == DIM -1)begin
        sum_done <= 1;
    end
end

assign sum_done_pos = sum_done && ~sum_done_delay;

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        sum_done_delay<= 0;
    end
    else if(Vector_addr == DIM )begin
        sum_done_delay <= 0;
    end
    else begin
        sum_done_delay <= sum_done;
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        Vector_addr <= 0;
    end
    else if(msg_valid)begin
        Vector_addr <= 0;
    end
    else if(sum_done)begin
        Vector_addr <= Vector_addr +1;
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        prod_done <= 0;
       // Vector_addr <= 0;
        prodHam <= 0;
        prodSpam <= 0;
    end
    else if(msg_valid)begin
        prod_done <= 0;
       // Vector_addr <= 1;
        prodHam <= 0;
        prodSpam <= 0;
    end
    else if(Vector_addr == DIM+1 )begin
        prod_done <= 1;
      //  Vector_addr <= 0;
        prodHam <= prodHam;
        prodSpam <= prodSpam;
    end
    else if(sum_done_delay)begin
      //  Vector_addr <= Vector_addr +1;
        prod_done <= 0;
        if(HV[Vector_addr -1] == 1)begin
            prodHam <= prodHam + hamVector_data;
            prodSpam <= prodSpam + spamVector_data;
        end
        else if(HV[Vector_addr -1] == -1)begin
            prodHam <= prodHam - hamVector_data;
            prodSpam <= prodSpam - spamVector_data;
        end
        else begin
            prodHam <= prodHam ;
            prodSpam <= prodSpam ;
        end
        // prodHam <= prodHam + hamVector_data * HV[Vector_addr -1] ;
        // prodSpam <= prodSpam + spamVector_data * HV[Vector_addr -1] ;
    end
end




reg [15:0] cosHam ;

reg [15:0] cosSpam;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        cosHam <= 0;
        cosSpam <= 0;
    end
    else if(msg_valid)begin
        cosHam <= 0;
        cosSpam <= 0;
    end
    else if(prod_done_pos)begin
        cosHam <= (prodHam)>>>5;
        cosSpam <= (prodSpam >>>3) +  (prodSpam >>>4) + (prodSpam >>>7) +  (prodSpam >>>8) ;
    end
end


reg prod_done_delay;
reg prod_done_pos_delay;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        prod_done_delay <= 0;
        prod_done_pos_delay <= 0;
    end
    else begin
        prod_done_delay <= prod_done;
        prod_done_pos_delay <= prod_done_pos;
    end
end


assign prod_done_pos = prod_done && ~ prod_done_delay;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        result <= 0;
    end
    else if(msg_valid)begin
        result<= 0;
    end
    else if(prod_done_pos_delay)begin
            if (cosHam>cosSpam) begin
              result <= 1;
            end
            else if (cosHam<cosSpam) begin
              result <= 0;
            end
            else begin
              result <= -1;
            end
    end
end


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        compute_done <= 0;
    end
    else begin
        compute_done <= prod_done_pos_delay;
    end
end



reg [15:0] correct_cnt;


always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        correct_cnt <= 0;
    end
    else if(compute_done)begin
        if(label == result)begin
            correct_cnt <= correct_cnt+1;
        end
        else begin
            correct_cnt <= correct_cnt;
        end
    end
end

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        error<= 0;
    end
    else if(compute_done)begin
        if(label != result)begin
            error <= 1;
        end
        else begin
            error <= 0;
        end
    end
end



endmodule
