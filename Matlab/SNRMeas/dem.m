function err = dem(data, params)

% Распаковка пакета необходимого для демодуляции

RECO = params{1};
car_sig = params{2};
L = params{3};
DATA = params{4};

% без пакета params функция выглядела так:
% function err = dem(data, RECO, car_sig, L, DATA);

% считаем корреляцию принятого с осциллографа массива data и отправленного на генератор RECO
[corr, lags] = xcorr(RECO,data);

% находим Х координату масимума корреляции (Y значение нас не интересует)
[~, m] = max(corr);

% находим какое значение задержки соответствует Х координате максимума корреляции
delay = lags(m);

try
    % вырезаем данные длиной length(RECO) начиная с отсчёта abs(delay). -1 ставится так как в диапазон попадает
    % значение abs(delay)
    cut = data(abs(delay):abs(delay) + length(RECO) - 1);
catch me
    % если индекс вырезаемого массива превосходит длину data, то вырезаем предшествующий блок
    disp(me.message);
    cut = data(abs(delay) - length(RECO) + 1:abs(delay));
end

% Верните BPSK последовательность на нулевую частоту, повторно перемножив BPSK
% последовательность с гармоническим сигналом. 
REVIVE =cut.*car_sig;

% Выполните фильтрацию полученных данных на нулевой частоте путем интегрирования 
% здесь в качестве делителя берется значение L/2, т.к. значения чередуются с нулями 
for i=1:length(REVIVE)/L
    a(i) = sum(REVIVE(i*L-L+1:i*L))/(L/2);
    y(i*L-L+1:L*i) = a(i);
end

% Произведите децимацию, а затем демодуляцию полученных данных. Цель демодуляции –
% преобразовать сигнал в битовый поток
decim = y(L:L:end);
for i=1:length(decim)
    if ((decim(i))<0)
        demod(i) = 0;
    else 
        demod(i) = 1;
    end
end

% Посчитайте ошибки с помощью функции biterr().
[~, err] = biterr(DATA, demod);
return;
