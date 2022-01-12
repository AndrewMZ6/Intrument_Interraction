%% Необходимые предваительные установки
% 1 Драйвер инструмента (на сайте производителя)
% 2 Keysight Connection Expert, который является частью IO Libraries Siute(для устновки visa)
% Или NI VISA

% Переключение между блоками: Ctrl + стрелка вверх/вниз
%% Формирование проверочного сигнала

clear all;
close all;

% длина символа
Fourier_length = 1024;
% защитный интервал
Protection_Interval = 100; 
% длина
N = 3648;               
bits = randi([0, 1], 1, N);
% randi - Uniformly distributed pseudorandmom integers
% X = randi([imin, imax], strings, columns)

fc = 10e6;
fs = 50e6;
L = 10*1024;  % 10240

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
pilot_data = mod_data(Fourier_length - 2*Protection_Interval + 1: Fourier_length - 2*Protection_Interval + 824);
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

figure;
plot(abs(fft(ref1_time)));

% между сдвинутыми половинами спектра вставляем нули
% L определяет длину получившегося массива
% -|_ _|-|  -->  -|_00000000000000000000000000000_|-|
spec_zeros = ([spectrum_shifted(1:Fourier_length/2), zeros(1, (L -1024)), spectrum_shifted(Fourier_length/2 + 1:end)]);
pilot_zeros = ([pilot_shifted(1:Fourier_length/2), zeros(1, (L -1024)), pilot_shifted(Fourier_length/2 + 1:end)]);

% переводим полученный спектр во временную область
sig_time = ifft(spec_zeros);
pil_time = ifft(pilot_zeros);
ref2_time = [pil_time, sig_time];

figure;
plot(abs(fft(pil_time)));

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
plot( abs(spectrum));
title('Original OFDM symbol');xlabel('n');ylabel('Amplitude');grid on;
subplot(2,2,2);
plot(abs(spec_zeros));
title('Shift + zeros interp');xlabel('n');ylabel('Amplitude');grid on;
subplot(2,2,3);
plot(abs(sent_fft));
title('Bandpass spectrum');xlabel('freq');ylabel('Amplitude');grid on;

%% Waveform Generator 33500B USB visa 
% Этот блок игнорируется если соединение происходит через LAN см. блок "Waveform Generator 33500B LAN"
% Идентификатор (4 аргумент) берется из Keysight Connection Expert
WG_obj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0957::0x2807::MY57401328::0::INSTR', 'Tag', '');

if isempty(WG_obj) % В аргументах visa может применяться новое название 'KEYSIGHT', 
    % а может и старое 'AGILENT'.
    WG_obj = visa('Agilent', 'USB0::0x0957::0x2807::MY57401328::0::INSTR');
else
    fclose(WG_obj);
    WG_obj = WG_obj(1);
end

% Подстчет производится из расчёта 8 бит на 1 точку
obj_buffer = length(SENT_TO_WAVEFORM_GENERATOR)*8;
set (WG_obj,'OutputBufferSize',(obj_buffer+125));
% Время ожидания запроса
WG_obj.Timeout = 10;

% Установка соедининения
try
   fopen(WG_obj);
catch exception %problem occurred throw error message
    uiwait(msgbox('Error occurred trying to connect to the 33522, verify correct IP address','Error Message','error'));
    rethrow(exception);
end

%% Waveform Generator 33500B LAN 
% Этот блок игнорируется если соединение происходит через USB см. блок "Waveform Generator 33500B USB visa"
% Чтобы посмотреть ip генератора - кнопка System -> I/O config -> LAN
% settings
WG_obj = instrfind('Type', 'tcpip', 'RemoteHost', '192.168.0.3', 'RemotePort', 5025, 'Tag', '');

% Сценарий соединения с инструментом взят из tmtool
% Create the tcpip object if it does not exist
% otherwise use the object that was found.
if isempty(WG_obj)
    WG_obj = tcpip('192.168.0.3', 5025);
else
    fclose(WG_obj);
    WG_obj = WG_obj(1);
end

% Подстчет производится из расчёта 8 бит на 1 точку
obj_buffer = length(SENT_TO_WAVEFORM_GENERATOR)*8;
set (WG_obj,'OutputBufferSize',(obj_buffer+125));
% Время ожидания запроса
WG_obj.Timeout = 10;

% Установка соедининения
try
   fopen(WG_obj);
catch exception %problem occurred throw error message
    uiwait(msgbox('Error occurred trying to connect to the 33522, verify correct IP address','Error Message','error'));
    rethrow(exception);
end

%% Отправка данных на генератор 33500B(этот блок общий как для LAN так и для USB и запускается после соединения с инструментом)
% Запрос имени инструмента
fprintf (WG_obj, '*IDN?');
idn = fscanf (WG_obj);
fprintf (idn)
fprintf ('\n\n')

% Название вашего массива в инстументе
name = 'my_waveforms';
% Задание частоты дискретизации
sRate = fs;
% Задание величины амлитуды
amp = 0.1;

% Создания полосы загрузки
mes = ['Connected to ' idn ' sending waveforms.....'];
h = waitbar(0,mes);

% Сбросить настройки инструмента
fprintf (WG_obj, '*RST');

% Убеждаемся, что массив представлен в виде строки, а не столбцов
if isrow(SENT_TO_WAVEFORM_GENERATOR) == 0
    SENT_TO_WAVEFORM_GENERATOR = SENT_TO_WAVEFORM_GENERATOR';
end

% Некоторые версии Matlab требую double
SENT_TO_WAVEFORM_GENERATOR = single(SENT_TO_WAVEFORM_GENERATOR);

% Включить или выключить встроенный фильтр на генераторе
ON_OFF_FILTER_CH1 = ['SOURce1:FUNCtion:ARBitrary:FILTer ', 'OFF'];
fprintf(WG_obj, ON_OFF_FILTER_CH1); 

% Размещаем данные между 1 и -1
mx = max(abs(SENT_TO_WAVEFORM_GENERATOR));
SENT_TO_WAVEFORM_GENERATOR = (1*SENT_TO_WAVEFORM_GENERATOR)/mx;

% Обновляем окно загрузки
waitbar(.1,h,mes);

% Очистка временной памяти
fprintf(WG_obj, 'SOURce1:DATA:VOLatile:CLEar'); 

% Устанавливаем порядок следования байт
% BORD = Byte ORDer
fprintf(WG_obj, 'FORM:BORD SWAP');  

% Количество байт
SENT_TO_WG_Bytes=num2str(length(SENT_TO_WAVEFORM_GENERATOR) * 4); 

% Создание заголовка для binblock
header= ['SOURce1:DATA:ARBitrary ', name, ', #', num2str(length(SENT_TO_WG_Bytes)), SENT_TO_WG_Bytes]; 

% Конвертация данных в формат unsigned int8
binblockBytes = typecast(SENT_TO_WAVEFORM_GENERATOR, 'uint8');

% Конкатенация заголовка и тела, и запись данных на инструмент
fwrite(WG_obj, [header binblockBytes], 'uint8');

% Команда инструменту ожидать выполнения предыдущей команды до конца перед
% продолжением
fprintf(WG_obj, '*WAI');   

% Обновляем окно загрузки
waitbar(.8,h,mes);

% Сообщаем, что в канал 1 нужно записать массив с нашим именем name
command = ['SOURce1:FUNCtion:ARBitrary ' name];
% Выполнить команду
fprintf(WG_obj,command); 

% set current arb waveform to defined arb testrise
command = ['MMEM:STOR:DATA1 "INT:\' name '.arb"'];
% Выполнить команду
fprintf(WG_obj,command);

% Обновить окно загрузки
waitbar(.9,h,mes);

% Установка частоты дискретизации
command = ['SOURCE1:FUNCtion:ARB:SRATe ' num2str(sRate)];
% Выполнить команду
fprintf(WG_obj,command);

% Включить нашу функцию
fprintf(WG_obj,'SOURce1:FUNCtion ARB'); 

% Установка амплитуды
command = ['SOURCE1:VOLT ' num2str(amp)];
% Выполнить команду
fprintf(WG_obj,command);

% Установка смещения 
fprintf(WG_obj,'SOURCE1:VOLT:OFFSET 0');

% Включить выход 1 (если выход включен над ним загорается лампочка)
fprintf(WG_obj,'OUTPUT1 ON');

% Сообщить, что загрузка завершена
fprintf('SENT_TO_WG waveform downloaded to channel 1\n\n');

% Заполняем окно загрузки, удаляем его
waitbar(1,h,mes);
delete(h);

% Проверка наличия ошибок
fprintf(WG_obj, 'SYST:ERR?');
errorstr = fscanf (WG_obj);

% Вывод ошибок
if strncmp (errorstr, '+0,"No error"',13)
   errorcheck = 'Arbitrary waveform generated without any error\n';
   fprintf (errorcheck)
else
   errorcheck = ['Error reported: ', errorstr];
   fprintf (errorcheck)
end

% Закрыть соединение с инструментом
fclose(WG_obj);

%% CXG N5166B Vector Generator USB visa
% Этот блок игнорируется если соединение происходит через LAN см. блок "CXG N5166B Vector Generator LAN"

% Идентификатор (4 аргумент) берется из Keysight Connection Expert
cxg = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0957::0x1F01::MY59100546::0::INSTR', 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(cxg)
    cxg = visa('AGILENT', 'USB0::0x0957::0x1F01::MY59100546::0::INSTR');
else
    fclose(cxg);
    cxg = cxg(1);
end

device_buffer = 10000000*8;
set(cxg,'OutputBufferSize',(device_buffer+125));

% Открыть соединение с инструментом
fopen(cxg);

%% CXG N5166B Vector Generator LAN
% Этот блок игнорируется если соединение происходит через USB см. блок "CXG N5166B Vector Generator USB"

% Чтобы посмотреть ip адрес нажмите кнопку Utility -> I/O config -> LAN setup
cxg = instrfind('Type', 'tcpip', 'RemoteHost', '192.168.0.82', 'RemotePort', 5025, 'Tag', '');

% Create the tcpip object if it does not exist
% otherwise use the object that was found.
if isempty(cxg)
    cxg = tcpip('192.168.0.82', 5025);
else
    fclose(cxg);
    cxg = cxg(1);
end

device_buffer = 10000000*8;
set(cxg,'OutputBufferSize',(device_buffer+125));

% Открыть соединение с инструментом
fopen(cxg);

%% Отправка данных на генератор CXG N5166B
% этот блок общий как для LAN так и для USB и запускается после соединения с инструментом

% Сбросить настройки, очистить регистры статуса и хранилище ошибок
fprintf(cxg, '*RST;*CLS');

% Установить имя нашего массива
ArbFileName = 'Pilot + OFDM';

% I и Q составляющие генерируются в первом блоке "Формирование проверочного сигнала"
wave = [real(ref2_time);imag(ref2_time)]; % get the real and imaginary parts
wave = wave(:)';    % transpose and interleave the waveform

maxval = max(abs([real(ref2_time), imag(ref2_time)]));

tmp = 1; % default normalization factor = 1
% tmp = max(abs([max(wave), min(wave)]));
% % ARB binary range is 2's Compliment -32768 to + 32767
% % So scale the waveform to +/- 32767 not 32768
modval = 2^16;
scale = 2^15-1;
scale = scale/tmp;
wave = round(wave * scale);

wave = wave*0.11;
%  Get it from double to unsigned int and let the driver take care of Big
%  Endian to Little Endian for you  Look at ESG in Workspace.  It is
%  property of the VISA driver (at least Agilent's
%  if your waveform is skrewy, suspect the NI driver of not changeing
%  BIG ENDIAN to LITTLE ENDIAN.  The PC is BIG ENDIAN.  ESG is LITTLE
wave = uint16(mod(modval + wave, modval));

% Выключить RF выход перед записью
fprintf(cxg, ':SOURce:RADio:ARB:STATE OFF');

% Запись данных в генератор
binblockwrite(cxg,wave,'uint16',[':MEMory:DATa:UNProtected "WFM1:' ArbFileName '", ']);
fprintf(cxg,'\n');

% Ожидание завершения предыдущей команды до конца
fprintf(cxg, '*WAI');

playcommand = [':SOURce:RAD:ARB:WAV "ARBI:' ArbFileName '"'];
fprintf(cxg, playcommand);

% Устрановка центральной частоты
fcent = 500e6; % Эта переменная загрузится в блоке для EXA n9010b
               % как центральная частота
fprintf(cxg, ['FREQ ', num2str(fcent)]);

% Установка амплитуды
fprintf(cxg, 'POWER -40');

% Установка частоты дискретизации
fsamp = 20e6;
fprintf(cxg,['RADio:ARB:SCLock:RATE ', num2str(fsamp)]);

% Включение RF output
fprintf(cxg, 'OUTPut ON');

% Включение волны ARB
fprintf(cxg, 'RADio:ARB ON');

% Запрос ошибок 
errors = query(cxg, 'SYST:ERR?');
fprintf(['Error respose: ', errors]);

% Вывести имя запущенного файла в консоль
arbname = query(cxg, 'RAD:ARB:WAV?');
fprintf(['Current ARB file: ', arbname]);

% Закрыть соединение с инструментом
fclose(cxg);

%% Осциллограф DSOX1102G USB visa (LAN соединение отсутствует)
% Идентификатор (4 аргумент) берется из Keysight Connection Expert
OSCI_Obj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x2A8D::0x1797::CN58056332::0::INSTR', 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(OSCI_Obj)
    OSCI_Obj = visa('Agilent', 'USB0::0x2A8D::0x1797::CN58056332::0::INSTR');
else 
    fclose(OSCI_Obj);
    OSCI_Obj = OSCI_Obj(1);
end

% Установка размера буфера
OSCI_Obj.InputBufferSize = 1000000;
% Установка времени ожидания
OSCI_Obj.Timeout = 10;
% Установка порядка следования байт
OSCI_Obj.ByteOrder = 'littleEndian';
% Open the connection
fopen(OSCI_Obj);
% Instrument control and data retreival

% Reset the instrument and autoscale and stop
% fprintf(OSCI_Obj,'*RST; :AUTOSCALE'); 
fprintf(OSCI_Obj,':STOP');
% Specify data from Channel 1
fprintf(OSCI_Obj,':WAVEFORM:SOURCE CHAN1'); 
% Set timebase to main
fprintf(OSCI_Obj,':TIMEBASE:MODE MAIN');
% Set up acquisition type and count. 
fprintf(OSCI_Obj,':ACQUIRE:TYPE NORMAL');
fprintf(OSCI_Obj,':ACQUIRE:COUNT 1');
% Specify 5000 points at a time by :WAV:DATA?
fprintf(OSCI_Obj,':WAV:POINTS:MODE RAW');
fprintf(OSCI_Obj,':WAV:POINTS 50000');
% Now tell the instrument to digitize channel1
fprintf(OSCI_Obj,':DIGITIZE CHAN1');
% Wait till complete
operationComplete = str2double(query(OSCI_Obj,'*OPC?'));
while ~operationComplete
    operationComplete = str2double(query(OSCI_Obj,'*OPC?'));
end
% Get the data back as a WORD (i.e., INT16), other options are ASCII and BYTE
fprintf(OSCI_Obj,':WAVEFORM:FORMAT WORD');

% Set the byte order on the instrument as well
fprintf(OSCI_Obj,':WAVEFORM:BYTEORDER LSBFirst');

% Get the preamble block
preambleBlock = query(OSCI_Obj,':WAVEFORM:PREAMBLE?');
% The preamble block contains all of the current WAVEFORM settings.  
% It is returned in the form <preamble_block><NL> where <preamble_block> is:
%    FORMAT        : int16 - 0 = BYTE, 1 = WORD, 2 = ASCII.
%    TYPE          : int16 - 0 = NORMAL, 1 = PEAK DETECT, 2 = AVERAGE
%    POINTS        : int32 - number of data points transferred.
%    COUNT         : int32 - 1 and is always 1.
%    XINCREMENT    : float64 - time difference between data points.
%    XORIGIN       : float64 - always the first data point in memory.
%    XREFERENCE    : int32 - specifies the data point associated with
%                            x-origin.
%    YINCREMENT    : float32 - voltage diff between data points.
%    YORIGIN       : float32 - value is the voltage at center screen.
%    YREFERENCE    : int32 - specifies the data point where y-origin
%                            occurs.

% Now send commmand to read data
fprintf(OSCI_Obj,':WAV:DATA?');

% read back the BINBLOCK with the data in specified format and store it in
% the waveform structure. FREAD removes the extra terminator in the buffer
waveform.RawData = binblockread(OSCI_Obj,'uint16'); fread(OSCI_Obj,1);

% Read back the error queue on the instrument
instrumentError = query(OSCI_Obj,':SYSTEM:ERR?');

while ~isequal(instrumentError,['+0,"No error"' char(10)])
    disp(['Instrument Error: ' instrumentError]);
    instrumentError = query(OSCI_Obj,':SYSTEM:ERR?');
end

% Массив с полученными данными
RECIEVED_FROM_OSCI = waveform.RawData;

% Закрыть соединение с инструментом
fclose(OSCI_Obj);

%% Анализатор сигналов EXA N9010B USB visa
% Этот блок игнорируется если соединение происходит через LAN см. блок "EXA N9010B LAN"

exa = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x2A8D::0x1B0B::MY60240336::0::INSTR', 'Tag', '');

% Create the VISA object if it does not exist
% otherwise use the object that was found.
if isempty(exa)
    exa = visa('AGILENT','USB0::0x2A8D::0x1B0B::MY60240336::0::INSTR');
else
    fclose(exa);
    exa = exa(1);
end

exa.OutputBufferSize = 1e7;
exa.InputBufferSize = 1e7;
exa.timeout = 10;

fopen(exa);

%% Анализатор сигналов EXA N9010B LAN
% Этот блок игнорируется если соединение происходит через USB см. блок "EXA N9010B USB visa"

% Чтобы посмотреть ip используйте экранную клавиатуру. Win+R -> cmd ->
% ipconfig/all
exa = instrfind('Type', 'tcpip', 'RemoteHost', '192.168.073', 'RemotePort', 5025, 'Tag', '');

% Create the tcpip object if it does not exist
% otherwise use the object that was found.
if isempty(exa)
    exa = tcpip('192.168.073', 5025);
else
    fclose(exa);
    exa = exa(1);
end

exa.OutputBufferSize = 1e7;
exa.InputBufferSize = 1e7;
exa.timeout = 10;

fopen(exa);

%% Получение данных от анализатора сигналов EXA N9010B
% этот блок общий как для LAN так и для USB и запускается после соединения с инструментом

acq_time = 2000e-6;
samp_rate = fsamp;
cent_freq = fcent;

fprintf(exa, '*RST;*CLS');

% Настройка режима и конфигурации
fprintf(exa, 'INST:SEL BASIC');
fprintf(exa, 'CONFigure:WAVeform');

fprintf(exa, ['FREQ:CENT ', num2str(cent_freq)]);
% set(exa, 'SATrigger', 'RFBurst');

fprintf(exa, ':INIT:CONT OFF');
fprintf(exa, [':WAV:SWE:TIME ', num2str(acq_time)]);

fprintf(exa,':INIT:IMM');


%Get IQ data
fprintf(exa, [':WAV:SRAT ', num2str(samp_rate)]);

% Get the interface object
% Tell it the precision
fprintf(exa,':FORM:DATA ASCii');

% fprintf(interface,':FORM:DATA MATLAB');

fprintf(exa,':READ:WAV0?');

fprintf(exa,'*WAI');

% exadata содержит сырые данные с анализатора типа <char>
% '2.306786738E-02,1.153779309E-02,1.795095950E-02,...'
exadata = fscanf(exa);
% data массив чисел <double>
data = str2num(exadata);
% нечетные в inphase - 1, 3, 5, ...
% четные в quad - 2, 4, 6, ...
inphase = data(1:2:end);
quad = data(2:2:end);
% создаём комплексный массив
compl = complex(inphase, quad);
% спектр комплексного массива
fft_com = fft(compl);

formatSpec = 'Спектр полученного комплесного массива compl. Его размер = %d';
len = length(fft_com);
str_1 = sprintf(formatSpec, len);
figure;
plot(abs(fft_com));
title(str_1);

scatterplot(fft_com);
title('созвездие спектра (fft com)');grid on;
% Корреляция с сдвинутым спектром с нулями
[corrr2, lags2] = xcorr(ref2_time, compl);
[cor2, pos2] = max(corrr2);
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
    newsum = compl(abs(tlag):abs(tlag) + length(ref2_time));
catch me
    disp(me.message);
    newsum = compl(abs(tlag) - length(ref2_time):abs(tlag));
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
fclose(exa);
%% Демодуляция

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

%% R&S (В разработке)
close all;

% Кнопка Setup -> General Setup -> Network address -> IP address
% Собственный ip адресс инструмента 169.254.21.200
% Find a tcpip object.
RS = instrfind('Type', 'tcpip', 'RemoteHost', '192.168.0.78', 'RemotePort', 5025, 'Tag', '');

% Create the tcpip object if it does not exist
% otherwise use the object that was found.
if isempty(RS)
    RS = tcpip('192.168.0.78', 5025);
else
    fclose(RS);
    RS = RS(1);
end

% Установка буфера и времени ожидания
RS.OutputBufferSize = 1e7;
RS.InputBufferSize = 1e7;
RS.timeout = 8;

% Параметры измерения
% Частота дискретизации должна быть ровно в 2 раза больше полосы
% измеряемого сигнала
fsampling = 40e6; % Полоса (BWIDth) устанавливается инструментом автоматически в зависимости от fsampling
fcentral = 500e6;
NumOfPoints = 50e3;

% Открыть соединение с инструментом
fopen(RS);

% Сброс и очистка регистра статуса
fprintf(RS, '*RST;*CLS');

% Запрос имени инструмента
data1 = query(RS, '*IDN?');
disp(['Инструмент: ', data1]);

% Установка нужного режима
fprintf(RS, 'INSTrument IQ');
% IQ, SANalyzer

% Получение информации о режиме работы 
mode = query(RS, 'INSTrument?');
disp(['Режим: ', mode]);

% fprintf(RS, 'INPut:DIQ:SRATe 20e6');
insrate = query(RS, 'INPut:DIQ:SRATe?');
disp(['Входная частота = ', insrate]);

% Установка центральной частоты
fprintf(RS, ['FREQ:CENT ', num2str(fcentral)]);

% Одиночное измерение
fprintf(RS, 'INITiate:CONTinuous OFF');

% Установка частоты дискретизации
fprintf(RS, ['TRACe:IQ:SRATe ', num2str(fsampling)]);
sam = query(RS, 'TRACe:IQ:SRATe?');
disp(['Частота дискретизации = ', sam]);

% Установка количества точек измерения (Record Length)
% В приложении IQWizard это поле "Count"
% Количество снимаемых точек зависит от времени измерения, устанавливать можно только что-то одно
% Если нужно установить время: fprintf(RS, 'SENS:SWE:TIME 1ms');
% fprintf(RS, 'SENS:SWE:TIME 1ms');
fprintf(RS, ['TRACe:IQ:RLENgth ' , num2str(NumOfPoints)]);
rlen = query(RS, 'TRACe:IQ:RLENgth?');
disp(['Количество точек = ', rlen]);

% Количество свипов
fprintf(RS, 'SWE:COUN 1');
% fprintf(RS, 'INIT;*WAI');

% Запрос ширины полосы измерения
% Ширина полосы зависит от частоты дискретизации
BandWidth = query(RS, 'TRACe:IQ:BWIDth?');
disp(['Ширина полосы = ', BandWidth]);

% Позволить изменениям отображаться на экране
% в противном случае экран потемнеет и выведется надпись "REMOTE MODE"
fprintf(RS, 'SYST:DISP:UPD ON');
fprintf(RS, 'INIT; *WAI');

try
    data4 = query(RS, 'TRACe:IQ:DATA?'); 

    numdata4 = str2num(data4);

    Inum = numdata4(1:2:end);
    Qnum = numdata4(2:2:end);

    compl = complex(Inum, Qnum);

    spec = fft(compl);

    figure;
    plot(abs(fftshift(spec)));
    title(['Количество комплексных векторов = ', num2str(length(compl))]);
    figure;
    plot(abs(compl));
    title('compl');

    scatterplot(spec);title('spec');
    scatterplot(compl);title('compl');
catch me
    disp(['Catched message: ', me.message]);
end

err = query(RS, ':SYST:ERR?');
disp(['Ошибка: ',err]);
% meme = fscanf(RS);
% return
fprintf(RS, 'INITiate:CONTinuous ON');
% fclose(RS);

%% Корреляция
close all;

% sig_time = ifft(spec_zeros);          -|_ 000000000 _|-|  10240
% pil_time = ifft(pilot_zeros);         -|_ 000000000 _|-|  10240
% ref2_time = [pil_time, sig_time];

corrr3 = xcorr(pil_time, compl);
figure;
plot(abs(corrr3));title('pil time');

corrr4 = xcorr(sig_time, compl);
figure;
plot(abs(corrr4));title('sig time');

corrr2 = xcorr(ref2_time, compl);
figure;
plot(abs(corrr2));title('ref2 time');

% spec_time = ifft(spectrum_shifted);       -|_ _|-|    1024
% spec_time_pilot = ifft(pilot_shifted);    -|_ _|-|    1024
% ref1_time = [spec_time_pilot, spec_time];

corrr6 = xcorr(spec_time_pilot, compl);
figure;
plot(abs(corrr6));title('spec time pilot');

corrr5 = xcorr(spec_time, compl);
figure;
plot(abs(corrr5));title('spec time');

[corrr7, lag7] = xcorr(ref1_time, compl);
figure;
plot(abs(corrr7));title('ref1 time');

[~, pos4] = max(abs(corrr7));
t = lag7(pos4);

cut = compl(abs(t):abs(t) + length(ref1_time));
cut_spec = fft(cut);
scatterplot(cut_spec);title('cut spec');
figure;
plot(abs(fftshift(cut_spec)));title('cut spec shifted');

fclose(RS);
