function [id] = getInstrInfo(model, connection)

% function [id] = getInstrInfo(model, connection)
%
% id - идентификатор для данного вида соединения
% model - имя модели инструмента(строка)
% connection - вид соединения: USB, LAN (строка)
%
% Функция принимает на вход параметры и в зависимости от них выдает
% идентификатор - либо IP адрес инструмента, если вид соединения LAN, либо
% идентификатор USB соединения. Варианты IP адресов и USB идентификаторов
% прописаны внутри функции!


% Если на вход было подано меньше одного аргумента
if nargin < 1
    error('Требуется указать инструмент')
end

% Если на вход был подан только первый аргумент
if (nargin<2) 
    if (strcmpi(model, 'R&S')) % У модели R&S есть только LAN соединение
        connection = 'LAN';
    else
        connection = 'USB'; 
    end
end

% Если модель - это cxg
if (strcmpi(model, 'cxg'))
    if (strcmpi(connection, 'USB'))
        id = 'USB0::0x0957::0x1F01::MY59100546::0::INSTR';
    else
        id = '192.168.0.85';
    end
end
