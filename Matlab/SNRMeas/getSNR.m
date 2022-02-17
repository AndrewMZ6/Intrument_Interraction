function [SNRList, BERList] = getSNR(wgID, osciID, sigAmpList, noiseAmpList, params)
  
% на вход функция принимает:

% wgID и osciID -             ID двух инструментов - waveform generator и oscilloscope;
% params -                    набор нужный для демодуляции функцией dem - data, RECO, car_sig, L, DATA;
% sigAmpList, noiseAmpList -  список значений амплитуды напряжений для сигнала и шума. По этим значениям будет проходить итерация;
% sigAmpList и noiseAmpList должны быть одинаковой длины;
% SNRList, BERList - являются выходными массивами функции и содержат значения SNR и BER, соответствующие друг другу.
% по этим двум массивам стоится график BER vs SNR;

% RMS_sig, RMS_Noise - root mean square - среднеквадратичные значения напряжения сигнала и шума. Генерируются внутри функции;
% используемые функции getRMS(), getFromOsci2() и dem() находятся в папке с этим же файлом в файле getRMS.m, getFromOsci2.m, dem.m соответственно;

for i = 1:length(sigAmpList)
    % выключить каналы 1 и 2
    channelOnOff(wgID, 1, 'OFF');
    channelOnOff(wgID, 2, 'OFF');
    
    % изменить значение амплитуды сигнала на канале 1
    channelAmp(wgID, 1, sigAmpList(i));
    
    % включить канал 1
    channelOnOff(wgID, 1, 'ON');

    % измерить RMS канала 1
    RMS_sig = str2num(getRMS(osciID));

    % выключить канал 1
    channelOnOff(wgID, 1, 'OFF');

    % изменить значение амплитуды шума на канале 2
    channelAmp(wgID, 2, noiseAmpList(i));

    % включить канал 2
    channelOnOff(wgID, 2, 'ON');

    % измерить RMS канала 2
    RMS_Noise = str2num(getRMS(osciID));

    % выключить канал 2
    channelOnOff(wgID, 2, 'OFF');

    % подсчитать значение SNR и добавить в список 
    SNR = 10*log10((RMS_sig^2)/(RMS_Noise^2));
    SNRList(i) = SNR;
    
    % включить каналы 1 и 2
    channelOnOff(wgID, 1, 'ON');
    channelOnOff(wgID, 2, 'ON');

    % измерить BER при новой SNR и добавить в список
    data = getFromOsci2(osciID);

    BER = dem(data, params);
    BERList(i) = BER;
    disp(['На итерации номер ', num2str(i), ' BER = ', num2str(BER), '' ...
        ', SNR = ', num2str(SNR),])

end
end
