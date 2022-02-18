function genNoise(connectionID, amp, bw)

% Функция отвечающая за установку шума на канале 1 или 2
% WaveformGenerator 33500B
%
% genNoise(connectionID, amp, bw, chNum)
% 
% chNum - номер канала, 1 или 2
% amp - зачение амплитуды в Вольтах/МиллиВольтах

% предел полосы для шума от 1 мГц до 20 МГц
if (nargin< 3) bw = 10e6; end
if (nargin< 2) amp = 50e-3; end
if (nargin< 1) connectionID = 'USB0::0x0957::0x4B07::MY53401534::0::INSTR'; end

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

% Создания полосы загрузки
mes = ['Connected to ' idn ' sending waveforms.....'];
h = waitbar(0,mes);

% Обновляем окно загрузки
waitbar(.1,h,mes);

% Очистка временной памяти
fprintf(WG_obj, 'SOURce2:DATA:VOLatile:CLEar'); 

% Обновляем окно загрузки
waitbar(.8,h,mes);

% Сообщаем, что в канал 2 нужно подать шум
command = 'SOURce2:FUNCtion NOISe';
% Выполнить команду
fprintf(WG_obj,command); 

% устанавливаем ширину полосы шума
command = ['SOURce2:FUNCtion:NOISe:BAND ', num2str(bw)];
% Выполнить команду
fprintf(WG_obj,command);

% Обновить окно загрузки
waitbar(.9,h,mes);

% установка размаха шума по амплитуде
command = ['SOURCE2:VOLT ' num2str(amp)];
% Выполнить команду
fprintf(WG_obj,command);

% Включить выход 2 (если выход включен над ним загорается лампочка)
fprintf(WG_obj,'OUTPut2 ON');

% Заполняем окно загрузки, удаляем его
waitbar(1,h,mes);
delete(h);

% Проверка наличия ошибок
fprintf(WG_obj, 'SYST:ERR?');
errorstr = fscanf (WG_obj);

% Вывод ошибок
if strncmp (errorstr, '+0,"No error"',13)
   errorcheck = 'Шум успешно добавлен \n';
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
