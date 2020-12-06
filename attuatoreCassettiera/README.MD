<strong>ATTUATORE WIRELESS PER CASSETTIERA.</strong>

l'unità attuatore wireless con relay è composta da : <br>
<ul>
<li>un modulo wireless zigbee della DIGI con relativo shield di espansione Arduino (https://www.dfrobot.com/product-61.html).</li>
<li>un arduino uno (o inferiore)</li>
<li>3 micro switch per segnalare fine corsa apri (su pin 8), fine corsa chiudi (su pin 9), cassetto aperto (su pin 2)</li>
<li>shield per pilotare un micro motore per l'automazione della serratura (pin 5 e 4)</li>
</ul>
<br>
<p>
il firmware apre e chiude una serratura sino a quando il meccanismo non arriva a fine corsa sia in apertura che in chiusura.</p>
<p>Se viene aperto il cassetto (cassettoApertoVal == LOW) quando la serratura è chiusa (fineCorsaChiudiVal == HIGH) viene inviata una eccezione all'unita logica.</p>
<p>L'inidirizzo dell'unità logica viene inviato all'attuatore con il comando 'S' che lo registra in una variabile.</p>
<p>I comandi sono composti da due byte il primo e in tipo di messaggio inviato 1 = comando e il secondo è il comando.
</p>
<p>L'unità risponde ai seguenti 6 comandi : </p>
<p>
<ul>
<li>APRI (3)</li> 
<li>CHIUDI (4)</li>
<li>RIPRISTINA (1)</li>
<li>SETUP ('S')</li>
<li>COMANDO ('C')</li>
</ul>
</p>
<br>
<p>Note : nel caso in cui si usi lo sleep mode di xbee il D09 dell'xbee va collegato al D12 di arduino</p>