// Image Processing module 
// Pipelined modle
// Size of image Width=768 && Height=512
module IMAGE_PROCESSING(clk, HRESETn, opcode, done);
    
    input clk;                                    // clock
    input HRESETn;                                // Active low reset
    input [3:0]opcode;                            // 4-bit opcode(Type of operation)

    output reg done;                              // flag(Image processing complete-->1 else -->0)

// Intermediate or Another signals

    reg [20:0]PC;                                        // Address

    // Memory fetch to operation stage 
    reg [20:0] Mem_op_PC;                                // Latch between memory to operation stage to store Address                                        
    reg [7:0] Mem_op_R;                                  // Latch between memory to operation stage to store data of red pixel                     
    reg [7:0] Mem_op_G;                                  // Latch between memory to operation stage to store data of green pixel                      
    reg [7:0] Mem_op_B;                                  // Latch between memory to operation stage to store data of blue pixel                
    reg [3:0] Mem_op_opcode;                             // Latch between memory to operation stage to store opcode                     


    // alu stage
    reg [20:0] alu_PC;
    reg signed [9:0]  alu_R;                            // store signed data of red component of pixel and operation
    reg signed [9:0]  alu_G;                            // store signed data of green component of pixel and operation
    reg signed [9:0]  alu_B;                            // store signed data of blue component of pixel and operation
    reg [3:0] alu_opcode;

    // Operation to storeage stage
    reg [20:0] op_s_PC;                                  // store Address
    reg [20:0] op_s_NPC_M;                               // store next Address for latch to memory
    reg [7:0] op_s_R;                                    // store pixel Red component after operation
    reg [7:0] op_s_G;                                    // store pixel Green component after operation
    reg [7:0] op_s_B;                                    // store pixel Blue component after operation


    // Intermal Memory
    parameter WIDTH = 768;
    parameter HEIGHT = 512;
    reg [7:0] Mem [0:HEIGHT*WIDTH*3-1];                  // 1179648 size 8-bit Internal Memory

`ifndef SYNTHESIS
task load_mem;
    input [1023:0] filename;
    begin
        $display("Loading memory from %s", filename);
        $readmemh(filename, Mem);
        $display("Memory load done: Mem[0]=%h Mem[1]=%h Mem[2]=%h",
                  Mem[0], Mem[1], Mem[2]);
    end
endtask
`endif


    // Parameters for ALU unit
    parameter S0 = 4'b0000,                              // Brightness Adjustment
              S1 = 4'b0001,                              // Contrast Adjustment
              S2 = 4'b0010,                              // Inversion
              S3 = 4'b0011,                              // Thresholding
              S4 = 4'b0100,                              // Grayscalr Conversion
              S5 = 4'b0101,                              // Colour Channel Modulation
              S6 = 4'b0110,                              // Bit level operation
              S7 = 4'b0111,                              // Gamma Correction
              S8 = 4'b1000;                              // Pseudo Colouring

    // Brightness parameter
    reg sign = 1;
    reg [5:0]Adjustment_value = 6'd50;                          // default brightness increment

    // Contrast parameter
    reg [1:0]alpha = 2'd2;                                     // default contrast value

    // Thresholding value
    reg Th = 170;
    reg gray = 0;

    // Gamma correction value
    reg gamma = 2;

    //Pseudo-Colouring
    reg gray_pse;


// Assigning value to PC / contorling the address value

always @(posedge clk, negedge HRESETn)
    begin
    
        if(~HRESETn)
            begin
                PC <= 0;
            end
        else
            begin
                PC <= PC + 3;
            end
    end

// reading pixel on each rissing clock edge

always @(posedge clk, negedge HRESETn)
    begin
    
        if(~HRESETn)
            begin
                Mem_op_PC   <= 0;
             
                Mem_op_R    <= 0;
                Mem_op_G    <= 0;
                Mem_op_B    <= 0;
            end
        else
            begin
                Mem_op_PC       <= PC;
                Mem_op_R        <= Mem[PC];
                Mem_op_G        <= Mem[PC+1];
                Mem_op_B        <= Mem[PC+2];
                Mem_op_opcode   <= opcode;
            end
    end


// Opreation as per opcode

always @(posedge clk, negedge HRESETn)
    begin
        if(~HRESETn)
            begin
                alu_PC         <= 0;
                alu_NPC        <= 0;
                alu_R          <= 0;
                alu_G          <= 0;
                alu_B          <= 0;
                alu_opcode     <= 0;
            end
        else
            begin
                alu_opcode <= Mem_op_opcode;
                alu_PC     <= Mem_op_PC;
               
                case (Mem_op_opcode)
                    S0: begin
                        alu_R   <= (sign) ? (Mem_op_R + Adjustment_value) : (Mem_op_R - Adjustment_value);
                        alu_G   <= (sign) ? (Mem_op_G + Adjustment_value) : (Mem_op_G - Adjustment_value);
                        alu_B   <= (sign) ? (Mem_op_B + Adjustment_value) : (Mem_op_B - Adjustment_value);
                        end

                    S1: begin
                        alu_R   <= (alpha*(Mem_op_R - 128) + 128);
                        alu_G   <= (alpha*(Mem_op_G - 128) + 128);
                        alu_B   <= (alpha*(Mem_op_B - 128) + 128);
                        end

                    S2: begin
                        alu_R   <= (255 - Mem_op_R);
                        alu_G   <= (255 - Mem_op_G);
                        alu_B   <= (255 - Mem_op_B);
                        end
                    
                    S3: begin
                        alu_R   <= Mem_op_R;
                        alu_G   <= Mem_op_G; 
                        alu_B   <= Mem_op_B;
                        gray    <= (Mem_op_R + Mem_op_G +Mem_op_B)/3;
                        end

                    S4: begin
                        alu_R   <= (Mem_op_R + Mem_op_G +Mem_op_B)/3;
                        alu_G   <= (Mem_op_R + Mem_op_G +Mem_op_B)/3;
                        alu_B   <= (Mem_op_R + Mem_op_G +Mem_op_B)/3;
                        end
                    
                    S5: begin
                        alu_R   <= 0;
                        alu_G   <= 2*Mem_op_G;
                        alu_B   <= Mem_op_B;
                        end

                    S6: begin
                        alu_R   <= Mem_op_R & 8'hf0;
                        alu_G   <= Mem_op_G & 8'hf0;
                        alu_B   <= Mem_op_B & 8'hf0;
                        end

                    S7: begin
                        alu_R   <= 255*((Mem_op_R/255)**(1/gamma));
                        alu_G   <= 255*((Mem_op_G/255)**(1/gamma));
                        alu_B   <= 255*((Mem_op_B/255)**(1/gamma));
                        end

                    S8: begin
                        alu_R   <= Mem_op_R;
                        alu_G   <= Mem_op_G; 
                        alu_B   <= Mem_op_B;
                        gray_pse    <= (Mem_op_R + Mem_op_G +Mem_op_B)/3;
                        end

                    default: begin
                        alu_R   <= 8'd0;
                        alu_G   <= 8'd0;
                        alu_B   <= 8'd0;
                        end
                endcase
            end
    end


// Correction of pixel before storing back
always @(posedge clk, negedge HRESETn)
    begin
        if(~HRESETn)
            begin
            op_s_PC     <=  0; 
            op_s_NPC    <=  0; 
            op_s_R      <=  0; 
            op_s_G      <=  0; 
            op_s_B      <=  0; 
            end
        else
            begin
                op_s_PC   <= alu_PC;
           

                case (alu_opcode)
                    S0,S1: begin
                        if(alu_R < 9'd0)
                            op_s_R <= 0;
                        else if(alu_R > 9'd255)
                            op_s_R <= 255;
                        else 
                            op_s_R <= alu_R[7:0];

                        if(alu_G < 9'd0)
                            op_s_G <= 0;
                        else if(alu_G > 9'd255)
                            op_s_G <= 255;
                        else 
                            op_s_G <= alu_G[7:0];

                        if(alu_B < 9'd0)
                            op_s_B <= 0;
                        else if(alu_B > 9'd255)
                            op_s_B <= 255;
                        else 
                            op_s_B <= alu_B[7:0];
                        end
                    
                    S2, S4, S5, S6, S7: begin
                        op_s_R   <= alu_R;
                        op_s_G   <= alu_G;
                        op_s_B   <= alu_B;
                        end

                    S3: begin 
                        if(gray > Th)
                            begin
                                op_s_R  <= 255;
                                op_s_G  <= 255;
                                op_s_B  <= 255;
                            end
                        else
                            begin 
                                op_s_R  <= 0;
                                op_s_G  <= 0;
                                op_s_B  <= 0;
                            end
                        end

                    S8: begin  // Look up design
                        if(gray_pse < 8'd64) begin
                            op_s_R  <= 8'd0;
                            op_s_G  <= 8'd0;
                            op_s_B  <= 8'd255;
                            end
                        else if(gray_pse < 8'd128) begin
                            op_s_R  <= 8'd0;
                            op_s_G  <= 8'd255;
                            op_s_B  <= 8'd255;
                            end
                        else if(gray_pse < 8'd192) begin
                            op_s_R  <= 8'd0;
                            op_s_G  <= 8'd255;
                            op_s_B  <= 8'd0;
                            end
                        else begin
                            op_s_R  <= 8'd255;
                            op_s_G  <= 8'd0;
                            op_s_B  <= 8'd0;
                            end
                        end

                endcase
            end
    end


// Storing back to memory 
always @(posedge clk)
    if(HRESETn)
        begin
            Mem[op_s_PC] <= op_s_R;
            Mem[op_s_PC+1] <= op_s_G;
            Mem[op_s_PC+2] <= op_s_B;
            op_s_NPC_M <= op_s_NPC;
            if(op_s_PC+2 >= HEIGHT*WIDTH*3)
                done = 1'b1;
        end



endmodule


                         


                        
                        

                


                        



                
                        
    

                
          