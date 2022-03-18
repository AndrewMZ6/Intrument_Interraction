# Digital compensation components

`mainClassed` - is a main script that calls for other classes to model a digital compensation system.

`gen` - generates random ofdm symbols with fftsize = 1024 (for now) and stores is it in property as well as other information. Also constains demodulation and
error handling methods.

`LPFClass` - low pass RC filter model that takes cut frequency as input, generates frequency response and applies it to input time domain signal.

`multiPathChan` - multipath signal propagation channel model. Takes number of rays, sampling frequency and reflecting signal as inputs.

`Service` - additional class that contains static methods for auxiliary functionality. For instance spectrum shrinker and concatenater, showGraph and searchNAN.

![untitled1](https://user-images.githubusercontent.com/40640833/158981511-2216f643-02d7-4395-ba01-4e99ccc654c1.png)
