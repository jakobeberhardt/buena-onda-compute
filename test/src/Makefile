all: counter

counter: counter.v counter_tb.v
	iverilog -o counter_tb.vvp counter_tb.v counter.v && \
	vvp counter_tb.vvp && \
	gtkwave counter_waveform.vcd

clean:
	rm *.vcd *.vvp