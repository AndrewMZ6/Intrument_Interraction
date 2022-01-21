p = [10e6, 20e6, 30e6, 40e6, 50e6, 60e6, 70e6, 80e6];
for i = 1:100
%     clc;
    close all;
    disp(['----> iteration ', num2str(i)])
    h1 = p(randi(8));
    % Генерируем сигнал
    [ref, L, spec_pilot] = generateSig(h1);
    disp(['fs for generateSig = ', num2str(h1)])
    % Отправляем в генератор cxg
    h1 = p(randi(8));
    sendToCxg(getInstrID('cxg'), ref,h1);
    disp(['fs for cxg = ', num2str(h1)])
    
    % Получаем данные с анализатора exa
    h1 = p(randi(8));
    a = getFromExa(getInstrID('exa'), h1);
    disp(['fs for exa = ', num2str(h1)])
    % Демодулируем
    demod(a, ref, L, spec_pilot);
    
end
return
%% Моделирование канала передачи

h = zeros(1, 1024);
h(1) = 1;
h(10) = 0.75;
h(50) = 0.5;
H = fft(h);

figure;
subplot(2, 1, 1)
plot(abs(H))
subplot(2, 1, 2)
plot(h)


%%  WG + OSCI

[ref,~,~,~,sig] = generateSig(50e6, 10240, 30e6);
sendToWg(getInstrID('wg'), sig);
return;
rx = getFromOsci(getInstrID('dsox'));

specRx = fft(rx);

figure;
subplot(2, 1, 1);
plot(rx);
subplot(2, 1, 2);
plot(abs(specRx(2:end)));
