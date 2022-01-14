function demod(data, reference, L, spec_pilot)

% нечетные в inphase - 1, 3, 5, ...
% четные в quad - 2, 4, 6, ...
inphase = data(1:2:end);
quad = data(2:2:end);

[m1, n1] = size(inphase);
[m2, n2] = size(quad);

if isempty(inphase)
    error('Что то пошло не так!')
end

if m1 ~= m2
    error('m1 и m2 не совпадают!')
else
    if n1 ~= n2
        error(['n1 и n2 не совпадают! n1 = ', num2str(length(n1)), 'n2 = ', num2str(length(n2))])
    end
end

try
    % создаём комплексный массив
    compl = complex(inphase, quad);
    % спектр комплексного массива
    fft_com = fft(compl);
catch ME
    disp(ME)
end

formatSpec = 'Спектр полученного комплесного массива compl. Его размер = %d';
len = length(fft_com);
str_1 = sprintf(formatSpec, len);
figure;
plot(abs(fft_com));
title(str_1);

scatterplot(fft_com);
title('созвездие спектра (fft com)');grid on;
% Корреляция с сдвинутым спектром с нулями
[corrr2, lags2] = xcorr(reference, compl);
[~, pos2] = max(corrr2);
tlag = lags2(pos2);

figure;
plot(lags2,abs(corrr2));
figure;
plot(abs(corrr2));
% Корреляция с сдвинутым спектром без нулей
% [corrr3, lags3] = xcorr(spec_time, compl);

% Зная начало кадра, вырезаем массив длинной 2*L, т.е.
% 2*10240. Это 2 OFDM символа
try
    newsum = compl(abs(tlag):abs(tlag) + length(reference));
catch me
    disp(me.message);
    newsum = compl(abs(tlag) - length(reference):abs(tlag));
end
newspec = fft(newsum);

figure;
plot(abs(newspec));
title('newspec');

% вырезаем пилот и дату, переводим в частотн. область
pil_time_Rx = newsum(1:L);
pil_freq_Rx = fft(pil_time_Rx);
sig_time_Rx = newsum(L+1:end);
sig_freq_Rx = fft(sig_time_Rx);

figure;
subplot(2,1,1);
plot(abs(pil_freq_Rx));title('pil time Rx');
subplot(2,1,2);
plot(abs(sig_freq_Rx));title('sig time Rx');

% вырезаем половинки спектра, одну в начле, вторую в конце
pilcut = [pil_freq_Rx(1:512), pil_freq_Rx(end - 511:end)];
datacut = [sig_freq_Rx(1:512), sig_freq_Rx(end - 511:end)];
% Правая часть нашего символа находится слева, а левая справа
% поменяем их местами
pilshift = fftshift(pilcut);
datashift = fftshift(datacut);

figure;
subplot(2, 1, 1);
plot(abs(pilshift));title('pilshift');grid on;
subplot(2, 1, 2);
plot(abs(datashift));title('datashift');grid on;

scatterplot(pilshift);title('pilshift');
% Оценка искажения спектра _|-|-|_
ocen = pilshift./spec_pilot;
figure;
plot(abs(ocen));title('ocen');
scatterplot(ocen);title('ocen');
% scatterplot(newcut);
% title('Созвездие вырезанного спектра');

% восстановление data по передаточной функции вычисленной по pilot
recov = datashift./ocen;
figure;
plot(abs(recov));title('recov');
scatterplot(recov);title('recov');

figure;
subplot(2,2,1);
% график модуля спектра
plot(abs(fft_com));
title('График спектра принятого');
subplot(2,2,2);
plot(abs(corrr2));
title('Корреляция');
subplot(2,2,3);
% newcut вырезанный из спектра символ длиной 1024
plot(abs(recov));title('Вырезанный символ');
% subplot(2,2,4);
% plot(abs(cutshift));title('Принятый OFDM символ');

return;
% Здесь нужно рассмотреть получше
clean_data = [recov(Protection_Interval:Protection_Interval + length(mod_data_send)/2- 1), recov(Protection_Interval + length(mod_data_send)/2 + 1:Fourier_length - Protection_Interval)];

k=1;
for i = 1:length(clean_data)
    if real(clean_data(i)) >0 && imag(clean_data (i)) >0
        bits_demod_r (k) = 1; bits_demod_r (k+1) = 1;
    end
    if real(clean_data (i)) <0 && imag(clean_data(i)) >0
        bits_demod_r (k) = 0; bits_demod_r (k+1) = 1;
    end
	if real(clean_data (i)) >0 && imag(clean_data (i)) <0
        bits_demod_r (k) = 1; bits_demod_r (k+1) = 0;
    end
    if real(clean_data (i)) <0 && imag(clean_data (i)) <0
        bits_demod_r (k) = 0; bits_demod_r (k+1) = 0;
    end
    k=k+2;
end

err = biterr(bits_demod_r, bits(1648 + 1: 1648 +  1648));