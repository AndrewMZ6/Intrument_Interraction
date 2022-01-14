function [RECIEVED_FROM_OSCI] = getFromOsci(connectionID)

% Осциллограф DSOX1102G USB visa (LAN соединение отсутствует)
% Идентификатор (4 аргумент) берется из Keysight Connection Expert
OSCI_Obj = instrfind('Type', 'visa-usb', 'RsrcName', connectionID, 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(OSCI_Obj)
    OSCI_Obj = visa('Agilent', connectionID);
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
% Открыть соединение с инструментом
fopen(OSCI_Obj);

% Сбросить настройки, включить авто-скалирование и остановить прибор
% fprintf(OSCI_Obj,'*RST; :AUTOSCALE'); 
fprintf(OSCI_Obj,':STOP');
% Источник данных - канал 1
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

return;