function [exadata] = getFromExa(connectionID, samp_rate, acq_time, cent_freq)

% function [exadata] = getFromExa(connectionID, samp_rate, acq_time, cent_freq)
%
% Обязательные параметры:
% connectionID - идентификатор соединения с инстументом
% 
% Опциональные параметры:
% samp_rate - частота дискретизации. По умолчанию 20 MHz
% acq_time - время измерения. По умолчанию 2000 мкс = 2 мс
% cent_freq - центральная частота (частота несущей). По умолчанию 500 MHz
% exadata - полученные от анализатора данные типа 'double'

if (nargin < 4) cent_freq = 500e6; end
if (nargin < 3) acq_time = 2000e-6; end
if (nargin < 2) samp_rate = 20e6; end
if (nargin < 1)
    error('Необходимо указать connectionID инструмента. Используйте функцию getIntsrID')
end

switch (contains(connectionID, '::'))
    case 1
        % Анализатор сигналов EXA N9010B USB visa
        % Этот блок игнорируется если соединение происходит через LAN см. блок "EXA N9010B LAN"
        
        exa = instrfind('Type', 'visa-usb', 'RsrcName', connectionID, 'Tag', '');
        
        % Create the VISA object if it does not exist
        % otherwise use the object that was found.
        if isempty(exa)
            exa = visa('AGILENT',connectionID);
        else
            fclose(exa);
            exa = exa(1);
        end
        
        exa.OutputBufferSize = 1e7;
        exa.InputBufferSize = 1e7;
        exa.timeout = 10;
        
        fopen(exa);
    case 0
        % Анализатор сигналов EXA N9010B LAN
        % Этот блок игнорируется если соединение происходит через USB см. блок "EXA N9010B USB visa"
        
        % Чтобы посмотреть ip используйте экранную клавиатуру. Win+R -> cmd ->
        % ipconfig/all
        exa = instrfind('Type', 'tcpip', 'RemoteHost', connectionID, 'RemotePort', 5025, 'Tag', '');
        
        % Create the tcpip object if it does not exist
        % otherwise use the object that was found.
        if isempty(exa)
            exa = tcpip(connectionID, 5025);
        else
            fclose(exa);
            exa = exa(1);
        end
        
        exa.OutputBufferSize = 1e7;
        exa.InputBufferSize = 1e7;
        exa.timeout = 10;
        
        fopen(exa);
end

% Получение данных от анализатора сигналов EXA N9010B
% этот блок общий как для LAN так и для USB и запускается после соединения с инструментом

% acq_time = 2000e-6;
% samp_rate = fsamp;
% cent_freq = fcent;

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

% fprintf(exa,'*WAI');

% exadata содержит сырые данные с анализатора типа <char>
% '2.306786738E-02,1.153779309E-02,1.795095950E-02,...'
data = fscanf(exa);
% data массив чисел <double>
exadata = str2num(data);

fclose(exa);
