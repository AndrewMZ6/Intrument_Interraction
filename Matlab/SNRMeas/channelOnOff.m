function channelOnOff(connectionID, chNum, state)

% Функция отвечающая за включение / выключение каналов 1 и 2 на генераторе
% WaveformGenerator 33500B
%
% channelOnOff(connectionID, chNum, state)
% 
% chNum - номер канала, 1 или 2
% state - состояние: 'ON' или 'OFF' (строка)
% connectionID - идентификатор соединения с инструментом
%
% Пример:
% channelOnOff('USB0::0x0957::0x4B07::MY53401534::0::INSTR', 2, 'OFF');
% channelOnOff('USB0::0x0957::0x4B07::MY53401534::0::INSTR', 1, 'ON');

WG_Obj = instrfind('Type', 'visa-usb', 'RsrcName', connectionID, 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(WG_Obj)
    WG_Obj = visa('Agilent', connectionID);
else 
    fclose(WG_Obj);
    WG_Obj = WG_Obj(1);
end

fopen(WG_Obj);

fprintf(WG_Obj, ['OUTPUT', num2str(chNum), ' ', state]);

fclose(WG_Obj);

return;
