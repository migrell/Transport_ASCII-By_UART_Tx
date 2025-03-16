module baud_test(
    input clk,
    input rst,
    output test_tick,
    output debug_led
);
    // 보드레이트 정확도 테스트 모듈
    
    // 보드레이트 생성기
    wire baud_tick, sample_tick;
    baud_tick_gen U_BAUD_GEN (
        .clk(clk),
        .rst(rst),
        .baud_tick(baud_tick),
        .sample_tick(sample_tick)
    );
    
    // 카운터 및 타이밍 측정
    reg [15:0] interval_counter;
    reg [15:0] last_interval;
    reg tick_detected;
    
    // 출력 할당
    assign test_tick = baud_tick;
    assign debug_led = (last_interval != 10417); // 예상 간격과 다르면 LED 켜기
    
    // 틱 간격 측정
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            interval_counter <= 0;
            last_interval <= 0;
            tick_detected <= 0;
        end else begin
            interval_counter <= interval_counter + 1;
            
            if (baud_tick) begin
                if (tick_detected) begin
                    last_interval <= interval_counter;
                    interval_counter <= 0;
                end else begin
                    tick_detected <= 1;
                    interval_counter <= 0;
                end
            end
        end
    end
endmodule