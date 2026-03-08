module tb;

    reg clk, HRESETn;
    reg [3:0] opcode;
    wire done;

    IMAGE_PROCESSING dut (
        .clk(clk),
        .HRESETn(HRESETn),
        .opcode(opcode),
        .done(done)
    );

    // Clock generation
    initial clk = 0;
    always #2 clk = ~clk;


    initial begin
        $dumpfile("wave1.vcd");   // waveform file name
        $dumpvars(0, tb);        // dump ALL signals under tb
    end

    initial begin
        // 1️⃣ Initialize signals
        HRESETn = 0;
        opcode  = 4'b0111;

        // 2️⃣ LOAD MEMORY FIRST (KEY STEP)
        dut.load_mem("kodim.hex");

        $monitor($time,done);

        // 3️⃣ VERIFY MEMORY
        $display("TB VERIFY: Mem[0]=%h Mem[1]=%h Mem[2]=%h",
                  dut.Mem[0], dut.Mem[1], dut.Mem[1179000]);
        $monitor("done = %b",done);

        // 4️⃣ HOLD RESET for safety
        repeat (5) @(posedge clk);

        // 5️⃣ RELEASE RESET → pipeline starts
        HRESETn = 1;

        // 6️⃣ RUN SIMULATION
        #1700000 
        

    wait(done==1);
    $writememh("output7.hex", dut.Mem);


    #100 $finish;
    end

endmodule
