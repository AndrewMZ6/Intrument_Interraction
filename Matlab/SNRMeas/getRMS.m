function RMS = getRMS(connectionID)

% Функция отвечающая за снятие значения RMS с осциллографа
% 
% RMS = getRMS(connectionID)
% 
% connectionID - идентификатор инструмента  
% RMS - rootMeanSquare, среднеквадратичное напряжение измеренное на 
% осциллогафе, в Вольтах

if nargin < 1
    connectionID = 'USB0::0x0957::0x179B::MY52447296::0::INSTR';
end

OSCI_Obj = instrfind('Type', 'visa-usb', 'RsrcName', connectionID, 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(OSCI_Obj)
    OSCI_Obj = visa('Agilent', connectionID);
else 
    fclose(OSCI_Obj);
    OSCI_Obj = OSCI_Obj(1);
end

fopen(OSCI_Obj);

RMS = query(OSCI_Obj, 'MEASure:VRMS?');

fclose(OSCI_Obj);

return;
