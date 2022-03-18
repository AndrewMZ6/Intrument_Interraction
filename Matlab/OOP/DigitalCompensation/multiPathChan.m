classdef multiPathChan < handle
    
    properties
        ofdmTime, fs, rayNum, distortedTime;
        delays, koeffs;
    end
    
    methods
        function this = multiPathChan(fs, rayNum, ofdmTime)
            this.fs = fs;
            this.rayNum = rayNum;
            this.ofdmTime = ofdmTime;
        end
        
        function genRays(this)
            for i = 1:this.rayNum
                randNum = randi([500, 8000]);
                this.koeffs(i) = 1 - randNum/9000;
                this.delays(i) = randNum*1e-11;
            end
        end
        
        function applyRays(this)
            spec = fft(this.ofdmTime);
            NN = length(this.ofdmTime);
            sumSig = this.ofdmTime;
            for o = 1:this.rayNum
                % вычисляется фазовый угол соответствующий задержке
                dphi(o) = 2*pi*this.delays(o)*this.fs/NN;
                for j = 1:NN
                    specShifted(o, j) = spec(j)*exp(-1i*dphi(o)*j);
                end
                timeSig(o, :) = ifft(specShifted(o,:))*this.koeffs(o);
                sumSig = sumSig + timeSig(o, :);
            end
            this.distortedTime = sumSig;
        end
        function showConst(this)
            scatterplot(fft(this.distortedTime)); 
            grid on; title('после многолучевого');
        end

    end
end

