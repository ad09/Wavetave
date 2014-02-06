#  Plugin_HarmonicMarking_Naive.m
#    The simplified version of Plugin_HarmonicMarking, which doesn't do
#      fundamental frequency correction as marking harmonic peaks. Instead
#      it uses F0 generated by Plugin_F0Marking_ByPhase to achieve a much
#      higher accuracy.
#  Depends on Plugin_F0Marking_ByPhase.

function Plugin_HarmonicMarking_Naive(Spectrum, Phase, Wave)
        global FFTSize;
        global SampleRate;
        global Plugin_Var_F0;
        global Plugin_Var_F0_Exact;
        global SpectrumUpperRange;
        global Environment;
        global Plugin_Var_Harmonics_Freq;
        global Plugin_Var_Harmonics_Magn;

        #Clear
        Plugin_Var_Harmonics_Freq = 0;
        Plugin_Var_Harmonics_Magn = 0;
        
        #F0
        PinX = Plugin_Var_F0_Exact * FFTSize / SampleRate;
        [PinY, X] = max(Spectrum(fix(PinX) - 3 : fix(PinX) + 3));
        X += fix(PinX) - 4;
        Plugin_Var_Harmonics_Freq(1) = X;
        Plugin_Var_Harmonics_Magn(1) = PinY;
        
        #If the data is valid
        if(Plugin_Var_F0_Exact > 50)
                for i = 2 : fix(SpectrumUpperRange / Plugin_Var_F0_Exact)
                        #Finding maximum
                        PinX = Plugin_Var_F0_Exact * FFTSize / SampleRate * i;
                        [PinY, X] = max(Spectrum(fix(PinX) - 3 : fix(PinX) + 3));
                        X += fix(PinX) - 4;
                        
                        Plugin_Var_Harmonics_Freq(i) = X;
                        Plugin_Var_Harmonics_Magn(i) = PinY;
                        
                        #Plotting
                        if(strcmp(Environment, "Visual"))
                                text(PinX, PinY + 5, strcat("H", mat2str(i - 1)));
                                text(PinX, PinY, cstrcat("x ",
                                     mat2str(fix(PinX * SampleRate / FFTSize)), "Hz"));
                        end
                end
        endif
end

