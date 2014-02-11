#  Regenerate.m
#    Regenerates wave from CVDB.
#    Depends on various Plugins and Octs.

#  Not finished yet.

function Ret = Regenerate(Path)
        addpath("../");
        addpath("../Oct");
        addpath("../Util");
        
        global CVDB_Residual;
        global CVDB_Sinusoid_Magn;
        global CVDB_Sinusoid_Freq;
        global CVDB_Wave;
        
        global FFTSize;
        global SampleRate;
        global Window;
        global Environment;
        SampleRate = 44100;
        FFTSize = 2048;
        Window = hanning(FFTSize);
        Environment = "Procedure";
        
        load(Path);
        CVDBUnwrap;
        
        [PSOLAMatrix, PSOLAWinHalf] = PSOLAExtraction(CVDB_Wave, CVDB_Pulses);
        
        #Modifications to CVDB can be done here
        #----------------------------------------------------------------------
        
        CVDB_Pulses2 = CVDB_Pulses;
        for i = 2 : length(CVDB_Pulses)
                #CVDB_Pulses(i) = CVDB_Pulses(i - 1) + fix(...
                #                 (CVDB_Pulses2(i) - CVDB_Pulses2(i - 1)) ...
                #                 + (sin(i * 0.07) * 5) - 50);
                #CVDB_Pulses(i) = fix(CVDB_Pulses2(i) * 1.2);
        end
        
        #----------------------------------------------------------------------
        
        #Transition Region
        T = PSOLASynthesis(PSOLAMatrix, PSOLAWinHalf, CVDB_Pulses);
        
        #Approximate F0
        Center = fix(length(PSOLAWinHalf) / 2);
        CenterPos = CVDB_Pulses(Center);
        Period = CVDB_Pulses(Center) - CVDB_Pulses(Center - 1);
        ApprBin = fix(FFTSize / Period);
        
        #Window
        Wide = T(CenterPos - FFTSize / 2 : CenterPos + FFTSize / 2 + 99);
        Selection = Wide(1 : FFTSize);
        Selection = Selection .* Window;
        
        #Transform
        X = fft(fftshift(Selection));
        Amp = 20 * log10(abs(X));
        Arg = arg(X);
        
        #Bin F0
        global Plugin_Var_F0;
        [Y, Plugin_Var_F0] = max(Amp(ApprBin - 2 : ApprBin + 2));
        Plugin_Var_F0 += ApprBin - 3;
        
        #Exact F0
        global Plugin_Var_F0_Exact;
        Plugin_F0Marking_ByPhase(Amp, Arg, Selection, Wide, 0);
        
        #Sinusoidal Extraction
        global SpectrumUpperRange;
        SpectrumUpperRange = 10000;
        global Plugin_Var_Harmonics_Freq;
        global Plugin_Var_Harmonics_Magn;
        InitialPhase = zeros(50, 1);
        
        Plugin_HarmonicMarking_Naive(Amp, Arg, Selection);
        for j = 11 : 30
                CVDB_Sinusoid_Magn(1, j) = - 20;
                CVDB_Sinusoid_Magn(2, j) = - 20;
                CVDB_Sinusoid_Magn(3, j) = - 20;
        end
        for j = 1 : 10
                #Decibel to logarithmic sinusoidal magnitude.
                [Freq, Magn] = GetExactPeak(Amp, ...
                                Plugin_Var_Harmonics_Freq(j));
                CVDB_Sinusoid_Magn(1, j) = log(...
                        10 ^ (Magn / 20) ...
                           / FFTSize * 4);
                CVDB_Sinusoid_Freq(1, j) = Freq;
                
                #Transition
                CVDB_Sinusoid_Magn(2, j) = CVDB_Sinusoid_Magn(1, j);
                CVDB_Sinusoid_Freq(2, j) = CVDB_Sinusoid_Freq(1, j);
                CVDB_Sinusoid_Magn(3, j) = (CVDB_Sinusoid_Magn(2, j) + ...
                                            CVDB_Sinusoid_Magn(4, j)) / 2;
                CVDB_Sinusoid_Freq(3, j) = (CVDB_Sinusoid_Freq(2, j) + ...
                                            CVDB_Sinusoid_Freq(4, j)) / 2;
                #Initial phase for deterministic synthesis.
                InitialPhase(j) = Arg(Plugin_Var_Harmonics_Freq(j));
        end
        
        #Unwrap
        CVDB_Sinusoid_Magn = exp(CVDB_Sinusoid_Magn);
        
        #Deterministic
        Ret(1 : CenterPos) = 0;
        Det = DeterministicSynth(CVDB_Sinusoid_Magn, CVDB_Sinusoid_Freq, ...
                InitialPhase, columns(CVDB_Sinusoid_Freq), 256);
        Ret(CenterPos : CenterPos + length(Det) - 1) ...
                 = Det;
        
        #Stochastic
        Offset = CenterPos - CVDB_FramePosition(1);
        Sto = zeros(1, length(Ret));
        for i = 1 : rows(CVDB_Residual) * 2 - 1
                X = GenResidual(CVDB_Residual(fix(i / 2 + 1), : ),
                        8, FFTSize)';
                Residual = real(ifft(X)) .* Window;
                Center = CVDB_FramePosition(i) + Offset;
                Sto(Center - FFTSize / 2 : Center + FFTSize / 2 - 1) += ...
                        Residual';
        end
        
        #Fade Out
        T(CenterPos : CenterPos + 255) .*= 1 - (1 : 256)' / 256;
        Ret(CenterPos : CenterPos + 255) .*=  (1 : 256) / 256;
        Ret(1 : CenterPos + 255) += T(1 : CenterPos + 255)';
        
        wavwrite(T, 44100, 'PSOLA.wav');
        wavwrite(Ret, 44100, 'sinusoidal.wav');
        wavwrite(Sto, 44100, 'residual.wav');
        wavwrite(Sto + Ret, 44100, 'plus.wav');
end

