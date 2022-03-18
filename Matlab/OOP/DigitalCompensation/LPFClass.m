classdef LPFClass < handle
    
    properties
        faxis, Fcut = 8e6, filteredSpec, filteredTime, H, ofdmTime, Nextended;
    end
    properties (Dependent)
        timeConst;
    end

    methods
        function this = LPFClass(faxis, ofdmTime, Nextended)
            this.faxis = faxis;
            this.ofdmTime = ofdmTime;
            this.Nextended = Nextended;
        end
        function genH(this)            
            this.H = 1./(1 + 1i*2*pi*this.faxis*this.timeConst);
        end

        function val = get.timeConst(this)
            val = 1/(2*pi*this.Fcut);
        end

        function applyH(this)
            spec = fft(this.ofdmTime);
            zerosArray = zeros(1, this.Nextended);
            zerosArray(1:1024) = spec;
            this.filteredSpec = zerosArray.*this.H;
            this.filteredTime = ifft(this.filteredSpec(1:1024));
        end

        function showH(this)
            figure; 
            subplot(1, 2, 1);
                loglog(this.faxis, abs(this.H));
                title('АЧХ RC фильтра 1 порядка');
                ylabel('gain'); xlabel('freq, Hz');
                ylim([0, 1.1]);
                grid on;
            subplot(1, 2, 2);
                scatter(real(this.H), imag(this.H), '.');
                title('Созвездие фильтра'); 
                ylabel('Imag'); xlabel('Real');
                xlim([-1, 1]); ylim([-1, 1]);
                grid on;
        end

    end
end

