import pyvisa
import numpy as np
import matplotlib.pyplot as ploty
import os

# Connect to instrument
rm = pyvisa.ResourceManager()
s = rm.list_resources()
# ESA_obj = rm.open_recource('USB0::0x2A8D::0x1B0B::MY60240336::0::INSTR')
print("\nList of resources: \n")
for i in range(len(s)):
	print(s[i])
print("\nType of the list is: ", type(s), '\n')
print("\nThe first element: ", s[0], '\n')
print('\nType of the first element: ', type(s[0]), '\n')

input()
