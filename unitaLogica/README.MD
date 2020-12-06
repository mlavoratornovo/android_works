<strong>UNITA' LOGICA DI CONTROLLO SU ARDUINO UNO.</strong>

l'unità logica di controllo è composta da : <br>
<ul>
<li>un modulo wireless zigbee della DIGI con relativo shield di espansione Arduino (https://www.dfrobot.com/product-61.html).</li>
<li>un chip Real Time Clock RX8025 (https://www.aliexpress.com/item/32318053549.html)</li>
<li>un lettore di schede micro sd per arduino</li>
</ul>
<br>

<strong>L'unità logica si occupa di</strong> : <br>
<ul>
<li>gestisce le comunicazioni con le risorse amministrate</li>
<li>gestire i permessi verso le risorse registrate nella sua SD.</li>
<li>invia comandi ad esecuzione immediata verso le risorse</li>
<li>gestisce la login dell'utente</li>
<li>gestisce il log delle operazioni</li>
</ul>
<br>

<strong>Contenuto della scheda SD</strong> : <br>
<ul>
<li>IMPIANTO.TXT
    <ul>
        <li>Seriale XBEE: 8byte</li>
        <li>idimpianto: 4byte</li>
        <li>tipo: 1byte (1 = attuatore; 2 = sensore; 3 = sensore login)</li>
        <li>idutente: 4byte</li>
    </ul>
</li>
<li>PERMESSI.TXT
    <ul>
        <li>idutente: 4byte</li>
        <li>antenna: 4byte</li>
        <li>risorsa: 4byte</li>
        <li>Orada: 2byte</li>
        <li>Oraal: 2byte</li>
        <li>Giorno: 1byte (0...6)</li>
        <li>Disabled: 1byte</li>                        
    </ul>
</li>
<li>VERBOSIT.TXT
    <ul>
        <li>Codeccezione: 1byte</li>
        <li>log: 1byte</li>
        <li>eccezione: 1byte</li>
    </ul>
</li>
<li>UTENTI.TXT 
    <ul>
        <li>idutente: 4byte</li>
        <li>obbligatoria: 1byte (0 = utente,1 = risorsa obbligatoria,2 = risorsa vietata)</li>
        <li>antenna: 4byte; key -> Da posizione finale id idutente +1 a posizione carattere terminazione</li>
    </ul>
</li>
<li>ZLOG.TXT 
    <ul>
        <li>Data: 7byte</li>
        <li>idimpianto: 4byte</li>
        <li>Codeccezione: 1byte ()</li>
        <li>Keysize: 1byte ()</li>
        <li>key: Da posizione finale id Codeccezione +1 a posizione carattere terminazione</li>
    </ul>
</li>
</ul>
<br>

<strong>
Codici eccezioni : 
</strong><br>
<ul>
       <li>RILEVAZIONE NUOVO UTENTE = 1</li>
       <li>MANCATA RILEVAZIONE UTENTE = 2</li>
       <li>RILEVAZIONE NUOVA RISORSA = 3</li>
       <li>MANCATA RILEVAZIONE RISORSA = 4</li> 
       <li>INIZIO APPLICAZIONE SINGOLARITA = 5</li>
       <li>FINE APPLICAZIONE SINGOLARITA = 6</li>
       <li>ELEZIONE UTENTE TITOLARE = 7</li>
       <li>SERRATURA NON CHIUSA = 8</li>
       <li>RILEVAZIONE RFID NON PRESENTE TABELLA UTENTI = 9</li>
       <li>RILEVAZIONE RFID SENZA PERMESSI NELLA FASCIA ORARIA = 10</li>
       <li>MANCATO FUNZIONAMENTO DI UN RELE = 11</li>
       <li>MANCATA RILEVAZIONE RISORSA PRESENZA OBBLIGATORIA = 12</li>
       <li>RILEVAZIONE RISORSA NON DEVE ESSERE PRESENTE = 13</li>
       <li>TOKEN ANTENNA SCARICA = 14</li>
       <li>RILEVATO UTENTE TITOLARE PRESENTE = 15</li>
       <li>RESTART TERMINALE = 16</li>
       <li>MANCATA RILEVAZIONE RFID NON PRESENTE TABELLA UTENTI = 17</li>
       <li>ALERT TELECAMERA = 18</li>
       <li>ATTIVAZIONE RISORSA STANZA = 19</li>
       <li>DISATTIVAZIONE RISORSA STANZA = 20</li>
       <li>APERTURA PORTA = 21</li>
       <li>RILEVAZIONE RFID NON PRESENTE UTENTI STANZA = 22</li>
       <li>RILEVAZIONE ANOMALA = 23</li>
       <li>TITOLARE PRESENTE = 24</li>
       <li>RILEVATO MOVIMENTO ASSENZA TITOLARE = 25</li>
       <li>CONFIGURAZIONE PORTA ASSENTE = 26</li>
       <li>APERTURA FORZATA PORTA = 27</li>
       <li>MANCANZA MOVIMENTO CON TITOLARE PRESENTE STANZA = 28</li>
       <li>ATTIVAZIONE RISORSE RILEVAMENTO SECONDA ANTENNA STANZA = 29</li>
</ul>

<strong>FUNZIONAMENTO : </strong><br>

L'unità viene programmata tramite l'upload wireless (protocollo zigbee) dei file di configurazione.<br>
Le operazioni svolte sono le seguenti:<br>
<ul>
<li>Ascolto messaggi periferiche come le antenne e i messaggi provenienti dai sensori e dagli attuatori configurati nel file di impianto IMPIANTO.TXT</li>
<li>Operazione di login/logout e tracking : quando una antenna invia un messaggio di lettura, l'unità legge la chiave rilevata e controlla nel file utenti UTENTI.TXT se la chiave è presente; in caso affermativo esegue l'operazione di login/logout e traccia il rilevamento della chiave (file di config. VERBOSIT.TXT); in caso negativo  traccia il rilevamento della chiave (file di config. VERBOSIT.TXT).</li>
<li>Operazione di login : in base all'utente rilevato viene letto il file PERMESSI.TXT e vengono attivate le risorse assegnate agli utenti inviando specifici messaggi agli attuatori configurati nel sistema; </li>
<li>Operazione di logout : in base all'utente rilevato viene letto il file PERMESSI.TXT e vengono disattivate le risorse assegnate agli utenti inviando specifici messaggi agli attuatori configurati nel sistema; </li>
<li>Comandi immediati : è possibile inviare all'unità specifici comandi di attivazione e disattivazione delle risorse configurate nell'impianto, quando un comando immediato è attivo su una risorsa questa viene esclusa dalle procedure di login e logout</li>
<li>Impostazione data : è possibile impostare data ed ora dell'impianto tramite invio di apposito comando tramite il protocollo zigbee</li>
<li>Invio file di log : è possibile richiedere il download del file di log</li>
</ul>