function sendToWg(connectionID, data, fs, ArbFileName)
%SENDTOWG отправить данные на генератор Waveform Generator 33500B
%
%   sendToWg() отправляет данные

if (nargin< 4) ArbFileName = 'Untitled'; end
if (nargin< 3) fs = 50e6; end
if (nargin< 2)
    error('Нужно передать как минимум два аргумента');
end

switch parseID(connectionID)
    case 1
        % Waveform Generator 33500B USB visa 
        % Этот блок игнорируется если соединение происходит через LAN см. блок "Waveform Generator 33500B LAN"
        % Идентификатор (4 аргумент) берется из Keysight Connection Expert
        WG_obj = instrfind('Type', 'visa-usb', 'RsrcName', connectionID, 'Tag', '');
        
        if isempty(WG_obj) % В аргументах visa может применяться новое название 'KEYSIGHT', 
            % а может и старое 'AGILENT'.
            WG_obj = visa('Agilent', connectionID);
        else
            fclose(WG_obj);
            WG_obj = WG_obj(1);
        end
        
        % Подстчет производится из расчёта 8 бит на 1 точку
        obj_buffer = 10e6*8;
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
    case 0
        % Waveform Generator 33500B LAN 
        % Этот блок игнорируется если соединение происходит через USB см. блок "Waveform Generator 33500B USB visa"
        % Чтобы посмотреть ip генератора - кнопка System -> I/O config -> LAN
        % settings
        WG_obj = instrfind('Type', 'tcpip', 'RemoteHost', connectionID, 'RemotePort', 5025, 'Tag', '');
        
        % Сценарий соединения с инструментом взят из tmtool
        % Create the tcpip object if it does not exist
        % otherwise use the object that was found.
        if isempty(WG_obj)
            WG_obj = tcpip(connectionID, 5025);
        else
            fclose(WG_obj);
            WG_obj = WG_obj(1);
        end
        
        % Подстчет производится из расчёта 8 бит на 1 точку
        obj_buffer = 10e6*8;
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
    otherwise
        error('Не удалось подключиться к инструменту :(')
end

% Отправка данных на генератор 33500B(этот блок общий как для LAN так и для USB и запускается после соединения с инструментом)
% Запрос имени инструмента
fprintf (WG_obj, '*IDN?');
idn = fscanf (WG_obj);
fprintf (idn)
fprintf ('\n\n')

% Название вашего массива в инстументе
name = ArbFileName;
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
if isrow(data) == 0
    data = data';
end

% Некоторые версии Matlab требую double
data = single(data);

% Включить или выключить встроенный фильтр на генераторе
ON_OFF_FILTER_CH1 = ['SOURce1:FUNCtion:ARBitrary:FILTer ', 'OFF'];
fprintf(WG_obj, ON_OFF_FILTER_CH1); 

% Размещаем данные между 1 и -1
mx = max(abs(data));
data = (1*data)/mx;

% Обновляем окно загрузки
waitbar(.1,h,mes);

% Очистка временной памяти
fprintf(WG_obj, 'SOURce1:DATA:VOLatile:CLEar'); 

% Устанавливаем порядок следования байт
% BORD = Byte ORDer
fprintf(WG_obj, 'FORM:BORD SWAP');  

% Количество байт
SENT_TO_WG_Bytes=num2str(length(data) * 4); 

% Создание заголовка для binblock
header= ['SOURce1:DATA:ARBitrary ', name, ', #', num2str(length(SENT_TO_WG_Bytes)), SENT_TO_WG_Bytes]; 

% Конвертация данных в формат unsigned int8
binblockBytes = typecast(data, 'uint8');

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

function flag = parseID(id)
    flag = false;
    len = length(id);
    for i = 1:len
        if id(i) == ':'
            flag = true;
        end
    end


return;