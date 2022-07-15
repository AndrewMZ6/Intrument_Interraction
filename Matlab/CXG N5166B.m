%% send to CXG
% Find a VISA-USB object.adasd
device = instrfind('Type', 'visa-usb', 'RsrcName', 'USB0::0x0957::0x1F01::MY59100546::0::INSTR', 'Tag', '');

% Create the VISA-USB object if it does not exist
% otherwise use the object that was found.
if isempty(device)
    device = visa('AGILENT', 'USB0::0x0957::0x1F01::MY59100546::0::INSTR');
else
    fclose(device);
    device = device(1);
end

device_buffer = 10000000*8;
set(device,'OutputBufferSize',(device_buffer+125));
% Connect to instrument object, obj1.
fopen(device);
fprintf(device, '*CLS');
ArbFileName = 'LOL';

wave = [I;Q]; % get the real and imaginary parts
wave = wave(:)';    % transpose and interleave the waveform

tmp = 1; % default normalization factor = 1
% 
% % ARB binary range is 2's Compliment -32768 to + 32767
% % So scale the waveform to +/- 32767 not 32768
modval = 2^16;
scale = 2^15-1;
scale = scale/tmp;
wave = round(wave * scale);

wave = wave*0.11;
%  Get it from double to unsigned int and let the driver take care of Big
%  Endian to Little Endian for you  Look at ESG in Workspace.  It is
%  property of the VISA driver (at least Agilent's
%  if your waveform is skrewy, suspect the NI driver of not changeing
%  BIG ENDIAN to LITTLE ENDIAN.  The PC is BIG ENDIAN.  ESG is LITTLE
wave = uint16(mod(modval + wave, modval));

% write the waveform data
binblockwrite(device,wave,'uint16',[':MEMory:DATa:UNProtected "WFM1:' ArbFileName '", ']);
fprintf(device,'\n');

fprintf(device, '*WAI');

playcommand = [':SOURce:RAD:ARB:WAV "ARBI:' ArbFileName '"'];
fprintf(device, playcommand);

errors = query(device, 'SYST:ERR?');
fprintf(['Error respose: ', errors]);
arbname = query(device, 'RAD:ARB:WAV?');
fprintf(['Current ARB file: ', arbname]);

fclose(device);
