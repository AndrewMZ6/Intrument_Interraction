# -*- coding: utf-8 -*-
"""
Created on Fri Jan 14 17:42:43 2022

@author: st13zabv
"""

import scipy
import numpy as np
import matplotlib.pyplot as plt

# размер рандомной последовательности 1хN
N = 100

# генерация рандомной последовательности
bits = np.random.randint(low = 0, high = 2, size = [1, N])

# создание контейнера, куда добавляются модулированные комплексные отсчёты
modulated = []

# qpsk модуляция битовой последовательности bits
for i in range(len(bits[0]) - 1):
    if bits[0][i] and bits[0][i + 1]:
        modulated.append(1 + 1j)
    else:
        if bits[0][i] == 0 and bits[0][i + 1] == 1:
            modulated.append(-1 + 1j)
        elif bits[0][i] == 1 and bits[0][i + 1] == 0:
            modulated.append(1 - 1j)
        else:
            modulated.append(-1 - 1j)
            
# размер защитного интервала
gsize = 10

# генерация защитного интервала
guardInt = np.zeros([1, gsize])

# добавление защитных интервалов к модулированным данным
ofdm = list(guardInt[0][0:5]) + modulated + list(guardInt[0][0:5])

fig, ax = plt.subplots()
ax.plot((ofdm))
plt.show()
