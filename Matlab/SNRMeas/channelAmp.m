function channelAmp(connectionID, chNum, amp)

% Функция отвечающая за установку амплитуды канала 1 и 2 на генераторе
% WaveformGenerator 33500B
%
% channelAmp(connectionID, chNum, amp)
% 
% chNum - номер канала, 1 или 2
% amp - зачение амплитуды в Вольтах/МиллиВольтах
% connectionID - идентификатор соединения с инструментом

WG_Obj = instrfind('Type', 'visa-usb', 'RsrcName', connectionID, 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(WG_Obj)
    WG_Obj = visa('Agilent', connectionID);
else 
    fclose(WG_Obj);
    WG_Obj = WG_Obj(1);
end

% Открыть соединение с инструментом
fopen(WG_Obj);

fprintf(WG_Obj, ['SOURCE', num2str(chNum), ':VOLT ', num2str(amp)]);

fclose(WG_Obj);

return;
