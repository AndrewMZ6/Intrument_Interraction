classdef Service
    methods (Static)
        function  showGraph(sig)
            figure;
            subplot(2, 2, 1);
            plot(abs(sig));grid on; title([inputname(1), ' nofft abs']);
            subplot(2, 2, 2);
            scatter(real(sig), imag(sig), '.'); grid on; title([inputname(1), ' no fft scatter']);
            subplot(2, 2, 3);
            plot(abs(fft(sig))); grid on; title([inputname(1), ' fft abs']);
            subplot(2, 2, 4);
            scatter(real(fft(sig)), imag(fft(sig)), '.'); grid on; title([inputname(1), 'fft scatter']);
        end

        function val = specShrinker(timeDomSig)
            spec = fft(timeDomSig);
            specCut = [spec(101:511), spec(513:924)];
            val = specCut;
        end

        function val = specConcatenator(spec)
            newspec = zeros(1, 1024);
            newspec(101:511) = spec(1:411);
            newspec(513:924) = spec(412:823);
            val = newspec;
        end

        function p = searchNan(input)
            for i=1:length(input)
                if isnan(input(i))
                    k = i;
                    p = 1;
                    disp(['В массиве "', inputname(1), '" обнаружен NaN. Индекс расположения ', num2str(k)]);
                    break
                else
                    p = 0;
                end
            end
        end
    end
end

