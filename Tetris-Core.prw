#include 'protheus.ch'    	
#include 'tetris-core.ch'

// ============================================================================
// Classe "CORE" do Jogo Tetris
// ============================================================================

CLASS APTETRIS
  
	// Propriedades publicas
	
  DATA aGamePieces     // Pe�as que compoe o jogo 
  DATA nGameStart      // Momento de inicio de jogo 
  DATA nGameTimer      // Tempo de jogo em segundos
  DATA nGamePause      // Controle de tempo de pausa
  DATA nNextPiece      // Proxima pe�a a ser usada
  DATA nGameStatus     // 0 = Running  1 = PAuse 2 == Game Over
  DATA aNextPiece      // Array com a defini��o e posi��o da proxima pe�a
  DATA aGameCurr       // Array com a defini��o e posi��o da pe�a em jogo
  DATA nGameScore      // pontua��o da partida
  DATA aGameGrid       // Array de strings com os blocos da interface representados em memoria

	// Eventos disparados pelo core do Jogo 
	
  DATA bShowScore      // CodeBlock para interface de score 
	DATA bShowElap       // CodeBlock para interface de tempo de jogo 
  DATA bChangeState    // CodeBlock para indicar mudan�a de estado ( pausa / continua /game over )
	DATA bPaintGrid      // CodeBlock para evento de pintura do Grid do Jogo
	DATA bPaintNext      // CodeBlock para evento de pintura da Proxima pe�a em jogo
  
  // Metodos Publicos
  
  METHOD New()          // Construtor
  METHOD Start()        // Inicio de Jogo
  METHOD DoAction(cAct) // Disparo de a��es da Interface
  METHOD DoPause()      // Dispara Pause On/Off

  // Metodos privados ( por conven��o, prefixados com "_" ) 

	METHOD _LoadPieces()   // Carga do array de pe�as do Jogo 
  METHOD _MoveDown()     // Movimenta a pe�a corrente uma posi��o para baixo
  METHOD _DropDown()     // Movimenta a pe�a corrente direto at� onde for poss�vel
  METHOD _SetPiece(aPiece,aGrid)  // Seta uma pe�a no Grid em memoria do jogo 
  METHOD _DelPiece(aPiece,aGrid)  // Remove uma pe�a no Grid em memoria do jogo 
  METHOD _FreeLines()    // Verifica e eliminha linhas totalmente preenchidas 
  METHOD _GetEmptyGrid() // Retorna um Grid em memoria inicializado vazio 

ENDCLASS

/* ----------------------------------------------------------
Construtor da classe
---------------------------------------------------------- */

METHOD NEW() CLASS APTETRIS

::aGamePieces := ::_LoadPieces()
::nGameTimer  := 0
::nGameStart  := 0
::aNextPiece  := {}
::aGameCurr   := {}
::nGameScore  := 0
::aGameGrid   := {}
::nGameStatus := GAME_RUNNING

Return self

/* ----------------------------------------------------------
Inicializa o Grid na memoria
Em memoria, o Grid possui 14 colunas e 22 linhas
Na tela, s�o mostradas apenas 20 linhas e 10 colunas
As 2 colunas da esquerda e direita, e as duas linhas a mais
sao usadas apenas na memoria, para auxiliar no processo
de valida��o de movimenta��o das pe�as.
---------------------------------------------------------- */

METHOD Start() CLASS APTETRIS
Local aDraw, nPiece, cScore

// Inicializa o grid de imagens do jogo na mem�ria
// Sorteia a pe�a em jogo
// Define a pe�a em queda e a sua posi��o inicial
// [ Peca, rotacao, linha, coluna ]
// e Desenha a pe�a em jogo no Grid
// e Atualiza a interface com o Grid

// Inicializa o grid do jogo "vazio"
::aGameGrid := aClone(::_GetEmptyGrid())

// Sorteia pe�a em queda do inicio do jogo
nPiece := randomize(1,len(::aGamePieces)+1)

// E coloca ela no topo da tela
::aGameCurr := {nPiece,1,1,6}
::_SetPiece(::aGameCurr,::aGameGrid)

// Dispara a pintura do Grid do Jogo
Eval( ::bPaintGrid , ::aGameGrid)

// Sorteia a proxima pe�a e desenha
// ela no grid reservado para ela
::aNextPiece := array(4,"00000")
::nNextPiece := randomize(1,len(::aGamePieces)+1)

aDraw := {::nNextPiece,1,1,1}
::_SetPiece(aDraw,::aNextPiece)

// Dispara a pintura da pr�xima pe�a
Eval( ::bPaintNext , ::aNextPiece )

// Marca timer do inicio de jogo
::nGameStart := seconds()

// Chama o codeblock de mudan�a de estado - Jogo em execu��o
Eval(::bChangeState , ::nGameStatus )

// E chama a pintura do score inicial 
cScore := str(::nGameScore,7)
Eval( ::bShowScore , cScore )

Return

/* ----------------------------------------------------------
Recebe uma a��o de movimento de pe�a, e realiza o movimento
da pe�a corrente caso exista espa�o para tal.
---------------------------------------------------------- */
METHOD DoAction(cAct)  CLASS APTETRIS
Local aOldPiece
Local cScore, cElapTime 
Local cOldScore, cOldElapTime 

If ::nGameStatus != GAME_RUNNING
	// Jogo n�o est� rodando, nao aceita a��o nenhuma
	Return .F. 
Endif

// Pega pontua��o e tempo decorridos agora 
cOldScore := str(::nGameScore,7)
cOldElapTime := STOHMS(::nGameTimer)

// Clona a pe�a em queda
aOldPiece := aClone(::aGameCurr)

if cAct $ 'AJ'
	
	// Movimento para a Esquerda (uma coluna a menos)
	// Remove a pe�a do grid
	::_DelPiece(::aGameCurr,::aGameGrid)
	::aGameCurr[PIECE_COL]--
	If !::_SetPiece(::aGameCurr,::aGameGrid)
		// Se nao foi feliz, pinta a pe�a de volta
		::aGameCurr :=  aClone(aOldPiece)
		::_SetPiece(::aGameCurr,::aGameGrid)
	Endif
	
Elseif cAct $ 'DL'
	
	// Movimento para a Direita ( uma coluna a mais )
	// Remove a pe�a do grid
	::_DelPiece(::aGameCurr,::aGameGrid)
	::aGameCurr[PIECE_COL]++
	If !::_SetPiece(::aGameCurr,::aGameGrid)
		// Se nao foi feliz, pinta a pe�a de volta
		::aGameCurr :=  aClone(aOldPiece)
		::_SetPiece(::aGameCurr,::aGameGrid)
	Endif
	
Elseif cAct $ 'WI'
	
	// Movimento para cima  ( Rotaciona sentido horario )
	
	// Remove a pe�a do Grid
	::_DelPiece(::aGameCurr,::aGameGrid)
	
	// Rotaciona a pe�a 
	::aGameCurr[PIECE_ROTATION]--
	If ::aGameCurr[PIECE_ROTATION] < 1
		::aGameCurr[PIECE_ROTATION] := len(::aGamePieces[::aGameCurr[PIECE_NUMBER]])-1
	Endif
	
	If !::_SetPiece(::aGameCurr,::aGameGrid)
		// Se nao consegue colocar a pe�a no Grid
		// Nao � possivel rotacionar. Pinta a pe�a de volta
		::aGameCurr :=  aClone(aOldPiece)
		::_SetPiece(::aGameCurr,::aGameGrid)
	Endif
	
ElseIF cAct $ 'SK#'
	
	// Desce a pe�a para baixo uma linha intencionalmente
	::_MoveDown()
	
	If 	cAct $ 'SK'
		// se o movimento foi intencional, ganha + 1 ponto
		::nGameScore++
	Endif
	
ElseIF cAct == ' '
	
	// Dropa a pe�a - empurra para baixo at� a �ltima linha
	// antes de bater a pe�a no fundo do Grid. Isto vai permitir
	// movimentos laterais e rora��o, caso exista espa�o 

	If !::_DropDown()
		// Se nao tiver espa�o para o DropDown, faz apenas o MoveDown 
		// e "assenta" a pe�a corrente
		::_MoveDown()
	Endif
	
Else

	UserException("APTETRIS:DOACTION() ERROR: Unknow Action ["+cAct+"]")
	
Endif

// Dispara a repintura do Grid
Eval( ::bPaintGrid , ::aGameGrid)

// Calcula tempo decorrido
::nGameTimer := seconds() - ::nGameStart
	
If ::nGameTimer < 0
	// Ficou negativo, passou da meia noite
	::nGameTimer += 86400
Endif

// Pega Score atualizado e novo tempo decorrido
cScore := str(::nGameScore,7)
cElapTime := STOHMS(::nGameTimer)

If ( cOldScore <> cScore ) 
	// Dispara o codeblock que atualiza o score
	Eval( ::bShowScore , cScore )
Endif

If ( cOldElapTime <> cElapTime ) 
	// Dispara atualiza�ao de tempo decorrido
	Eval( ::bShowElap , cElapTime )
Endif

Return .T.


/* ----------------------------------------------------------
Coloca e retira o jog em pausa
Este metodo foi criado isolado, pois � o unico 
que poderia ser chamado dentro de uma pausa
---------------------------------------------------------- */
METHOD DoPause() CLASS APTETRIS
Local lChanged := .F.
Local nPaused
Local cElapTime 
Local cOldElapTime 

cOldElapTime := STOHMS(::nGameTimer)

If ::nGameStatus == GAME_RUNNING
	// Jogo em execu��o = Pausa : Desativa o timer
	lChanged      := .T.
	::nGameStatus := GAME_PAUSED
	::nGamePause  := seconds()
ElseIf ::nGameStatus == GAME_PAUSED
	// Jogo em pausa = Sai da pausa : Ativa o timer
	lChanged      := .T.
	::nGameStatus := GAME_RUNNING
	// Calcula quanto tempo o jogo ficou em pausa
	// e acrescenta esse tempo do start do jogo
	nPaused := seconds()-::nGamePause
	If nPaused < 0
		nPaused += 86400
	Endif
	::nGameStart += nPaused
Endif

If lChanged
	
	// Chama o codeblock de mudan�a de estado - Entrou ou saiu de pausa
	Eval(::bChangeState , ::nGameStatus )
	
	If ::nGameStatus == GAME_PAUSED
		// Em pausa, Dispara a pintura do Grid do Jogo vazio
		Eval( ::bPaintGrid , ::_GetEmptyGrid() )
	Else
		// Game voltou da pausa, pinta novamente o Grid
		Eval( ::bPaintGrid , ::aGameGrid)
	Endif
	
	// Calcula tempo de jogo sempre ao entrar ou sair de pausa
	::nGameTimer := seconds() - ::nGameStart
	
	If ::nGameTimer < 0
		// Ficou negativo, passou da meia noite
		::nGameTimer += 86400
	Endif	

	// Pega novo tempo decorrido
	cElapTime := STOHMS(::nGameTimer)

	If ( cOldElapTime <> cElapTime ) 
		// Dispara atualiza�ao de tempo decorrido
		Eval( ::bShowElap , cElapTime )
	Endif

Endif


Return

/* ----------------------------------------------------------
Metodo SetGridPiece
Aplica a pe�a informada no array do Grid.
Retorna .T. se foi possivel aplicar a pe�a na posicao atual
Caso a pe�a n�o possa ser aplicada devido a haver
sobreposi��o, a fun��o retorna .F. e o grid n�o � atualizado
Serve tanto para o Grid do Jogo quando para o Grid da pr�xima pe�a
---------------------------------------------------------- */

METHOD _SetPiece(aPiece,aGrid)  CLASS APTETRIS
Local nPiece   := aPiece[PIECE_NUMBER] // Numero da pe�a
Local nRotate  := aPiece[PIECE_ROTATION] // Rota��o
Local nRow     := aPiece[PIECE_ROW] // Linha no Grid
Local nCol     := aPiece[PIECE_COL] // Coluna no Grid
Local nL , nC
Local aTecos := {}
Local cTecoGrid, cPeca , cPieceId

conout("_SetPiece on COL "+cValToChar(nCol))

cPieceId := str(nPiece,1)

For nL := nRow to nRow+3
	cPeca := ::aGamePieces[nPiece][1+nRotate][nL-nRow+1]
	If nL > len(aGrid) 
		  // Se o grid acabou, verifica se o teco 
		  // da pe�a tinha alguma coisa a ser ligada
		  // Se tinha, nao cabe, se n�o tinha, beleza
			If  '1' $ cPeca 
				Return .F.
			Else
				EXIT
			Endif
	Endif
	cTecoGrid := substr(aGrid[nL],nCol,4)
	For nC := 1 to 4
		If Substr(cPeca,nC,1) == '1'
			If SubStr(cTecoGrid,nC,1) != '0'
				// Vai haver sobreposi��o,
				// a pe�a nao cabe ...
				Return .F.
			Endif
			cTecoGrid := Stuff(cTecoGrid,nC,1,cPieceId)
		Endif
	Next
	// Array temporario com a pe�a j� colocada
	aadd(aTecos,cTecoGrid)
Next

// Aplica o array temporario no array do grid
For nL := nRow to nRow+len(aTecos)-1
	aGrid[nL] := stuff(aGrid[nL],nCol,4,aTecos[nL-nRow+1])
Next

// A pe�a "coube", retorna .T.
Return .T.

/* -----------------------------------------------------------------
Carga do array de pe�as do jogo
Array multi-dimensional, contendo para cada
linha a string que identifica a pe�a, e um ou mais
arrays de 4 strings, onde cada 4 elementos
representam uma matriz binaria de caracteres 4x4
para desenhar cada pe�a

Exemplo - Pe�a "O"

aLPieces[1][1] C "O"
aLPieces[1][2][1] "0000"
aLPieces[1][2][2] "0110"
aLPieces[1][2][3] "0110"
aLPieces[1][2][4] "0000"

----------------------------------------------------------------- */

METHOD _LoadPieces() CLASS APTETRIS
Local aLPieces := {}

// Pe�a "O" , uma posi��o
aadd(aLPieces,{'O',	{	'0000','0110','0110','0000'}})

// Pe�a "I" , em p� e deitada
aadd(aLPieces,{'I',	{	'0000','1111','0000','0000'},;
                    {	'0010','0010','0010','0010'}})

// Pe�a "S", em p� e deitada
aadd(aLPieces,{'S',	{	'0000','0011','0110','0000'},;
                    {	'0010','0011','0001','0000'}})

// Pe�a "Z", em p� e deitada
aadd(aLPieces,{'Z',	{	'0000','0110','0011','0000'},;
                    {	'0001','0011','0010','0000'}})

// Pe�a "L" , nas 4 posi��es possiveis
aadd(aLPieces,{'L',	{	'0000','0111','0100','0000'},;
                    {	'0010','0010','0011','0000'},;
                    {	'0001','0111','0000','0000'},;
                    {	'0110','0010','0010','0000'}})

// Pe�a "J" , nas 4 posi��es possiveis
aadd(aLPieces,{'J',	{	'0000','0111','0001','0000'},;
                    {	'0011','0010','0010','0000'},;
                    {	'0100','0111','0000','0000'},;
                    {	'0010','0010','0110','0000'}})

// Pe�a "T" , nas 4 posi��es possiveis
aadd(aLPieces,{'T',	{	'0000','0111','0010','0000'},;
                    {	'0010','0011','0010','0000'},;
                    {	'0010','0111','0000','0000'},;
                    {	'0010','0110','0010','0000'}})

Return aLPieces


/* ----------------------------------------------------------
Fun��o _MoveDown()

Movimenta a pe�a em jogo uma posi��o para baixo.
Caso a pe�a tenha batido em algum obst�culo no movimento
para baixo, a mesma � fica e incorporada ao grid, e uma nova
pe�a � colocada em jogo. Caso n�o seja possivel colocar uma
nova pe�a, a pilha de pe�as bateu na tampa -- Game Over

---------------------------------------------------------- */

METHOD _MoveDown() CLASS APTETRIS
Local aOldPiece
Local nMoved := 0

If ::nGameStatus != GAME_RUNNING
	Return
Endif

// Clona a pe�a em queda na posi��o atual
aOldPiece := aClone(::aGameCurr)

// Primeiro remove a pe�a do Grid atual
::_DelPiece(::aGameCurr,::aGameGrid)

// Agora move a pe�a apenas uma linha pra baixo
::aGameCurr[PIECE_ROW]++

// Recoloca a pe�a no Grid
If ::_SetPiece(::aGameCurr,::aGameGrid)
	
	// Nao bateu em nada, beleza. 
	// Retorna aqui mesmo 
	Return
	
Endif

// Opa ... Esbarrou em alguma pe�a ou fundo do grid
// Volta a pe�a pro lugar anterior e recoloca a pe�a no Grid
::aGameCurr :=  aClone(aOldPiece)
::_SetPiece(::aGameCurr,::aGameGrid)

// Encaixou uma pe�a .. Incrementa o score em 4 pontos
// Nao importa a pe�a ou como ela foi encaixada
::nGameScore += 4

// Verifica apos a pea encaixada, se uma ou mais linhas
// foram preenchidas e podem ser eliminadas
::_FreeLines()

// Pega a proxima pe�a e coloca em jogo
nPiece := ::nNextPiece
::aGameCurr := {nPiece,1,1,6} // Peca, direcao, linha, coluna

If !::_SetPiece(::aGameCurr,::aGameGrid)
	
	// Acabou, a pe�a nova nao entra (cabe) no Grid
	// "** GAME OVER** "
	::nGameStatus := GAME_OVER
	
	// Chama o codeblock de mudan�a de estado - Game Over
	Eval(::bChangeState , ::nGameStatus )
	
	// E retorna aqui mesmo
	Return
	
Endif

// Inicializa proxima pe�a em branco
::aNextPiece := array(4,"00000")

// Sorteia a proxima pe�a que vai cair
::nNextPiece := randomize(1,len(::aGamePieces)+1)
::_SetPiece( {::nNextPiece,1,1,1} , ::aNextPiece)

// Dispara a pintura da pr�xima pe�a
Eval( ::bPaintNext , ::aNextPiece )

// e retorna para o processamento de a��es 

Return


METHOD _DropDown() CLASS APTETRIS
Local aOldPiece
Local nMoved := 0

If ::nGameStatus != GAME_RUNNING
	Return .F.
Endif

// Clona a pe�a em queda na posi��o atual
aOldPiece := aClone(::aGameCurr)

// Dropa a pe�a at� bater embaixo
// O Drop incrementa o score em 1 ponto
// para cada linha percorrida. Quando maior a quantidade
// de linhas vazias, maior o score acumulado com o Drop

// Remove a pe�a do Grid atual
::_DelPiece(::aGameCurr,::aGameGrid)

// Desce uma linha pra baixo
::aGameCurr[PIECE_ROW]++

While ::_SetPiece(::aGameCurr,::aGameGrid)
	
	// Pe�a desceu mais uma linha
	// Incrementa o numero de movimentos dentro do Drop
	nMoved++

	// Incrementa o Score
	::nGameScore++

	// Remove a pe�a da interface
	::_DelPiece(::aGameCurr,::aGameGrid)
	
	// Guarda a pe�a na posi��o atual
	aOldPiece := aClone(::aGameCurr)
	
	// Desce a pe�a mais uma linha pra baixo
	::aGameCurr[PIECE_ROW]++
	
Enddo

// Volta a pe�a na �ltima posi��o v�lida, 
::aGameCurr := aClone(aOldPiece)
::_SetPiece(::aGameCurr,::aGameGrid)
	
// Se conseguiu mover a pe�a com o Drop
// pelo menos uma linha, retorna .t. 
Return (nMoved > 0)


/* -----------------------------------------------------------------------
Remove a pe�a informada do grid informado
----------------------------------------------------------------------- */
METHOD _DelPiece(aPiece,aGrid) CLASS APTETRIS

Local nPiece := aPiece[PIECE_NUMBER]
Local nRotate   := aPiece[PIECE_ROTATION]
Local nRow   := aPiece[PIECE_ROW]
Local nCol   := aPiece[PIECE_COL]
Local nL, nC
Local cTecoGrid, cTecoPeca

// Como a matriz da pe�a � 4x4, trabalha em linhas e colunas
// Separa do grid atual apenas a �rea que a pe�a est� ocupando
// e desliga os pontos preenchidos da pe�a no Grid.
// Esta fun��o n�o verifica se a pe�a que est� sendo removida
// � a correta, apenas apaga do grid os pontos ligados que
// a pe�a informada ocupa nas coordenadas especificadas

For nL := nRow to nRow+3
	cTecoPeca := ::aGamePieces[nPiece][1+nRotate][nL-nRow+1]
	If nL > len(aGrid)
	  // O Grid acabou, retorna
		Return
	Endif
	cTecoGrid := substr(aGrid[nL],nCol,4)
	For nC := 1 to 4
		If Substr(cTecoPeca,nC,1)=='1'
			cTecoGrid := Stuff(cTecoGrid,nC,1,'0')
		Endif
	Next
	aGrid[nL] := stuff(aGrid[nL],nCol,4,cTecoGrid)
Next

Return

/* -----------------------------------------------------------------------
Verifica e elimina as linhas "completas"
ap�s uma pe�a ser encaixada no Grid
----------------------------------------------------------------------- */
METHOD _FreeLines() CLASS APTETRIS
Local nErased := 0
Local cTecoGrid

For nL := 21 to 2 step -1
	
	// Sempre varre de baixo para cima
	cTecoGrid := substr(::aGameGrid[nL],3)
	
	If !('0'$cTecoGrid)
		// Se a linha nao tem nenhum espa�o em branco
		// Elimina esta linha e acrescenta uma nova linha
		// em branco no topo do Grid
		adel(::aGameGrid,nL)
		ains(::aGameGrid,1)
		::aGameGrid[1] := GRID_EMPTY_LINE
		nL++
		nErased++
	Endif
	
Next

// Pontua��o por linhas eliminadas
// Quanto mais linhas ao mesmo tempo, mais pontos
If nErased == 4
	::nGameScore += 100
ElseIf nErased == 3
	::nGameScore += 50
ElseIf nErased == 2
	::nGameScore += 25
ElseIf nErased == 1
	::nGameScore += 10
Endif

Return


/* ------------------------------------------------------
Retorna um grid de jogo vazio / inicializado
O Grid no core do tetris contem 21 linhas por 14 colunas
As limita��es nas laterais esquerda e direita para 
facilitar os algoritmos para fazer a manuten��o no Grid 
A �rea visivel nas colunas do Grid est� indicada usando 
"." Logo, mesmo que o grid em memoria 
tenha 21x14, o grid de bitmaps de interface tem apenas 20x10, 
a partir da coordenada 2,3 ( linha,coluna ) do Grid do Jogo 

"11000000000011" -- Primeira linha, n�o visivel 
"11..........11" -- demais 20 linhas, visiveis da coluna 2 a 11 

------------------------------------------------------ */
METHOD _GetEmptyGrid() CLASS APTETRIS
Local aEmptyGrid 
aEmptyGrid := array(21,GRID_EMPTY_LINE)
Return aEmptyGrid


/* ------------------------------------------------------
Fun��o auxiliar de convers�o de segundos para HH:MM:SS
------------------------------------------------------ */

STATIC Function STOHMS(nSecs)
Local nHor
Local nMin

nHor := int(nSecs/3600)
nSecs -= (3600*nHor)

nMin := int(nSecs/60)
nSecs -= (60*nMin)

Return strzero(nHor,2)+':'+Strzero(nMin,2)+':'+strzero(nSecs,2)

