module shift_register(
    input wire i_clock
);

    reg test1 = 1'b1;
    reg test2 = 1'b0;
    reg test3 = 1'b0;
    reg test4 = 1'b0;

    always @(posedge i_clock) begin
        test2 <= test1;
        test3 <= test2;
        test4 <= test3;
    end

endmodule
