import generateSig
import sendToWg

a = generateSig.timeDom

sendToWg.sendToWg(abs(a))
