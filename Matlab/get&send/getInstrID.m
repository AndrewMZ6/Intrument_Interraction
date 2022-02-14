function [id] = getInstrID(model, connection)

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
    if (strcmpi(model, 'r&s')) % У модели R&S есть только LAN соединение
        connection = 'LAN';
    else
        connection = 'USB'; 
    end
end

% В зависимости от аргумента модели срабатывает case
switch model
    case 'cxg'
        if (strcmpi(connection, 'USB'))
            id = 'USB0::0x0957::0x1F01::MY59100546::0::INSTR';
        else
            id = '192.168.0.85';
        end
    case 'exa'
        if (strcmpi(connection, 'USB'))
            id = 'USB0::0x2A8D::0x1B0B::MY60240336::0::INSTR';
        else
            id = '192.168.0.73';
        end
    case 'wg'
        if (strcmpi(connection, 'USB'))
            id = 'USB0::0x0957::0x2807::MY57401328::0::INSTR';
        else
            id = '192.168.0.100';
        end
    case 'dsox'
        if (strcmpi(connection, 'USB'))
            id = 'USB0::0x2A8D::0x1797::CN58056332::0::INSTR';
        else
            error('DSOX осциллограф не имеет LAN соединения');
        end
    case 'r&s'
        if (strcmpi(connection, 'USB'))
            error('r&s анализатор не имеет USB соединения');
        else
            id = '192.168.073';
        end
    otherwise
        error('Для выбранной модели идентификатора нет')
end

return;
