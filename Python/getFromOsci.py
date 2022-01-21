import pyvisa 

def getFromOsci():
    rm = pyvisa.ResourceManager()

    osci = rm.open_resource('USB0::0x2A8D::0x1797::CN58056332::0::INSTR')
    data = osci.query_binary_values('WAV:DATA?')
    
    osci.close()
    
    return data