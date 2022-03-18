classdef gen < handle
    %GEN Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        fs = 50e6, bw = 10e6, fftsize = 1024, guardSize = 100;
        bits, ofdmTime, demodedBits, err;
        informationalIndexes1, informationalIndexes2;
    end
    
    properties (Dependent = true)
        deltaF, Nextended, faxis, L, taxis, Ts, sigDuration, ofdmFFT;
    end

    
    methods
        function val = get.ofdmFFT(this)
            val = fft(this.ofdmTime);
        end
        function value = get.deltaF(this)
            % шаг частот на один отсчёт, при учёте, что на 1024 отсчёта
            % приходится 10 МГц
            value = this.bw/this.fftsize;
        end

        function value = get.Nextended(this)
            % количество отсчётов, необходимое чтобы 1024 отсчёта вмещали
            % 10 МГц
            value = this.fs/this.deltaF;
        end
        
        function value = get.L(this)
            % L вычисляется из соображений того, что в символе 1024
            % отсчетов, из них по 100 защитных интервалов справа и слева,
            % т.е. 1024 - 200 = 824. Также оставляется ноль для центральной
            % несущей, т.е. 824 - 1 = 823
            value = this.fftsize - this.guardSize*2 - 1;
        end
        
        function value = get.Ts(this)
            % Период дискретизации
            value = 1/this.fs;
        end

        function array = get.taxis(this)
            % time axis, временная шкала
            array = [0:this.Ts:this.sigDuration - this.Ts];
        end

        function value = get.sigDuration(this)
            % длительность сигнала высчитывается из соображений того, что на
            % один отсчёт длится один период дискретизации, значит чтобы
            % узнать сколько длится весь сигнал нужно умножить количество
            % отсчётов на период дискретизации
            value = this.fftsize*this.Ts; 
        end

        function array = get.faxis(this)
            % frequency axis, шкала частот
            array = [0:this.deltaF:this.fs - this.deltaF];
        end

        function generateOFDM(this)

            % function = generateOFDM(this)
            % -------------------------------------------------------------
            % генерирует случайную битовую последовательность (расчёт
            % размера последовательности смотри в методе get.L) и
            % записывает её в свойство объекта bits
            % 
            % this.bits = randi([0, 1], 1, this.L*2);
            % 
            % модулирует полученную битовую последовательность QPSK:
            % 
            % mod = (qammod(this.bits', 4, 'InputType', 'bit'))';
            % 
            % добавляет защитные интервалы слева и
            % справа, ноль для несущей ставится на 512 отсчёт:
            % 
            % spec = [zeros(1, this.guardSize), mod(1:floor(this.L/2)), 0, ...
            %    mod(ceil(this.L/2):this.L), zeros(1, this.guardSize)];
            % 
            % при L = 823, floor(L/2) = 411, ceil(L/2) = 412. Таким образом
            % ноль попадает в нужный 512 отсчёт.
            % Полученный спектр переводится во временную область и
            % записывается в свойство ofdmTime
            %
            % this.ofdmTime = ifft(spec);
            %
            % -------------------------------------------------------------
            this.bits = randi([0, 1], 1, this.L*2);
            mod = (qammod(this.bits', 4, 'InputType', 'bit'))';
            this.informationalIndexes1 = 1:floor(this.L/2);
            this.informationalIndexes2 = ceil(this.L/2):this.L;
           
            spec = [zeros(1, this.guardSize), mod(this.informationalIndexes1), 0, ...
                mod(this.informationalIndexes2), zeros(1, this.guardSize)];
            this.ofdmTime = ifft(spec);
        end

        function demodRx(this, outerSig)
            % -----------------------------------------------------------
            % Принимает на вход OFDM сигнал во временной области ofdmTime:
            %
            % demodRx(this)
            %
            % подсчитывает спектр входного OFDM сигнала:
            % 
            % ofdmSpec = fft(ofdmTime);
            %
            % вырезает информационные отсчёты, игнорируя защитные интервалы
            % и ноль несущей:
            %
            % noGuardsAndZeros = [ofdmSpec(101:512), ofdmSpec(514:924)];
            %
            % демодулирует информационные отсчёты:
            % 
            % demodedBits = (qamdemod(noGuardsAndZeros', 4, 'OutputType', 'bit'))';
            % 
            % На выход подается демодулированная битовая последовательность
            % demodedBits
            % -------------------------------------------------------------
            ofdmSpec = fft(outerSig);
            % guardSiz
            noGuardsAndZeros = [ofdmSpec(this.guardSize + 1:(this.fftsize/2 - 1)), ofdmSpec((this.fftsize/2 + 1):this.fftsize - this.guardSize)];
            this.demodedBits = (qamdemod(noGuardsAndZeros', 4, 'OutputType', 'bit'))';
        end

        function showTime(this)
            figure;
            plot(this.taxis, abs(this.ofdmTime)); 
            title(['OFDM сигнал во временной области']);
            ylabel('амплитуда'); xlabel('время, сек');
            grid on;
        end

        function showSpec(this)
            figure;
            plot(this.faxis(1:this.fftsize), abs(this.ofdmFFT)); 
            title(['OFDM сигнал в частотной области']);
            ylabel('амплитуда'); xlabel('частота, Гц');
            grid on;
        end
        
        function getErr(this)
            [err, errRate] = biterr(this.bits, this.demodedBits);
            this.err = [err, errRate];
        end

    end
end

