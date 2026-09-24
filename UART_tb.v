`timescale 1ns/1ps

module uart_tb;

    reg clk;
    reg rst;
    reg wr_enb;
    reg [7:0] data_in;

    wire tx;
    wire busy;

    wire [7:0] data_out;
    wire valid;

    uart_tx_top tx_module (
        .clk(clk),
        .rst(rst),
        .wr_enb(wr_enb),
        .data_in(data_in),
        .tx(tx),
        .busy(busy)
    );

    uart_rx_top rx_module (
        .clk(clk),
        .rst(rst),
        .rx(tx),
        .data_out(data_out),
        .valid(valid)
    );

    always #10 clk = ~clk;

    initial begin

        $dumpfile("uart.vcd");
        $dumpvars(0, uart_tb);

        clk = 1'b0;
        rst = 1'b1;
        wr_enb = 1'b0;
        data_in = 8'b0;

        #100;

        rst = 1'b0;

        #100;

        data_in = 8'b10110010;
        wr_enb = 1'b1;

        #20;

        wr_enb = 1'b0;

        wait(valid);

        #20;

        if (data_out == data_in)
            $display("TEST PASSED");
        else
            $display("TEST FAILED");

        $display("Sent     = %b", data_in);
        $display("Received = %b", data_out);

        #100;

        $finish;

    end

endmodule