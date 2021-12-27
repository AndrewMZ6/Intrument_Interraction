# -*- coding: utf-8 -*-
"""
Created on Mon Dec 27 14:55:03 2021

@author: st13zabv
"""
from scipy.fft import fft, ifft
import pyvisa
import matplotlib.pyplot as plt

rm = pyvisa.ResourceManager()
s = rm.list_resources()

# Вывести список доступных инструментов
print(s)

# открыть соединение с инструментом
exa = rm.open_resource('USB0::0x2A8D::0x1B0B::MY60240336::0::INSTR')

# проверить содеинение - запросить имя и вывести в консоль
name = exa.query('*IDN?')
print(name)

# установка режима 
exa.write('INST:SEL BASIC')

# установка конфигурации для данного режима
exa.write('CONFigure:WAVeform')

# установка центральной частоты
exa.write('FREQuency:CENT 500e6')

# установка частоты дискретизации
exa.write(':WAVeform:SRATe 20e6')

# установка времени снятия данных
exa.write(':WAV:SWE:TIME 2e-3')

# снять единичное измерение (пауза)
exa.write('INIT:CONT OFF')

# получение данных
data = exa.query_ascii_values('READ:WAV0?')

# если просто запросить data через query, то он вернёт Comma Separated Values
#data_split = data.split(',')

# создать пустых массивов
I = []
Q = []

# четные, т.е. 0, 2, 4, ... в I
# нечетные, т.е. 1, 3, 5, ... в Q
for i in range(len(data)):
    if i%2 == 0:
        I.append(float(data[i]))
    else:
        Q.append(float(data[i]))
        
# созд
compl = []
for i in range(len(I)):
    compl.append(complex(I[i], Q[i]))
    
spec = fft(compl)

fig, ax = plt.subplots()
ax.plot(abs(spec))
ax.grid()
ax.set(title = 'Spectrum')

fig,ax = plt.subplots()
ax.scatter(spec.real, spec.imag)
ax.grid()
ax.set(title = 'Scatterplot')
plt.show()

exa.close()

# теперь мне нужно скоррелировать полученные данные с референсом. Но референс лежит в генераторе CXG
# неплохо было бы взять референс прямо у CXG

cxg = rm.open_resource('USB0::0x0957::0x1F01::MY59100546::0::INSTR')

cxg_name = cxg.query('*IDN?')
print(cxg_name)

# в каталоге есть наш отпраленный файлик
cat = cxg.query('MEMory:CATalog?')
print(cat)

# данные получаются, но слишком большие (как мне кажется)
data1 = cxg.query_binary_values(':MMEMory:DATA? "PILOT + OFDM@NVWFM"')

# NV - non volatile, HDR - header, MKR - marker, WFM - waveform
bin1 = cxg.query('MEMory:CATalog:BINary?')
print(bin1)

cxg.close()
