clearvars;
close all;

% длина символа
Fourier_length = 1024;
% защитный интервал
Protection_Interval = 100; 
% длина
N = 1648;               
bits = randi([0, 1], 1, N);

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

% вырезаем данные длиной 824 из произвольного массива данных
mod_data_send = mod_data(1:Fourier_length - 2*Protection_Interval); 
% добавляем слева и справа защитные интервалы и 0 для несущей
spectrum = [zeros(1, Protection_Interval - 1), mod_data_send(1:length(mod_data_send)/2), 0, mod_data_send(length(mod_data_send)/2+1:end), zeros(1, Protection_Interval)];

%---------- эта часть относится к предыскажениям
% for i = 1:length(spectrum)
%     spectrum_distorted(i) = spectrum(i)*1; % coeffs_inv(i)
% end

% for i = 1:length(spectrum)
%     spectrum_distorted(i) = spectrum(i)*coeffs_inv(i);
% end
% spectrum(1024) = 2;
%---------------------------------------------

% мдвиг спектра делит спектр попалам и помещает правую часть
% влево, а левую вправо
spectrum_shifted = fftshift(spectrum);
% Тест. ОБПФ
spec_time = ifft(spectrum_shifted);

% figure;
% plot(abs(spectrum_shifted));
% title('abs(spectrum shifted)');
% xlabel('Freq');
% ylabel('Amplitude');
% grid on;

% между сдвинутыми половинами спектра вставляем нули
% L определяет длину получившегося массива
spec_zeros = ([spectrum_shifted(1:Fourier_length/2), zeros(1, (L -1024)), spectrum_shifted(Fourier_length/2 + 1:end)]);

% переводим полученный спектр во временную область
sig_time = ifft(spec_zeros);
% выделяем
I = real(sig_time);
Q = imag(sig_time);

t_sig = [0:length(I) - 1]/fs;
% t_sig = (0:1:L-1)/fs;

sig_carrI = cos(2*pi*fc*t_sig);
for i = 1:length(I)
    I_mod(i) = I(i)*sig_carrI(i);
end

sig_carrQ = -sin(2*pi*fc*t_sig);
for i = 1:length(Q)
    Q_mod(i) = Q(i)*sig_carrQ(i);
end

for i = 1:length(I)
    SENT_TO_WAVEFORM_GENERATOR(i) = I_mod(i) + Q_mod(i);
end

% как выглядит SENT_TO_WAVEFORM_GENERATOR

sent_fft = fft(SENT_TO_WAVEFORM_GENERATOR);

% aboba = sig_time';
% csvwrite('CSVfile2.csv', aboba);
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
t_L = (L/fs)*1e6; % микросекунды
t_F = (Fourier_length/fs)*1e6;

figure;
subplot(2,2,1);
plot( abs(spectrum));
title('Original OFDM symbol');xlabel('n');ylabel('Amplitude');grid on;
subplot(2,2,2);
plot(abs(spec_zeros));
title('Shift + zeros interp');xlabel('n');ylabel('Amplitude');grid on;
subplot(2,2,3);
plot(f, abs(sent_fft));
title('Bandpass spectrum');xlabel('freq');ylabel('Amplitude');grid on;

%% Send to WG

% Подключение к генератору и отправка сигнала на него

% Find a VISA-USB object.
% Защита от создания копий одного и того же объекта соединения
% Если объект уже существует он не записан в переменную obj1, то записываем
% его туда (04.10.2021, 1:42)
WG_obj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0957::0x2807::MY57401328::0::INSTR', 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(WG_obj) % В аргументах visa может применяться новое название 'KEYSIGHT', 
    % а может и старое 'AGILENT'. Нужно смотреть через tmtool как для
    % генератора так и для осциллографа
    WG_obj = visa('Agilent', 'USB0::0x0957::0x2807::MY57401328::0::INSTR');
else
    fclose(WG_obj);
    WG_obj = WG_obj(1);
end

name = 'my_waveforms';
sRate = fs;
amp = 0.1;

% Connect to instrument object, obj1.
% fopen(obj1);

% vAddress = ['USB0::0x0957::0x2807::MY57401329::0::INSTR']; %build visa address string to connect
% fgen = visa('AGILENT',vAddress); %build IO object
% obj1.Timeout = 15; %set IO time out
%calculate output buffer size
obj1_buffer = length(SENT_TO_WAVEFORM_GENERATOR)*8;
set (WG_obj,'OutputBufferSize',(obj1_buffer+125));

WG_obj.Timeout = 10;

%open connection to 33500A/B waveform generator
try
   fopen(WG_obj);
catch exception %problem occurred throw error message
    uiwait(msgbox('Error occurred trying to connect to the 33522, verify correct IP address','Error Message','error'));
    rethrow(exception);
end

%Query Idendity string and report
fprintf (WG_obj, '*IDN?');
idn = fscanf (WG_obj);
fprintf (idn)
fprintf ('\n\n')

%create waitbar for sending waveform to 33500
mes = ['Connected to ' idn ' sending waveforms.....'];
h = waitbar(0,mes);

%Reset instrument
fprintf (WG_obj, '*RST');

%make sure waveform data is in column vector
if isrow(SENT_TO_WAVEFORM_GENERATOR) == 0
    SENT_TO_WAVEFORM_GENERATOR = SENT_TO_WAVEFORM_GENERATOR';
end

%set the waveform data to single precision
SENT_TO_WAVEFORM_GENERATOR = single(SENT_TO_WAVEFORM_GENERATOR);

ON_OFF_FILTER_CH1 = ['SOURce1:FUNCtion:ARBitrary:FILTer ', 'OFF'];
fprintf(WG_obj, ON_OFF_FILTER_CH1); % ON OFF filter

%scale data between 1 and -1
mx = max(abs(SENT_TO_WAVEFORM_GENERATOR));
SENT_TO_WAVEFORM_GENERATOR = (1*SENT_TO_WAVEFORM_GENERATOR)/mx;

%update waitbar
waitbar(.1,h,mes);

%send waveform to 33500
fprintf(WG_obj, 'SOURce1:DATA:VOLatile:CLEar'); %Clear volatile memory
%configure the box to correctly accept the binary arb points
fprintf(WG_obj, 'FORM:BORD SWAP');  
%# of bytes
SENT_TO_WG_Bytes=num2str(length(SENT_TO_WAVEFORM_GENERATOR) * 4); 
%create header
header= ['SOURce1:DATA:ARBitrary ', name, ', #', num2str(length(SENT_TO_WG_Bytes)), SENT_TO_WG_Bytes]; 
%convert datapoints to binary before sending
binblockBytes = typecast(SENT_TO_WAVEFORM_GENERATOR, 'uint8');
%combine header and datapoints then send to instrument
fwrite(WG_obj, [header binblockBytes], 'uint8');
%Make sure no other commands are exectued until arb is done downloadin
fprintf(WG_obj, '*WAI');   
%update waitbar
waitbar(.8,h,mes);
%Set desired configuration for channel 1
command = ['SOURce1:FUNCtion:ARBitrary ' name];
%fprintf(fgen,'SOURce1:FUNCtion:ARBitrary GPETE'); % set current arb waveform to defined arb testrise
fprintf(WG_obj,command); 
% set current arb waveform to defined arb testrise
command = ['MMEM:STOR:DATA1 "INT:\' name '.arb"'];
%fprintf(fgen,'MMEM:STOR:DATA1 "INT:\GPETE.arb"');%store arb in intermal NV memory
fprintf(WG_obj,command);
%update waitbar
waitbar(.9,h,mes);
command = ['SOURCE1:FUNCtion:ARB:SRATe ' num2str(sRate)]; %create sample rate command
fprintf(WG_obj,command);%set sample rate
fprintf(WG_obj,'SOURce1:FUNCtion ARB'); % turn on arb function
command = ['SOURCE1:VOLT ' num2str(amp)]; %create amplitude command
fprintf(WG_obj,command); %send amplitude command
fprintf(WG_obj,'SOURCE1:VOLT:OFFSET 0'); % set offset to 0 V
fprintf(WG_obj,'OUTPUT1 ON'); %Enable Output for channel 1
fprintf('SENT_TO_WG waveform downloaded to channel 1\n\n') %print waveform has been downloaded

%get rid of message box
waitbar(1,h,mes);
delete(h);

%Read Error
fprintf(WG_obj, 'SYST:ERR?');
errorstr = fscanf (WG_obj);

% error checking
if strncmp (errorstr, '+0,"No error"',13)
   errorcheck = 'Arbitrary waveform generated without any error\n';
   fprintf (errorcheck)
else
   errorcheck = ['Error reported: ', errorstr];
   fprintf (errorcheck)
end

% fclose(WG_obj);


%% WavReadIQData unpacked



% Connecting to EXA SA
if ~isempty(instrfind)
    fclose(instrfind);
    delete(instrfind);
end

interfaceObj = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x2A8D::0x1B0B::MY60240336::0::INSTR', 'Tag', '');

% Create the VISA object if it does not exist
% otherwise use the object that was found.
if isempty(interfaceObj)
    interfaceObj = visa('AGILENT','USB0::0x2A8D::0x1B0B::MY60240336::0::INSTR');
else
    fclose(interfaceObj);
    interfaceObj = interfaceObj(1);
end

% Creating Icdevice obj, using .mdd, and visa interface obj
exa = icdevice('Agilent_SA_Driver.mdd',interfaceObj);
connect(exa);

invoke(exa, 'WriteSCPI', '*RST;');invoke(exa, 'QuerySCPI', '*OPC?');
invoke(exa, 'WriteSCPI', '*CLS');invoke(exa, 'QuerySCPI', '*OPC?');

acq_time = 1000e-6;
samp_rate = 50.0e6;
cent_freq = 10.0e6;

exa.timeout = 10;
set(exa,'Mode','Basic');
invoke(exa, 'QuerySCPI', '*OPC?');
invoke(exa, 'WriteSCPI', '*RST;:DISP:ENAB ON');
invoke(exa, 'QuerySCPI', '*OPC?');
set(exa,'SAFreqCenter',cent_freq);
invoke(exa, 'QuerySCPI', '*OPC?');
% set(exa, 'SATrigger', 'RFBurst');

set(exa, 'SASweepSingle','On');
invoke(exa, 'QuerySCPI', '*OPC?');
set(exa, 'WavAcquisitionTime',acq_time);
invoke(exa, 'QuerySCPI', '*OPC?');
set(exa, 'WavRBW',5e6);
invoke(exa, 'QuerySCPI', '*OPC?');
invoke(exa,'SAInitiate');
invoke(exa, 'QuerySCPI','*OPC?');

%Get IQ data
set(exa,'WavSampleRate',samp_rate);
invoke(exa, 'QuerySCPI', '*OPC?');
% ----------------------- unpacked -----------------------#
% Get the interface object
interface=get(exa,'interface');

% Tell it the precision
fprintf(interface,':FORM:DATA ASCii');
fprintf(interface,'*OPC?');
% fprintf(interface,':FORM:DATA MATLAB');

fprintf(interface,':READ:WAV0?');

% l содержит сырые данные с анализатора типа <char>
% '2.306786738E-02,1.153779309E-02,1.795095950E-02,...'
l = fscanf(interface);
% data массив чисел <double>
data = str2num(l);
% нечетные в inphase - 1, 3, 5, ...
% четные в quad - 2, 4, 6, ...
inphase = data(1:2:end);
quad = data(2:2:end);
% создаём комплексный массив
compl = complex(inphase, quad);
% спектр комплексного массива
fft_com = fft(compl);

% созвездие спектра
% scatterplot(fft_com);
% title('созвездие спектра (fft com)');grid on;
% Корреляция и максимум корреляции
[corrr2, lags2] = xcorr(sig_time, compl);
[cor2, pos2] = max(corrr2);

newsig = compl(abs(pos2):abs(pos2) + length(sig_time));
newspec = fft(newsig);
% figure;
% plot(abs(newspec));
% title('newspec');
newcut = [newspec(1:512), newspec(end - 511:end)];
% cutshift имеет вид похожий на spectrum
cutshift = fftshift(newcut);
scatterplot(newcut);
title('Созвездие вырезанного спектра');

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
plot(abs(newcut));title('Вырезанный символ');
subplot(2,2,4);
plot(abs(cutshift));title('Принятый OFDM символ');
return
%% Эквалайзирование
ref = mod_data_send;
figure;
plot(ref);
scatterplot(ref);

newdata = [newcut(1024 - 412:1023), newcut(1:412)];
figure;
plot(abs(newdata));
scatterplot(newdata);
title('newdata');grid on;

% load('matlab.mat')
TF_est = newdata./ref;
figure;plot(TF_est);
title('TF est');grid on;
restored = newdata./TF_est;

scatterplot(restored);
title('restored');grid on;


% disp(['type of data is: ', class(data)]);

%% Демодуляция

mod_data_r = [spectrum_r_shifted(Protection_Interval:Protection_Interval + length(mod_data_send)/2- 1), spectrum_r_shifted(Protection_Interval + length(mod_data_send)/2 + 1:Fourier_length - Protection_Interval)];

figure;
plot(abs(mod_data_r));
title('mod data r');
grid on;

scatterplot(mod_data_r,1,0,'r*');

% Демодуляция mod_data_r
k=1;
for i = 1:length(mod_data_r)
    if real(mod_data_r(i)) >0 && imag(mod_data_r (i)) >0
        bits_demod_r (k) = 1; bits_demod_r (k+1) = 1;
    end
    if real(mod_data_r (i)) <0 && imag(mod_data_r(i)) >0
        bits_demod_r (k) = 0; bits_demod_r (k+1) = 1;
    end
	if real(mod_data_r (i)) >0 && imag(mod_data_r (i)) <0
        bits_demod_r (k) = 1; bits_demod_r (k+1) = 0;
    end
    if real(mod_data_r (i)) <0 && imag(mod_data_r (i)) <0
        bits_demod_r (k) = 0; bits_demod_r (k+1) = 0;
    end
    k=k+2;
end

% График демодулированного принятого сигнала, т.е. биты информации, которые
% нам и нужны
figure;
plot(bits_demod_r);
title('bits demod r');
xlim([1 100]);
grid on;

% for i = 1:length(bits_demod_r)
%     if bits_demod_r(i) == 0
%         bits_demod_r_fliped(i) = 1;
%     if bits_demod_r(i) == 1
%         bits_demod_r_fliped(i) = 0;
%     end
% end


% Проверка на ошибки, сравнение принятого bits_demod и отправленного
% сообщения bits
err2 = biterr(bits_demod_r ,bits);

%% Предысккажение 

% Sectrum это спектр составленный из зашитн интервала нулей + данные + нули
% второг защитного интервала
for i = 1:length(cutshift) - 1  % 
    coeffs(i) = cutshift(i)/spectrum(i);
end

for i = 1:length(coeffs)
    coeffs_inv(i) = 1/coeffs(i);
end

%% Другие моды EXA
% Управление без драйвера


%% RHODE

obj2 = tcpip('168.254.21.201');
fopen(obj2);
fprintf(obj2, '*IDN?');
