classdef ofdm
    properties
       fs = 50e6
       fc = 10e6
       N = 1024
       
    end
    % what is this? Oh nevermind it's just another comment :)    
    properties (Dependent = true)
        t, f, signal_time_domain, spectrum
    end
    
    
    methods
        function this = ofdm(varargin)
          
        end
        
        function t = get.t(this)
            % расчёт временной оси
           t = [0:1/this.fs:(this.N - 1)/this.fs];
        end
        
        function f = get.f(this)
           f = [0:this.fs/this.N:this.fs - this.fs/this.N]; 
        end
        
        function signal_time_domain = get.signal_time_domain(this)
            signal_time_domain = sin(2*pi*this.fc*this.t);
        end
        
        function showTime(this)
           figure;
           plot(this.t, this.signal_time_domain);
           title('time domain signal');
           xlabel('time, sec');
           ylabel('amplitude');
           grid on;
        end
        
        function spectrum = get.spectrum(this)
           spectrum = fft(this.signal_time_domain); 
        end
        
        function showSpec(this)
           figure;
           plot(this.f, abs(this.spectrum));
           title('signal spectrum');
           xlabel('frequency, Hz');
           ylabel('amplitude');
           grid on;
        end
    end
end
