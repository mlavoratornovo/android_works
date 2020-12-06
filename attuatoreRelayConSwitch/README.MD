<strong>ATTUATORE WIRELESS CON RELAY E SWITCH DI CONTROLLO.</strong>

<p>Attuatore per un relay e uno switch di controllo.</p>
<p>Relay collegato al pin 8 e switch collegato al pin 2.</p>
<p>Invia un byte valorizzato 8 se lo switch passa da High a Low quando il relay non e' attivo, oppure se dopo tre secondi dalla disattivazione del relay lo switch e' in stato Low.</p>
E' composta da : <br>
<ul>
<li>un modulo wireless zigbee della DIGI con relativo shield di espansione Arduino (https://www.dfrobot.com/product-61.html).</li>
<li>un arduino uno (o inferiore)</li>
<li>un relay collegato al pin 8 in output</li>
<li>un micro switch collegato al pin 2 in output</li>
</ul>
<br>
<p>L'unità risponde ai seguenti 6 comandi : </p>
<p>
<ul>
<li>APRI (3)</li> 
<li>CHIUDI (4)</li>
<li>RIPRISTINA (1)</li>
<li>SETUP ('S')</li>
<li>COMANDO ('C')</li>
<li>RICHIESTASETUP ('T')</li>
</ul>
</p>
<br>
<p>Note : nel caso in cui si usi lo sleep mode di xbee il D09 dell'xbee va collegato al D12 di arduino</p>