clear all;
close all;

% symbol length
Fourier_length = 1024;
% guard interval
Protection_Interval = 100; 
% info length
N = 1648;               
bits = randi([0, 1], 1, N);
% carrying frequency
fc = 10e6;
% sampling frequency
fs = 50e6;
% length of interpolated symbol
L = 10*1024;  % 10240
% frequency step
fstep = fs/L ;
% frequency array (used as X axis)
f = 0:fstep:fstep*(L - 1);

% QPSK modulation of bits
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

% mod_data - is complex array made of bit pairs where the first bit in pair
% corresponds to real part whereas the second bit to imaginary. That's why mod_data array is half length of bits array

% cut off 824 information bits from mod_data
mod_data_send = mod_data(1:Fourier_length - 2*Protection_Interval); 
% add guard intervals to the left and to the right side of the 824 information bits 
% adding zero for central carrier frequency
spectrum = [zeros(1, Protection_Interval - 1), mod_data_send(1:length(mod_data_send)/2), 0, mod_data_send(length(mod_data_send)/2+1:end), zeros(1, Protection_Interval)];

%---------- This part is for predistortions ---------
% for i = 1:length(spectrum)
%     spectrum_distorted(i) = spectrum(i)*1; % coeffs_inv(i)
% end

% for i = 1:length(spectrum)
%     spectrum_distorted(i) = spectrum(i)*coeffs_inv(i);
% end
% spectrum(1024) = 2;
%----------------------------------------------------

% frequency shift divides spectrum in half and puts the right part of it to the left
% and the left part to the right
spectrum_shifted = fftshift(spectrum);
% for testing IFFT
spec_time = ifft(spectrum_shifted);

% figure;
% plot(abs(spectrum_shifted));
% title('abs(spectrum shifted)');
% xlabel('Freq');
% ylabel('Amplitude');
% grid on;

% insert zeros between shifted spectrum halfs
% L defines the total spectrum length
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

%% send to CXG
% Find a VISA-USB object.
device = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0957::0x1F01::MY59100546::0::INSTR', 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(device)
    device = visa('AGILENT', 'USB0::0x0957::0x1F01::MY59100546::0::INSTR');
else
    fclose(device);
    device = device(1);
end

device_buffer = 10000000*8;
set(device,'OutputBufferSize',(device_buffer+125));
% Connect to instrument object, obj1.
fopen(device);
fprintf(device, '*RST;*CLS');
ArbFileName = 'LOL';

wave = [I;Q]; % get the real and imaginary parts
wave = wave(:)';    % transpose and interleave the waveform

tmp = 1; % default normalization factor = 1
% 
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

% write the waveform data
binblockwrite(device,wave,'uint16',[':MEMory:DATa:UNProtected "WFM1:' ArbFileName '", ']);
fprintf(device,'\n');

fprintf(device, '*WAI');
% 
playcommand = [':SOURce:RAD:ARB:WAV "ARBI:' ArbFileName '"'];
fprintf(device, playcommand);
% Устрановка центральной частоты
fcent = 500e6; % Эта переменная загрузится в блоке для EXA n9010b
               % как центральная частота
fprintf(device, ['FREQ ', num2str(fcent)]);
% Установка амплитуды
fprintf(device, 'POWER -40');
% Установка частоты дискретизации
fsamp = 20e6;
fprintf(device,['RADio:ARB:SCLock:RATE ', num2str(fsamp)]);
% Включение RF output
fprintf(device, 'OUTPut ON');
% Включение волны ARB
fprintf(device, 'RADio:ARB ON');
% Запрос ошибок и текущего имени ARB волны
errors = query(device, 'SYST:ERR?');
fprintf(['Error respose: ', errors]);
arbname = query(device, 'RAD:ARB:WAV?');
fprintf(['Current ARB file: ', arbname]);

fclose(device);
%% getting results from exa

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

invoke(exa, 'WriteSCPI', '*RST;*CLS')

acq_time = 4000e-6;
samp_rate = fsamp;
cent_freq = fcent;

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

% figure;
% plot(abs(fft_com));

% scatterplot(fft_com);
title('созвездие спектра (fft com)');grid on;
% Корреляция с сдвинутым спектром с нулями
[corrr2, lags2] = xcorr(sig_time, compl);
[cor2, pos2] = max(corrr2);
% Корреляция с сдвинутым спектром без нулей
% [corrr3, lags3] = xcorr(spec_time, compl);


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

