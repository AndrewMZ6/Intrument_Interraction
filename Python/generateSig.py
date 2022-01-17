import scipy
import numpy as np
import matplotlib.pyplot as plt

# размер рандомной последовательности 1хN
N = 1000

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
gsize = 50

# генерация защитного интервала
guardInt = np.zeros([1, gsize])

# добавление защитных интервалов к модулированным данным
ofdm = list(guardInt[0]) + modulated + list(guardInt[0])

# для abs(ofdm) выдается ошибка
# TypeError: bad operand type for abs(): 'list'
# поэтому хитрим
k = [abs(x) for x in ofdm]
# можно было сделать и по другому
# ofdm = np.array(ofdm)

# применяем inverse fft
timeDom = scipy.fft.ifft(ofdm)

# построение графика
fig, (ax1, ax2) = plt.subplots(2, 1)

ax1.plot(k)
# подпись графика, сетка, подписи осей
ax1.set_title('freq domain')
ax1.grid()
ax1.set_xlabel('freq')
ax1.set_ylabel('amp')

ax2.plot(abs(timeDom))
ax2.set_title('time domain')
ax2.grid()
ax2.set_ylabel('amp')
ax2.set_xlabel('time')

fig, ax = plt.subplots()
ax.scatter(np.real(np.array(ofdm)), np.imag(np.array(ofdm)))
ax.grid()
# показать график
plt.show()
