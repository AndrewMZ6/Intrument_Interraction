clc;
close all;

% Генерируем сигнал
[ref, L, spec_pilot] = generateSig(20e6);
% Отправляем в генератор cxg
sendToCxg(getInstrID('cxg'), ref,20e6);
% Получаем данные с анализатора exa
a = getFromExa(getInstrID('exa'), 20e6);
% Демодулируем
demod(a, ref, L, spec_pilot);


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

[~,~,~,~,sig] = generateSig(50e6);
sendToWg(getInstrID('wg'), sig, 20e6);
rx = getFromOsci(getInstrID('dsox'));

specRx = fft(rx);

figure;
subplot(2, 1, 1);
plot(rx);
subplot(2, 1, 2);
plot(abs(specRx(2:end)));
