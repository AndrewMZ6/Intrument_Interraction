function [ref2_time, L, spec_pilot, ref1_time, SENT_TO_WAVEFORM_GENERATOR] = generateSig(fs, L, fc, Fourier_length, Protection_Interval)

% function [ref1_time, ref2_time, SENT_TO_WAVEFORM_GENERATOR] = generateSig(Fourier_length, Protection_Interval, N, fc, fs,L)
%
% Fourier_length - длина Фурье OFDM символа
% Protection_Interval - длина защитного интервала
% fc - f carrier - несущая частота
% fs - f sampling - частота дискретизации
% L - длина интерполированного символа (дополненного нулями)
% ref1_time - пилот и данные во временной области (без дополнения нулями на нулевой частоте)
% ref2_time - пилот и данные во временной области (дополненные нулями на нулевой частоте)
% SENT_TO_WAVEFORM_GENERATOR - ref2_time, перенесённый на несущую fc
%
% Функция

% Параметры по умолчанию
if (nargin < 5) 
    Protection_Interval = 100; end
if (nargin < 4) 
    Fourier_length = 1024; end
if (nargin < 3)
    fc = 10e6; end
if (nargin < 2)
    L = 10*1024; end
if (nargin < 1)
    fs = 20e6; end

% Формирование проверочного сигнала
N = Fourier_length*4 + 2*Protection_Interval;
bits = randi([0, 1], 1, N);

fstep = fs/L ;
f = 0:fstep:fstep*(L - 1);

% QPSK модуляция битовой последовательности bits
k = 1;
for i = 1:2:N
    if bits(i) == 1 && bits(i+1) == 1
        mod_data(k) = 1 + 1i;
    end
    if bits(i) == 1 && bits(i+1) == 0
        mod_data(k) = 1 - 1i;
    end
    if bits(i) == 0 && bits(i+1) == 1
        mod_data(k) = -1 + 1i;
    end
    if bits(i) == 0 && bits(i+1) == 0
        mod_data(k) = -1 - 1i;
    end
    
    k = k + 1;
end

% mod_data - это массив комплексных чисел, попрано созданный из массива
% bits, где первому числу из пары присваивается реальная ось, а второму мнимая. Поэтому массив mod_data
% и в два раза меньше
% Длина mod_data в 2 раза меньше N, т.к. на одну ПАРУ бит N приходится
% только ОДНО значение

% вырезаем данные длиной 824 из произвольного массива данных
mod_data_send = mod_data(1:Fourier_length - 2*Protection_Interval); 
% вырезаем пилотные данные длиной 824
pilot_data = mod_data(Fourier_length - 2*Protection_Interval + 1: 2*Fourier_length - 4*Protection_Interval);
% добавляем слева и справа защитные интервалы и 0 для несущей
spectrum = [zeros(1, Protection_Interval - 1), mod_data_send(1:length(mod_data_send)/2), 0, mod_data_send(length(mod_data_send)/2+1:end), zeros(1, Protection_Interval)];
spec_pilot=[zeros(1, Protection_Interval - 1), pilot_data(1:length(pilot_data)/2), 0, pilot_data(length(pilot_data)/2+1:end), zeros(1, Protection_Interval)];
% Созданные нами спектры структурно выглядят следующим образом:
% [99нулей, 412компл.значений,0длянесущей,412компл.значений, 100нулей]

% cдвиг спектра делит спектр попалам и помещает правую часть
% влево, а левую вправо
% _|-|-|_  -->  -|_ _|-|
spectrum_shifted = fftshift(spectrum);
pilot_shifted = fftshift(spec_pilot);


% Тест. ОБПФ
spec_time = ifft(spectrum_shifted);
spec_time_pilot = ifft(pilot_shifted);
ref1_time = [spec_time_pilot, spec_time];

% между сдвинутыми половинами спектра вставляем нули
% L определяет длину получившегося массива
% -|_ _|-|  -->  -|_00000000000000000000000000000_|-|
spec_zeros = ([spectrum_shifted(1:Fourier_length/2), zeros(1, (L -Fourier_length)), spectrum_shifted(Fourier_length/2 + 1:end)]);
pilot_zeros = ([pilot_shifted(1:Fourier_length/2), zeros(1, (L -Fourier_length)), pilot_shifted(Fourier_length/2 + 1:end)]);

% переводим полученный спектр во временную область
sig_time = ifft(spec_zeros);
pil_time = ifft(pilot_zeros);
ref2_time = [pil_time, sig_time];

% выделяем реальную (синфазную) и мнимую(квадратурную) части
% REAL->I, IMAG->Q
I = real(sig_time);
Ip = real(pil_time);
Q = imag(sig_time);
Qp = imag(pil_time);

% задаём массив времени, и несущие
t_sig = [0:length(I) - 1]/fs;
% t_sig = (0:1:L-1)/fs;
sig_carrQ = -sin(2*pi*fc*t_sig);
sig_carrI = cos(2*pi*fc*t_sig);

% Посадка на несущую I и Q составляющих
for i = 1:length(I)
    Ip_mod(i) = Ip(i)*sig_carrI(i);
    I_mod(i) = I(i)*sig_carrI(i);
end

for i = 1:length(Q)
    Qp_mod(i) = Qp(i)*sig_carrQ(i);
    Q_mod(i) = Q(i)*sig_carrQ(i);
end

% Суммирование I и Q составляющих отдельно пилотов и отдельно данных
for i = 1:length(I)
    pilot_to_wg(i) = Ip_mod(i) + Qp_mod(i);
    data_to_wg(i) = I_mod(i) + Q_mod(i);
end

% Формируем конечный массив путём конкатенации полученных ранее сумм
SENT_TO_WAVEFORM_GENERATOR = [pilot_to_wg, data_to_wg];

% как выглядит SENT_TO_WAVEFORM_GENERATOR
sent_fft = fft(SENT_TO_WAVEFORM_GENERATOR);

% figure(4)
% subplot(2,1,1)
% plot(abs(fft(SENT_TO_WAVEFORM_GENERATOR)))
% 
% subplot(2,1,2)
% plot(sig_carrI)
% hold on
% plot(sig_carrQ)
% hold off
% xlim([1, 100]);
% grid on
% return
% SENT_TO_WAVEFORM_GENERATOR = spectrum;

% Длительность сигнала = кол-точек*период дискретизации
% С учетом интерполяии L точек
t_L = (L/fs)*1e6; % микросекунды
% Без учета интерполяции Fourier_length точек
t_F = (Fourier_length/fs)*1e6;


figure;
subplot(2,2,1);
plot( abs(spectrum_shifted));
title('ref1 time spectrum (one part)');xlabel('n');ylabel('Amplitude');grid on;
subplot(2,2,2);
plot(abs(spec_zeros));
title('ref2 time spectrum (one part)');xlabel('n');ylabel('Amplitude');grid on;
subplot(2,2,3);
plot(abs(sent_fft));
title('SENT TO WAVEFORM GENERATOR spectrum');xlabel('n');ylabel('Amplitude');grid on;

return;