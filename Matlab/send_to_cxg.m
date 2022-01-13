function send_to_cxg(connectionID, data, fcent, fsamp, pLevel, ArbFileName)

% send_to_cxg(connectionID, data, fcent, fsamp, pLevel, ArbFileName)
%
% connectionID - идентификатор USB соединения или IP адрес
% data (ref2_time) - массив(в виде комплексных чисел), который будет записан
% fcent - центральная частота(несущая)
% fsamp - частота дискретизации
% pLevel - power level - мощность в децибелах
% ArbАileName - имя файла в приборе
%
% Значения по умолчанию:
% fcent = 500 MHz
% fsamp = 20 MHz
% pLevel = -40 dB
% Arbfilename = 'Untitled'


% На вход мне нужно подать следующие аргументы:
% id - идентификатор USB соединения (по идее тут надо еще запихнуть
% возможность передать IP, если соединение через LAN)

if nargin < 2
    error('На вход функции необходимо хотя бы два аргумента');
end

if (nargin < 6) ArbFileName = 'Untitled'; end
if (nargin < 5) pLevel = -40; end
if (nargin < 4) fsamp = 20e6; end
if (nargin < 3) fcent = 500e6; end

% return;
% default = {'USB0::0x0957::0x1F01::MY59100546::0::INSTR', 'MyPilot', ref2_time, 500e6, 20e6, -40};

% Те параметры, которые были указаны при вызове функции перезаписывают
% дефолтные
% default(1:nargin) = varargin;

switch (contains(connectionID, '::'))
    case 1
        % CXG N5166B Vector Generator USB visa
        % Этот блок игнорируется если соединение происходит через LAN см. блок "CXG N5166B Vector Generator LAN"
        
        % Идентификатор (4 аргумент) берется из Keysight Connection Expert
        cxg = instrfind('Type', 'visa-usb', 'RsrcName', connectionID, 'Tag', '');
        
        % Create the VISA-USB object if it does not exist
        % otherwise use the object that was found.
        if isempty(cxg)
            cxg = visa('AGILENT', connectionID);
        else
            fclose(cxg);
            cxg = cxg(1);
        end
        
        device_buffer = 10000000*8;
        set(cxg,'OutputBufferSize',(device_buffer+125));
        
        % Открыть соединение с инструментом
        fopen(cxg);

    case 0
        % CXG N5166B Vector Generator LAN
        % Этот блок игнорируется если соединение происходит через USB см. блок "CXG N5166B Vector Generator USB"
        
        % Чтобы посмотреть ip адрес нажмите кнопку Utility -> I/O config -> LAN setup
        cxg = instrfind('Type', 'tcpip', 'RemoteHost', connectionID, 'RemotePort', 5025, 'Tag', '');
        
        % Create the tcpip object if it does not exist
        % otherwise use the object that was found.
        if isempty(cxg)
            cxg = tcpip(connectionID, 5025);
        else
            fclose(cxg);
            cxg = cxg(1);
        end
        
        device_buffer = 10000000*8;
        set(cxg,'OutputBufferSize',(device_buffer+125));
        
        % Открыть соединение с инструментом
        fopen(cxg);
end
%% Отправка данных на генератор CXG N5166B
% этот блок общий как для LAN так и для USB и запускается после соединения с инструментом

% Сбросить настройки, очистить регистры статуса и хранилище ошибок
fprintf(cxg, '*RST;*CLS');

% Установить имя нашего массива
ArbFileName = ArbFileName;

% I и Q составляющие генерируются в первом блоке "Формирование проверочного сигнала"
wave = [real(data);imag(data)]; % get the real and imaginary parts
wave = wave(:)';    % transpose and interleave the waveform

maxval = max(abs([real(data), imag(data)]));

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
fcent = fcent; % Эта переменная загрузится в блоке для EXA n9010b
               % как центральная частота
fprintf(cxg, ['FREQ ', num2str(fcent)]);

% Установка амплитуды
pLevel = pLevel;
fprintf(cxg, ['POWER ', num2str(pLevel)]);

% Установка частоты дискретизации
fsamp = fsamp;
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

return;