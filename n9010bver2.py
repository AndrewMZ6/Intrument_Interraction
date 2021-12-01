import pyvisa
import numpy as np
import matplotlib.pyplot as plt
import os
from scipy.fft import fft, ifft

# Connect to instrument
rm = pyvisa.ResourceManager()
s = rm.list_resources()
# ESA_obj = rm.open_recource('USB0::0x2A8D::0x1B0B::MY60240336::0::INSTR')
ESA_obj = rm.open_resource(s[-1])

ESA_obj.timeout = 10000 # Set timeout 10 seconds

# Getting intrument name
ESA_obj.write('*IDN?')
instr_name = ESA_obj.read()

ESA_obj.write('INST:SEL BASIC')
ESA_obj.write('FREQ:CENT 11e6')
ESA_obj.write('INIT:CONT OFF')
ESA_obj.write('WAV:SWE:TIME 500e-6')
#ESA_obj.write('WAV:BAND 5e6')
ESA_obj.write('INIT:IMM ;*OPC?')
ESA_obj.write('WAV:SRAT 10e6')
ESA_obj.write('FORM:DATA ASC')
ESA_obj.write('READ:WAV0?')

data = ESA_obj.read()

#print(data)

#ESA_obj.write('SYST:PRES;*OPC?')
#print(ESA_obj.read())

#maxDATA = max(TRACE_DATA_array)
#minDATA = min(TRACE_DATA_array)

#ploty.plot(data)
#ploty.autoscale(True, True, True)
#ploty.show()
print('Длина массива data = ' + str(len(data)) + ', тип = ' + str(type(data)))

mylist = data.split(',')
print(mylist[10], ' Тип = ' + str(type(mylist[10])) + ' Длина массива mylist = ' + str(len(mylist)))
I = []
Q = []

for i in range(len(mylist)):
	if i%2 == 0:
		Q.append(float(mylist[i]))
	else:
		I.append(float(mylist[i]))

complArray = []
for i in range(len(I)):
	complArray.append(complex(I[i], Q[i]))
	print('I = ' + str(I[i]) + ', Q = ' + str(Q[i]))

print('\n Тип I и Q = ' + str(type(I[10])) + ' Длина массива I = Q = ' + str(len(I)))
input()

#abs_array = abs(complArray)
c_array_fft = fft(complArray)
abs_fft = abs(c_array_fft)
fig, ax1 = plt.subplots()
ax1.plot(abs_fft)
ax1.set_title("spectrum")
#ax2.scatter(Q, I)
#ax[1].plot(abs_array)
#plt.scatter(Q, I)
plt.show()

ESA_obj.clear()
ESA_obj.close()