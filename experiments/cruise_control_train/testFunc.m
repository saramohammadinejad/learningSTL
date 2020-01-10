ccc;
sims = 20;
arr = [];
v_acc = [];
for ss = 1:sims
    if mod(ss, 100) == 0
        disp(ss);
    end
    ss
    fsm_code;
    arr = [arr, nfail/N];
    figure(1);
    plot(1:length(v), v); hold on;
    figure(2);
    plot(1:length(ti), ti); hold on;
    
    %     disp(size(v));
end
sprintf('Success rate: %0.2f %%', (1 - (sum(arr) / sims)) * 100)
size(v_acc);