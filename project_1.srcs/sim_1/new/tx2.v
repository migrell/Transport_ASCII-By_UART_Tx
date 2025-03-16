`timescale 1ns / 1ps

module tb_send_tx_btn();
    // 입력 신호 선언
    reg clk;
    reg rst;
    reg btn_start;
    
    // 출력 신호 선언
    wire tx;
    wire tx_done;
    
    // DUT(Device Under Test) 인스턴스화
    send_tx_btn dut(
        .clk(clk),
        .rst(rst),
        .btn_start(btn_start),
        .tx_done(tx_done),
        .tx(tx)
    );
    
    // 클럭 생성 (100MHz = 10ns 주기)
    always #5 clk = ~clk;
    
    // 테스트 시나리오
    initial begin
        // 초기값 설정
        clk = 1'b0;
        rst = 1'b1;
        btn_start = 1'b0;
        
        // 리셋 해제
        #100 rst = 1'b0;
        
        // 첫 번째 문자 전송
        #100 btn_start = 1'b1;
        #20 btn_start = 1'b0;
        
        // tx_done 신호가 다시 HIGH가 될 때까지 대기
        wait(tx_done == 1'b1);
        #1000;
        
        // 두 번째 문자 전송
        #100 btn_start = 1'b1;
        #20 btn_start = 1'b0;
        
        // tx_done 신호가 다시 HIGH가 될 때까지 대기
        wait(tx_done == 1'b1);
        #1000;
        
        // 세 번째 문자 전송
        #100 btn_start = 1'b1;
        #20 btn_start = 1'b0;
        
        // tx_done 신호가 다시 HIGH가 될 때까지 대기
        wait(tx_done == 1'b1);
        #1000;
        
        // 시뮬레이션 종료
        $finish;
    end
endmodule