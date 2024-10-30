all: counter

counter: counter.v counter_tb.v
	iverilog -o counter_tb.vvp counter_tb.v counter.v && \
	vvp counter_tb.vvp && \
	gtkwave counter_waveform.vcd

shift_register: shift_register.v shift_register_tb.v
	iverilog -o shift_register_tb.vvp shift_register_tb.v shift_register.v && \
	vvp shift_register_tb.vvp && \
	gtkwave shift_register_waveform.vcd

clean:
	rm *.vcd *.vvp