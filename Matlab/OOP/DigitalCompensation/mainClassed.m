clc;
clearvars;
close all;

% SNR в канале компенсации
snrComp = 30;
% SNR в приёмо-передающем тракте
% snrRxTx = 10;

snrArray =  50:-0.1:-5;
plevel = -10:0.1:10;


% Preallocating arrays
errArrayWithComp = zeros(length(plevel), length(snrArray));
errNoCompNoInterf = zeros(length(plevel), length(snrArray));
errArray = zeros(length(plevel), length(snrArray));
lev = zeros(length(plevel), length(snrArray));
usefulToInterfDB_Ar = zeros(1, length(plevel));

% набор коэффициентов


p = 0;
for plev = plevel
    p = p + 1;
    k = 0;
    for snrRxTx = snrArray
        %% Оценка канала компенсации
        k = k + 1;
        % Сгенерирован тестовый сигнал для цепи компенсации
        testSig1 = gen;
        testSig1.generateOFDM;
        
        % OFDM сигнал подан на ФНЧ
        lowPComp = LPFClass(testSig1.faxis, testSig1.ofdmTime, testSig1.Nextended);
        lowPComp.genH;
        lowPComp.applyH;
        
        % Добавление шума в канал компенсации
        noisedComp = awgn(lowPComp.filteredTime, snrComp, 'measured');
        
        sAfter = Service.specShrinker(noisedComp);
        sBefore = Service.specShrinker(testSig1.ofdmTime);
        
        % Оценка канала компенсации
        H1 = sAfter./sBefore;
        %% Оценка приёмо-передающего тракта
        
        % Тестовый сигнал проходит по многолучевому каналу 
        multPathRxTx = multiPathChan(testSig1.fs, 3, testSig1.ofdmTime);
        multPathRxTx.genRays;
        multPathRxTx.applyRays;
        
        % После многолучевости сигнал проходит ФНЧ
        lowPRxTx = LPFClass(testSig1.faxis, multPathRxTx.distortedTime, testSig1.Nextended);
        lowPRxTx.genH;
        lowPRxTx.applyH;
        
        % Добавление шума в канал приёмо-передающего тракта
        noisedRxTx = awgn(lowPRxTx.filteredTime, snrRxTx, 'measured');
        
        sAfter = Service.specShrinker(noisedRxTx); 
        % Оценка канала приёмо-передающего тракта
        H2 = sAfter./sBefore;
        %% Формировние гасящего(extinguish) сигнала
        % формируется сигнал, который будет скомпенсирован
        goodSig = gen;
        goodSig.generateOFDM;
        
        % Предыскажения
        comp = Service.specShrinker(goodSig.ofdmTime).*H2./H1;
        compSpec = Service.specConcatenator(comp);
        
        % Такой предыскаженный инвертированный сигнал во временной области начнёт
        % движение по каналу компенсации
        compTimeInverted = ifft(compSpec)*-1;
        
        % ФНЧ канала компенсации
        lowPComp.ofdmTime = compTimeInverted;
        lowPComp.applyH;
        
        % Добавление шума в канал компенсации
        noisedComp = awgn(lowPComp.filteredTime, snrComp, 'measured');
        
        % сигнал noisedComp придёт на сумматор
        %% Формирование сигнала-помехи
        
        % многолучёвость приёмо-передающего канала
        multPathRxTx.ofdmTime = goodSig.ofdmTime;
        multPathRxTx.applyRays;
        
        % ФНЧ приёмо-передающего канала
        lowPRxTx.ofdmTime = multPathRxTx.distortedTime;
        lowPRxTx.applyH;
        
        noisedInterf = awgn(lowPRxTx.filteredTime, snrRxTx, 'measured');

        rmsInterf = rms(lowPRxTx.filteredTime);
        rmsNoisedInterf = rms(noisedInterf);
        rmsRX = (10^(plev/20))*rmsInterf;
        %% Формирование полезного сигнала
        usefulSig = gen;
        usefulSig.generateOFDM;
        
        % Этот сигнал будет только зашумлён и демодулирован. Без компенсации
        
%         usefulSigNoComp = usK*(usefulSig.ofdmTime);
        rmsUseful = rms(usefulSig.ofdmTime);
        co = rmsRX/rmsUseful;
        usefulSigNoComp = co*usefulSig.ofdmTime;
        usefulSig.ofdmTime = usefulSigNoComp;
        rmsUseful = rms(usefulSig.ofdmTime);
        %% Смесь полезного и сигнала-помехи
        mixed = usefulSig.ofdmTime + lowPRxTx.filteredTime;
        
        % Добавление шума в смесь 
        noisedRxTx = awgn(mixed, snrRxTx, 'measured');
        
        % Добавление шума для полезного без компенсации
        usefulSigNoCompNoised = awgn(usefulSigNoComp, snrRxTx, 'measured');
        %% В сумматоре
        % сигнал lowPRxTx.filteredTime пойдет на сумматор
        sigSum = noisedComp + noisedRxTx;
        
        % Расчёт уровня компенсации в дБ
        intAndComp = noisedInterf + noisedComp;
        lev(p, k) = 20*log10(rmsNoisedInterf/rms(intAndComp));
        
        %% Демодуляция полезного сигнала после компесации
        usefulSig.demodRx(sigSum);
        usefulSig.getErr;
        errArrayWithComp(p, k) = usefulSig.err(2);

        usefulSig.demodRx(noisedRxTx);
        usefulSig.getErr;
        errArray(p, k) = usefulSig.err(2);

        usefulSig.demodRx(usefulSigNoCompNoised);
        usefulSig.getErr;
        errNoCompNoInterf(p, k) = usefulSig.err(2);
        
    end
    usefulToInterfDB = 20*log10(rmsUseful/rmsInterf);
    disp(['Полезный мощнее помехи на: ' , num2str(usefulToInterfDB), ' дБ']);
    
%     semilogy(snrArray, errWithComp, snrArray, errNoComp); hold on;
%     grid on; legend('С смешиванием', 'Без смешивания');
%     xlim([5, 20]); ylim([0, 1.1]);
%     xlabel('SNR в приёмо-передающем канале'); ylabel('BER');
    usefulToInterfDB_Ar(p) = usefulToInterfDB;
%     pause(0.5);
end
% return


usefulToInterfDB = 20*log10(rmsUseful/rmsInterf);
disp(['Полезный мощнее помехи на: ' , num2str(usefulToInterfDB), ' дБ']);

% return
%% Графики
% figure;
% plot(abs(sigSum));
% hold on;
% plot(abs(noisedRxTx));
% title(['уровень компенсации ', num2str(lev), ' дБ'])
% legend('после компенсации', 'до компенсации');

%% 3D

figure;
h=gca; 
surf(snrArray, usefulToInterfDB_Ar, errArrayWithComp); hold on;
xlabel('SNR, dB'); ylabel('Puseful / Pinterf, dB');
zlabel('BER');
title('С компенсацией');
set(h,'zscale','log');

% figure;
h=gca; 
surf(snrArray, usefulToInterfDB_Ar, errArray);
xlabel('SNR, dB'); ylabel('Puseful / Pinterf, dB');
zlabel('BER');
title('Без компенсации');
set(h,'zscale','log');

figure;
h=gca; 
surf(snrArray, usefulToInterfDB_Ar, errNoCompNoInterf);
xlabel('SNR, dB'); ylabel('Puseful / Pinterf, dB');
zlabel('BER');
title('До смешивания');
set(h,'zscale','log');

figure;
plot(snrArray, lev(1, :));
grid on;
xlabel('SNR, dB');
ylabel('Compensation, dB');
title('Уровень компенсации');

