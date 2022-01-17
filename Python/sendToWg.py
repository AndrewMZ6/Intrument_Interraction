import pyvisa

def sendToWg(data):
    
    rm = pyvisa.ResourceManager()
    
    s = rm.list_resources()
    
    # print(s)
    
    wg = rm.open_resource('USB0::0x0957::0x2807::MY57401328::0::INSTR')
    
    name = wg.query('*IDN?')
    print(name)
    
    # SOURce1:DATA:ARBitrary
    wg.write_ascii_values('SOURce1:DATA:ARBitrary somename,', data)
    
    wg.write('SOURce1:FUNCtion:ARBitrary somename')
    
    wg.write('MMEM:STOR:DATA1 "INT:\somename.arb"')
    
    wg.write('SOURCE1:FUNCtion:ARB:SRATe 50e6')
    
    wg.write('SOURce1:FUNCtion ARB')
    
    wg.write('SOURCE1:VOLT 0.1')
    
    wg.write('OUTPUT1 ON')
    
    wg.close()
