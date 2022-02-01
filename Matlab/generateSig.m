function [basebandInterp, L, specPilot, basebandNoInterp, passband] = generateSig(fs, L, fc, fourierLength, guardInterval)

% function [basebandInterp, L, specPilot, basebandNoInterp, passband] = generateSig(fs, L, fc, fourierLength, guardInterval)
%
% fourierLength - длина Фурье OFDM символа
% guardInterval - длина защитного интервала
% fc - f carrier - несущая частота
% fs - f sampling - частота дискретизации
% L - длина интерполированного символа (дополненного нулями)
% basebandNoInterp - пилот и данные во временной области (без дополнения нулями на нулевой частоте)
% basebandInterp - пилот и данные во временной области (дополненные нулями на нулевой частоте)
% passband - это сигнал basebandInterp, перенесённый на несущую fc
%
% Функция

% Параметры по умолчанию
if (nargin < 5) 
    guardInterval = 100; end
if (nargin < 4) 
    fourierLength = 1024; end
if (nargin < 3)
    fc = 10e6; end
if (nargin < 2)
    L = 10*1024; end
if (nargin < 1)
    fs = 50e6; end

% Формирование случайной битовой последовательности
N = fourierLength*4 + 2*guardInterval;
bits = randi([0, 1], 1, N);

% QPSK модуляция битовой последовательности bits
k = 1;
for i = 1:2:N
    if bits(i) == 1 && bits(i+1) == 1
        modData(k) = 1 + 1i;
    end
    if bits(i) == 1 && bits(i+1) == 0
        modData(k) = 1 - 1i;
    end
    if bits(i) == 0 && bits(i+1) == 1
        modData(k) = -1 + 1i;
    end
    if bits(i) == 0 && bits(i+1) == 0
        modData(k) = -1 - 1i;
    end
    
    k = k + 1;
end

% modData - это массив комплексных чисел, попрано созданный из массива
% bits, где первому числу из пары присваивается реальная ось, а второму мнимая. Поэтому массив modData
% и в два раза меньше
% Длина mod_data в 2 раза меньше N, т.к. на одну ПАРУ бит N приходится
% только ОДНО значение

% вырезаем данные длиной 824 из массива данных modData
modDataSend = modData(1:fourierLength - 2*guardInterval); 
% вырезаем пилотные данные длиной 824
pilotData = modData(fourierLength - 2*guardInterval + 1: 2*fourierLength - 4*guardInterval);
% добавляем слева и справа защитные интервалы и 0 для несущей
spectrum = [zeros(1, guardInterval - 1), modDataSend(1:length(modDataSend)/2), 0, modDataSend(length(modDataSend)/2+1:end), zeros(1, guardInterval)];
specPilot=[zeros(1, guardInterval - 1), pilotData(1:length(pilotData)/2), 0, pilotData(length(pilotData)/2+1:end), zeros(1, guardInterval)];
% Созданные нами спектры структурно выглядят следующим образом:
% [99нулей, 412компл.значений,0длянесущей,412компл.значений, 100нулей]

% cдвиг спектра делит спектр попалам и помещает правую часть
% влево, а левую вправо
% _|-|-|_  -->  -|_ _|-|
specShifted = fftshift(spectrum);
pilotShifted = fftshift(specPilot);


% Тест. ОБПФ
specTime = ifft(specShifted);
specTimePilot = ifft(pilotShifted);
basebandNoInterp = [specTimePilot, specTime];

% между сдвинутыми половинами спектра вставляем нули
% L определяет длину получившегося массива
% -|_ _|-|  -->  -|_00000000000000000000000000000_|-|
specZeros = ([specShifted(1:fourierLength/2), zeros(1, (L -fourierLength)), specShifted(fourierLength/2 + 1:end)]);
pilotZeros = ([pilotShifted(1:fourierLength/2), zeros(1, (L -fourierLength)), pilotShifted(fourierLength/2 + 1:end)]);

% переводим полученный спектр во временную область
sigTime = ifft(specZeros);
pilTime = ifft(pilotZeros);
basebandInterp = [pilTime, sigTime];

% выделяем реальную (синфазную) и мнимую(квадратурную) части
% REAL->I, IMAG->Q
I = real(sigTime);
Ip = real(pilTime);
Q = imag(sigTime);
Qp = imag(pilTime);

% задаём массив времени, и несущие
t_sig = [0:length(I) - 1]/fs;
% t_sig = (0:1:L-1)/fs;
sigCarrQ = -sin(2*pi*fc*t_sig);
sigCarrI = cos(2*pi*fc*t_sig);

% Посадка на несущую I и Q составляющих
for i = 1:length(I)
    IpMod(i) = Ip(i)*sigCarrI(i);
    IMod(i) = I(i)*sigCarrI(i);
end

for i = 1:length(Q)
    QpMod(i) = Qp(i)*sigCarrQ(i);
    QMod(i) = Q(i)*sigCarrQ(i);
end

% Суммирование I и Q составляющих отдельно пилотов и отдельно данных
for i = 1:length(I)
    pilotToWg(i) = IpMod(i) + QpMod(i);
    dataToWg(i) = IMod(i) + QMod(i);
end

% Формируем конечный массив путём конкатенации полученных ранее сумм
passband = [pilotToWg, dataToWg];

% как выглядит спектр passband
senfFFT = fft(passband);

% Длительность сигнала = кол-точек*период дискретизации
% С учетом интерполяии L точек
t_L = (L/fs)*1e6; % микросекунды
% Без учета интерполяции Fourier_length точек
t_F = (fourierLength/fs)*1e6;

% Сводная информация о полученных данных
figure;
subplot(2,2,1);
plot( abs(specShifted));
title('basebandNoInterp');xlabel('n');ylabel('Amplitude');grid on;
subplot(2,2,2);
plot(abs(specZeros));
title('basebandInterp');xlabel('n');ylabel('Amplitude');grid on;
subplot(2,2,3);
plot(abs(senfFFT));
title('passband');xlabel('n');ylabel('Amplitude');grid on;

return;
