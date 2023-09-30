package UVM_package;

    import uvm_pkg ::*;
    `include "uvm_macros.svh"
    event drived;

    class my_sequence_item extends uvm_sequence_item;  

        function new (string name = "my_sequence_item");
            super.new(name );
        endfunction

        parameter ADDR_WIDTH = 5;
        parameter DATA_WIDTH = 32;

        
        
        logic [DATA_WIDTH-1:0] data_out;
        logic valid_out;

        //randmom data
        randc bit [ADDR_WIDTH-1:0] addr;
        rand bit [DATA_WIDTH-1:0] data_in;
        rand logic en;
        rand logic wr;
        rand logic rst_n;

        //every single line of these include the field in the print_packet command
        `uvm_object_utils_begin(my_sequence_item)
        `uvm_field_int(addr,UVM_ALL_ON)
        `uvm_field_int(wr,UVM_ALL_ON)
        `uvm_field_int(en,UVM_ALL_ON)
        `uvm_field_int(data_in,UVM_ALL_ON)
        `uvm_field_int(data_out,UVM_ALL_ON)
        `uvm_field_int(valid_out,UVM_ALL_ON)
        `uvm_field_int(rst_n,UVM_ALL_ON)
        `uvm_object_utils_end 

        
        //constraint data_constraint
        constraint data_constraint { data_in < 500000  ;}
        //constranting the reset for a high probability for not reseting  
        constraint reset_constraint 
        {
            rst_n dist { 1 := 90 , 0:=10} ;
        }
        
    endclass
//-------------------------------------------------------------------------------------------------

    class my_sequence extends uvm_sequence#(my_sequence_item);
       
       `uvm_object_utils(my_sequence)
       
        function new (string name = "my_sequence");
            super.new(name );
        endfunction

        //Here in the task body I start the sequence of stimulus that I want to test on the DUT
        //The test stimulus is a mix of random testing , constrained random testing and dircet testing
        virtual task body();

        req = my_sequence_item::type_id::create("req");

        if (starting_phase != null)
                starting_phase.raise_objection(this);

            $display("########################################################################");
            $display("Reseting");
            $display("########################################################################");
            repeat(2)
            begin  
                start_item(req);
                if( !(req.randomize() with {req.rst_n==0 ; req.addr ==0;} ))
                    `uvm_error("", "Randomize failed")
                finish_item(req);
            end
            #20

            //read and write all the memory
            $display("########################################################################");
            $display("Filling the memory");
            $display("########################################################################");
            repeat(32)
            begin  
                start_item(req);
                if( !(req.randomize() with {req.en==1 ;req.wr == 1; req.rst_n==1 ;} ))
                    `uvm_error("", "Randomize failed")
                finish_item(req);
            end
            #20

            $display("########################################################################");
            $display("Reading all of the memory");
            $display("########################################################################");
            repeat(32)
            begin
                start_item(req);
                if( !(req.randomize() with {req.en==1 ;req.wr == 0; req.rst_n==1 ; } ))
                    `uvm_error("", "Randomize failed")
                finish_item(req);
            end
            #20

            //some back to back directed write then read
            $display("########################################################################");
            $display("Directed Write followed by Read");
            $display("########################################################################");
            `uvm_do_with(req, {req.en == 1; req.wr == 1; req.addr==3 ; req.rst_n==1 ;})
            `uvm_do_with(req, {req.en == 1; req.wr == 0; req.addr==3 ; req.rst_n==1 ;})
            `uvm_do_with(req, {req.en == 1; req.wr == 1; req.addr==6 ; req.rst_n==1 ;})
            `uvm_do_with(req, {req.en == 1; req.wr == 0; req.addr==6 ; req.rst_n==1 ;})
            `uvm_do_with(req, {req.en == 1; req.wr == 1; req.addr==9 ; req.rst_n==1 ;})
            `uvm_do_with(req, {req.en == 1; req.wr == 0; req.addr==9 ; req.rst_n==1 ;}) 

            #20
            //total random data
            $display("########################################################################");
            $display("Completely random stimulus");
            $display("########################################################################");
            repeat(10)
            begin
                start_item(req);
                if( !(req.randomize() ))
                    `uvm_error("", "Randomize failed")
                finish_item(req);
            end
            #20

            //random data with enable = 1
            $display("########################################################################");
            $display("Random stimulus with En = 1 , RST = LOW");
            $display("########################################################################");
            repeat(5)
            begin
                start_item(req);
                if( !(req.randomize() with {req.en==1 ;  req.rst_n==1 ;} ))
                    `uvm_error("", "Randomize failed")
                finish_item(req);
            end
            #20

            if (starting_phase != null)
                starting_phase.drop_objection(this);   
        
        endtask
    endclass
//-------------------------------------------------------------------------------------------------
    class my_sequencer extends uvm_sequencer#(my_sequence_item);
        
        `uvm_component_utils(my_sequencer);
        
        function new (string name = "my_sequencer" , uvm_component parent = null);
            super.new(name , parent);
        endfunction 

        function void build_phase(uvm_phase phase);
            super.build_phase(phase); 
            $display("This is my build of my sequencer");   
        endfunction

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            $display("This is my connect phase of my sequencer");
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("this is  run phase of my sequencer");
        endtask

    endclass
//-------------------------------------------------------------------------------------------------
    class my_scoreboard extends uvm_scoreboard;
        
        `uvm_component_utils(my_scoreboard);
        uvm_analysis_imp #(my_sequence_item , my_scoreboard) item_collected_export;
        logic [31:0] SB_mem [32];

        function new (string name = "my_scoreboard" , uvm_component parent = null);
            super.new(name , parent);
            item_collected_export = new("item_collected_export" , this);

        endfunction 

        
        function void build_phase(uvm_phase phase);
            super.build_phase(phase); 
            $display("This is my build of my scoreboard");  
            //I call the reset memory at the start of the test to empty my scoreboard memory
            reset_memory();

        endfunction

        // A simple function that resets the scoreboard memory once the reset is asserted
        virtual function void reset_memory();
                foreach (SB_mem[i])
                SB_mem[i]='x;
        endfunction

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            $display("This is my connect phase of my scoreboard");
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("this is  run phase of my scoreboard");
        endtask

        //This function is called when the monitor sends the packet to the scoreboard 
        virtual function void write(my_sequence_item packet);
            
            //check if the packet has reset asserted
            if (packet.rst_n ==0) begin
                $display("At scoreboard , reset is asserted");
                //once rst is asserted the scoreboard memory on reset
                reset_memory();
            end
            else begin
                $display("Received packet at scoreboard: ");
                packet.print();
                //if it's write operation then store the data inside the scoreboard memory
                if(packet.wr == 1 && packet.en ==1)
                    SB_mem[packet.addr] = packet.data_in;

                //esle if it's a read operation with valid out = 1 then check for the data inside addr of the packet inside the memory
                else if (packet.en ==1 && packet.wr ==0 && packet.valid_out ==1) begin
                    if (packet.data_out == SB_mem[packet.addr])
                        $display("TEST PASSED ");
                    else begin
                        `uvm_error(get_type_name() , "TEST FAILED");
                        $display("Reading from address which is not stored in the memory");
                    end
                end
            end

        endfunction
    endclass
//-------------------------------------------------------------------------------------------------   
    class my_subscriber extends uvm_subscriber#(my_sequence_item);    
        `uvm_component_utils(my_subscriber);
        
        function new (string name = "my_subscriber" , uvm_component parent = null);
            super.new(name , parent);
        endfunction 
        function void write (my_sequence_item t);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase); 
            $display("This is my build of my subscriber");            
        endfunction
        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            $display("This is my connect phase of my suscriber");
        endfunction
        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("this is  run phase of my subscriber");
        endtask
    endclass
//-------------------------------------------------------------------------------------------------
    class my_driver extends uvm_driver#(my_sequence_item);
        
        `uvm_component_utils(my_driver);
        virtual mem_if vif1;
        my_sequence_item sequence_item1;
        
        function new (string name = "my_driver" , uvm_component parent = null);
            super.new(name , parent);
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase); 

            if(!uvm_config_db#(virtual mem_if)::get(this ,"", "vif", vif1))
                `uvm_fatal("" , "get interface not working");

            $display("This is my build of my driver");            
        endfunction
        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            $display("This is my connect phase of my driver");
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("this is  run phase of my driver");
            forever begin
                //here the driver is blocked until it gets the next item from the sequencer
                seq_item_port.get_next_item(sequence_item1);
                //here it calls the drive item function which sends the randomized data from the sequencer to the DUT interface
                drive_item(sequence_item1);  
                //blocks until the item is done to proceed and get the next item
                seq_item_port.item_done();
            end
        endtask : run_phase

        //the function which drived the randomized stimulus to the interface which will be given to the DUT
        virtual task drive_item (input my_sequence_item sequence_item1);
            //I sample the data to the interface at the positive edge of the clk
            @(posedge vif1.clk);
            vif1.addr <= sequence_item1.addr;
            vif1.wr <=sequence_item1.wr;
            vif1.en <=sequence_item1.en;
            vif1.rst_n <= sequence_item1.rst_n;
            if(sequence_item1.wr ==0)  // if read put data in =0
                vif1.data_in <= '0;
            else
            vif1.data_in <= sequence_item1.data_in;

            #1;
            $display("Content at the driver side:");
            $display("data_in = %0h , addr = %0h , en = %0b , write = %0b , rst_n = %0b",vif1.data_in , vif1.addr , vif1.en , vif1.wr , vif1.rst_n);

            //highest priority is for the reset
            if (vif1.rst_n == 0) begin
                $display("Reset is asserted ");
                ->drived;
            end
            //then next priority is for the enable
            else if(vif1.en == 0 ) begin //enable == 0 , dont drive the monitor side
                $display("enable  = %0d -> packet droppped" , vif1.en );
            end
            //then check if write
            else if(sequence_item1.en==1 && sequence_item1.wr ==1) begin
                ->drived;         
            end
            //then check if read operation
            else if (sequence_item1.en==1 && sequence_item1.wr ==0) begin
                ->drived;
                //gives the driver one clock cycle wait to be synchronized with the monitor as the monitor will take 2 cycles
                //as the monitor has to wait for valid out to be true
                @(posedge vif1.clk);
            end

        endtask : drive_item
    endclass
//-------------------------------------------------------------------------------------------------
    class my_monitor extends uvm_monitor;
        
        `uvm_component_utils(my_monitor);
        virtual mem_if vif1;
        my_sequence_item trans_collected;
        //analysis port for the TLM
        uvm_analysis_port #(my_sequence_item) item_collected_port;
        //to trigger the coverage
        event cover_transaction;

        covergroup cov_trans @(cover_transaction) ;
            DATA_OUT : coverpoint vif1.data_out iff (vif1.wr ==0)
                    {   bins low = {[0:32'h0000_ffff]};
                        bins high  = {[32'h0001_0000 : $]};
                        bins misc = default ; }
            DATA_IN : coverpoint vif1.data_in iff (vif1.wr == 1)
                    {   bins low_din = {[0:32'h0000_ffff]};
                        bins high_din  = {[32'h0001_0000 : $]};
                        bins misc = default ;  }
            ADDRESS : coverpoint vif1.addr;
            VALID_OUT : coverpoint vif1.valid_out;
            WR : coverpoint vif1.wr;
            RST_N : coverpoint vif1.rst_n;
            ENABLE : coverpoint vif1.en;
        endgroup : cov_trans
        function new (string name = "my_monitor" , uvm_component parent = null);
            super.new(name , parent);
            cov_trans = new();
            cov_trans.set_inst_name( {get_full_name() , ".cov_trans"});
            trans_collected = new();
        endfunction
        function void build_phase(uvm_phase phase);
            super.build_phase(phase); 
            //create instance of analysis port
            item_collected_port= new("item_collected_port", this);
            //get virtual inteface handle
            if (!uvm_config_db#(virtual mem_if)::get(this ,"", "vif", vif1)) begin
                `uvm_error(get_type_name() , "DUT interface not found");
                end
            $display("This is my build of my monitor");   
        endfunction
        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            $display("This is my connect phase of my monitor");
        endfunction
        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("this is  run phase of my monitor");
            collect_data(); 
        endtask

        virtual task collect_data ();
        forever begin
            
            //wait(drived.triggered);
            @(drived);
            //trigger coverage to collect data
            ->cover_transaction;

            //check if the reset is asserted 
            if (vif1.rst_n == 0) begin
                trans_collected.rst_n = vif1.rst_n;
                //if reset is asserted then send the packet with only the rst_field and it will be handeled at the scoreboard
                item_collected_port.write(trans_collected);
            end
            else begin
                //sampling the inputs from the DUT interface
                trans_collected.en = vif1.en;
                trans_collected.rst_n = vif1.rst_n;
                trans_collected.addr = vif1.addr;
                trans_collected.data_in = vif1.data_in;
                trans_collected.wr = vif1.wr;

                //read operation need 2 cycles
                if (vif1.wr ==0 && vif1.en==1) begin 
                    //here will sample the 2 outputs from the interface
                    @(posedge vif1.clk);
                        #1;
                    if (vif1.valid_out==1) begin
                        //$display("MONITOR : T = %0t driver drived wr = 0",$time);
                        trans_collected.valid_out = vif1.valid_out;
                        trans_collected.data_out = vif1.data_out;
                        $display("Content at the monitor side:");
                        $display("data_in = %0h ,addr = %0h , data_out = %0h , en = %0b , wr = %0b , valid_out = %0b , rst_n = %0b" , trans_collected.data_in ,trans_collected.addr, trans_collected.data_out , trans_collected.en , trans_collected.wr , trans_collected.valid_out ,trans_collected.rst_n);
                    end
                    else
                        $display("error in valid out");
                end
                //if it's write operation
                else if (vif1.wr ==1 && vif1.en==1) begin

                    //put the data out =x as I dont care for its value and valid out = 0
                    trans_collected.data_out = 'x;
                    trans_collected.valid_out = 1'b0;
                    $display("Content at the monitor side:");
                    $display("data_in = %0h ,addr = %0h , data_out = %0h , en = %0b , wr = %0b , valid_out = %0b , rst_n = %0b" , trans_collected.data_in ,trans_collected.addr, trans_collected.data_out , trans_collected.en , trans_collected.wr , trans_collected.valid_out,trans_collected.rst_n);

                end  
                //$display("T = %0t sending to scoreoard",$time);

                //the following like sends the packet that the monitor got from the interface to the scoreboard
                item_collected_port.write(trans_collected);  
            end         
        end
        endtask : collect_data


    endclass
//-------------------------------------------------------------------------------------------------
    class my_agent extends uvm_agent;

        `uvm_component_utils(my_agent);

        my_sequencer sequencer1;
        my_driver driver1;
        my_monitor monitor1;
        virtual mem_if vif1;
        
        function new (string name = "my_agent" , uvm_component parent = null);
            super.new(name , parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase); 
            sequencer1=my_sequencer::type_id::create("sequencer1",this);
            driver1=my_driver::type_id::create("driver1",this);
            monitor1=my_monitor::type_id::create("monitor1",this); 

            uvm_config_db#(virtual mem_if)::get(this ,"", "vif", vif1);
            uvm_config_db#(virtual mem_if)::set(this ,"my_driver", "vif", vif1);
            uvm_config_db#(virtual mem_if)::set(this ,"my_monitor", "vif", vif1);

            $display("This is my build of my agent");            
        endfunction

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);

            //to connect driver to the sequencer in the agent
            driver1.seq_item_port.connect(sequencer1.seq_item_export);

            $display("This is my connect phase of my agent");
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("this is  run phase of my agent");
        endtask

    endclass
//-------------------------------------------------------------------------------------------------
    class my_env extends uvm_env;
        
        `uvm_component_utils(my_env);

        my_agent agent1;
        my_scoreboard scoreboard1;
        my_subscriber subscriber1;
        virtual mem_if vif1;

        function new (string name = "my_env" , uvm_component parent = null);
            super.new(name , parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase); 
            agent1=my_agent::type_id::create("agent1",this);
            scoreboard1=my_scoreboard::type_id::create("scoreboard1",this);
            subscriber1=my_subscriber::type_id::create("subscriber1",this);

            uvm_config_db#(virtual mem_if)::get(this ,"", "vif", vif1);
            uvm_config_db#(virtual mem_if)::set(this ,"my_agent", "vif", vif1);

            $display("This is my build of my env");            
        endfunction

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            //driver1.seq_item_port.connect(sequencer1.seq_item_export);
            agent1.monitor1.item_collected_port.connect(scoreboard1.item_collected_export);
            $display("This is my connect phase of my env");
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("this is  run phase of my env");
        endtask

    endclass
//-------------------------------------------------------------------------------------------------
    class my_test extends uvm_test;

        `uvm_component_utils(my_test);

        my_env env1;
        my_sequence my_sequence_in;
        virtual mem_if vif1;

        function new (string name = "my_test" , uvm_component parent = null);
            super.new(name , parent);
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase); 
            env1=my_env::type_id::create("env1",this);
            my_sequence_in = my_sequence ::type_id ::create("my_sequence_in");

            uvm_config_db#(virtual mem_if)::get(this ,"", "vif", vif1);
            uvm_config_db#(virtual mem_if)::set(this ,"my_env", "vif", vif1);

            $display("This is my build of my test");            
        endfunction

        function void connect_phase (uvm_phase phase);
            super.connect_phase(phase);
            $display("This is my connect phase of my test");
        endfunction
        
        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            $display("this is  run phase of my test");
            phase.raise_objection(this);
            my_sequence_in.start(env1.agent1.sequencer1);
            #100;
            phase.drop_objection(this);
        endtask

    endclass
//-------------------------------------------------------------------------------------------------


endpackage



module top_tb;

    import UVM_package::*;
    import uvm_pkg ::*;
    
    bit clk ;
    always #5 clk=~clk;


    mem_if intf1(clk);
    virtual mem_if vif1;

    memory #(
            .ADDR_WIDTH(intf1.ADDR_WIDTH),
            .DATA_WIDTH(intf1.DATA_WIDTH),
            .DEPTH(intf1.DEPTH)
    )
    m1
    (
            .clk(clk), .rst_n(intf1.rst_n), .en(intf1.en), 
            .wr(intf1.wr), .addr(intf1.addr), .data_in(intf1.data_in), 
            .data_out(intf1.data_out), .valid_out(intf1.valid_out)
            );

    initial begin

       vif1 = intf1;
       uvm_config_db#(virtual mem_if)::set(uvm_root::get() , "*" , "vif", intf1);



        run_test("my_test");


    end

endmodule