module baud_rate_generator (
    input  clk,
    input  rst,
    output tx_enb,
    output rx_enb
);

    reg [12:0] tx_counter;
    reg [9:0]  rx_counter;

    always @(posedge clk) begin
        if (rst)
            tx_counter <= 0;
        else if (tx_counter == 5208)
            tx_counter <= 0;
        else
            tx_counter <= tx_counter + 1'b1;
    end

    always @(posedge clk) begin
        if (rst)
            rx_counter <= 0;
        else if (rx_counter == 325)
            rx_counter <= 0;
        else
            rx_counter <= rx_counter + 1'b1;
    end

    assign tx_enb = (tx_counter == 0) ? 1'b1 : 1'b0;
    assign rx_enb = (rx_counter == 0) ? 1'b1 : 1'b0;

endmodule


module uart_tx_top (
    input        clk,
    input        rst,
    input        wr_enb,
    input  [7:0] data_in,
    output       tx,
    output       busy
);

    wire tx_enb;

    baud_rate_generator baud_gen (
        .clk(clk),
        .rst(rst),
        .tx_enb(tx_enb)
    );

    transmitter uart_tx (
        .clk(clk),
        .rst(rst),
        .wr_enb(wr_enb),
        .enb(tx_enb),
        .data_in(data_in),
        .tx(tx),
        .busy(busy)
    );

endmodule


module transmitter (
    input        clk,
    input        rst,
    input        wr_enb,
    input        enb,
    input  [7:0] data_in,
    output reg   tx,
    output       busy
);

    parameter idle_state  = 2'b00;
    parameter start_state = 2'b01;
    parameter data_state  = 2'b10;
    parameter stop_state  = 2'b11;

    reg [7:0] data;
    reg [2:0] index;
    reg [1:0] state;

    always @(posedge clk) begin

        if (rst) begin
            state <= idle_state;
            data  <= 8'b0;
            index <= 3'b000;
        end

        else begin
            case (state)

                idle_state: begin
                    if (wr_enb) begin
                        data  <= data_in;
                        index <= 3'b000;
                        state <= start_state;
                    end
                    else begin
                        state <= idle_state;
                    end
                end

                start_state: begin
                    if (enb) begin
                        state <= data_state;
                    end
                    else begin
                        state <= start_state;
                    end
                end

                data_state: begin
                    if (enb) begin

                        if (index == 3'b111) begin
                            state <= stop_state;
                            index <= 3'b000;
                        end
                        else begin
                            index <= index + 3'b001;
                        end

                    end
                    else begin
                        state <= data_state;
                    end
                end

                stop_state: begin
                    if (enb) begin
                        state <= idle_state;
                    end
                    else begin
                        state <= stop_state;
                    end
                end

                default: begin
                    state <= idle_state;
                    data  <= 8'b0;
                    index <= 3'b000;
                end

            endcase
        end
    end

    always @(*) begin

        case (state)

            idle_state:
                tx = 1'b1;

            start_state:
                tx = 1'b0;

            data_state:
                tx = data[index];

            stop_state:
                tx = 1'b1;

            default:
                tx = 1'b1;

        endcase

    end

    assign busy = (state != idle_state);

endmodule


module uart_rx_top (
    input        clk,
    input        rst,
    input        rx,
    output [7:0] data_out,
    output       valid
);

    wire rx_enb;

    baud_rate_generator baud_gen (
        .clk(clk),
        .rst(rst),
        .rx_enb(rx_enb)
    );

    uart_receiver uart_rx (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .rx_enb(rx_enb),
        .data_out(data_out),
        .data_valid(valid)
    );

endmodule


module uart_receiver (
    input        clk,
    input        rst,
    input        rx,
    input        rx_enb,
    output reg [7:0] data_out,
    output reg       data_valid
);

    parameter idle_state  = 2'b00;
    parameter start_state = 2'b01;
    parameter data_state  = 2'b10;
    parameter stop_state  = 2'b11;

    reg [1:0] state;
    reg [7:0] data;
    reg [2:0] index;
    reg [3:0] count;

    always @(posedge clk) begin

        if (rst) begin
            state      <= idle_state;
            data       <= 8'b0;
            index      <= 3'b000;
            count      <= 4'b0000;
            data_out   <= 8'b0;
            data_valid <= 1'b0;
        end

        else begin

            data_valid <= 1'b0;

            case (state)

                idle_state: begin
                    if (!rx) begin
                        count <= 4'b0000;
                        state <= start_state;
                    end
                end

                start_state: begin
                    if (rx_enb) begin

                        if (count == 4'd7) begin

                            if (!rx) begin
                                count <= 4'b0000;
                                index <= 3'b000;
                                state <= data_state;
                            end
                            else begin
                                state <= idle_state;
                            end

                        end
                        else begin
                            count <= count + 1'b1;
                        end

                    end
                end

                data_state: begin
                    if (rx_enb) begin

                        if (count == 4'd15) begin

                            data[index] <= rx;
                            count <= 4'b0000;

                            if (index == 3'b111)
                                state <= stop_state;
                            else
                                index <= index + 1'b1;

                        end
                        else begin
                            count <= count + 1'b1;
                        end

                    end
                end

                stop_state: begin
                    if (rx_enb) begin

                        if (count == 4'd15) begin

                            if (rx) begin
                                data_out   <= data;
                                data_valid <= 1'b1;
                            end

                            state <= idle_state;
                            count <= 4'b0000;

                        end
                        else begin
                            count <= count + 1'b1;
                        end

                    end
                end

                default: begin
                    state <= idle_state;
                    data  <= 8'b0;
                    index <= 3'b000;
                    count <= 4'b0000;
                end

            endcase
        end
    end

endmodule