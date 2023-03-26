# todo
# url: https://lichess.org/analysis/pgn/1.%20c3%20e5%202.%20f3%20Nc6%203.%20Qc2%20Nf6%204.%20Qd3%20d5%205.%20Qe3%20Bd6%206.%20Qf2%20e4%207.%20Kd1%20O-O%208.%20Qe1%20Re8%209.%20fxe4%20dxe4%2010.%20d3%20exd3%2011.%20exd3%20Rxe1+%2012.%20Kxe1%20Ng4%2013.%20Nf3%20Bf5%2014.%20h3%20Bg3+%2015.%20Kd2%20Nf2%2016.%20Rg1%20Bxd3%2017.%20Bxd3%20Qxd3+%2018.%20Ke1%20Qd1#36

import {log,r4r,table,tr,td,input,form,div,br,span,button} from '../js/utils.js'

query = {}

configure = =>
	queryString = window.location.search
	urlParams = new URLSearchParams queryString
	query.fen = urlParams.get "fen"
	if !query.fen then query.fen = "rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1"
	# query.fen = "8/8/8/4k3/3R4/2K5/8/8 w - - 0 1"
	query

console.log configure()

BOKSTAVERA = true
STRENGTH = 10
READBOTH=true

stockfish = null
speaker = null
voices = null
queue = []
speaking = 0
game = null

window.speechSynthesis.onvoiceschanged = -> voices = window.speechSynthesis.getVoices()

initSpeaker = ->
	index = 5
	speaker = new SpeechSynthesisUtterance()
	speaker.onend = (event) => 
		speaking--
		if queue.length > 0 then say()
	speaker.voiceURI = "native"
	speaker.volume = 1
	speaker.rate = 1.0
	speaker.pitch = 0
	speaker.text = '' 
	speaker.lang = 'sv'
	if voices and index <= voices.length-1 then speaker.voice = voices[index]

say = (m="") ->
	if speaker == null then return
	if m != "" then queue.push m
	if speaking == 0
		speaking++
		speaker.text = queue.shift()
		speechSynthesis.speak speaker

initSpeaker()

init = =>
	stockfish = new Worker 'stockfish.js'
	board = null
	game = new Chess query.fen
	# log game
	# stockfish.postMessage "position fen " + query.fen

	# do not pick up pieces if the game is over
	# only pick up pieces for White
	onDragStart = (source, piece, position, orientation) =>
		if game.in_checkmate() || game.in_draw() || piece.search(/^b/) != -1
			return false

	makeMove = =>
		possibleMoves = game.moves()

		# game over
		if possibleMoves.length == 0 then return

		FEN = game.fen()

		stockfish.postMessage "position fen " + FEN
		#stockfish.postMessage 'go depth ' + STRENGTH
		stockfish.postMessage 'go movetime 1000' # ms

		stockfish.onmessage = (event) =>
			console.log event.data
			document.getElementById("bestmove").innerHTML = event.data
			str = event.data
			message = str.split " "
			if message.includes "score"
				if message[8]=='cp' then score = -message[9]/100
				if message[8]=='mate' then score = '#'+message[9]
				document.getElementById("score").innerHTML = score
			
			# res = str.split " "
			if message[0] == "bestmove"
				zug = message[1].split ""
				botmovesource = zug[0]+zug[1]
				botmovetarget = zug[2]+zug[3]
				# document.getElementById("botmove").innerHTML = botmovesource;
				source = botmovesource
				target = botmovetarget
				move = game.move {from: source, to: target,promotion: 'q'}

				say lastMove()
				
				board.position game.fen()
				document.getElementById("PGN").innerHTML = game.pgn()
				updateStatus()
				#sound()

	patch = (move, obj) ->
		for key, value of obj
			move = move.replace key, value
		move

	lastMove = =>
		moves = game.history()
		if moves.length == 0 then return ''
		move = moves[moves.length-1]
		oldmove = move

		move = patch move, {a: "!",b: "@",c: "_",d: "$",e: "%",f: "^",g: "&",h: "*"}
		move = patch move, {"!":"adam ","@":"bertil ","_":"seehsar ","$":"david ","%":"erik ","^":"filip ","&":"gustav ","*":"helge "}
		move = patch move, {x: " slår ",N: "springare ",B: "löpare ",R: "torn ",Q: "dam ",K: "kung ","+": ", schack","#": ", schack matt",'O-O-O': 'kung lång','O-O': 'kung kort'}

		# move = move.replaceAll "a", "!"
		# move = move.replaceAll "b", "@"
		# move = move.replaceAll "c", "_"
		# move = move.replaceAll "d", "$"
		# move = move.replaceAll "e", "%"
		# move = move.replaceAll "f", "^"
		# move = move.replaceAll "g", "&"
		# move = move.replaceAll "h", "*"

		# move = move.replaceAll "!","adam "
		# move = move.replaceAll "@","bertil "
		# move = move.replaceAll "_","seehsar "
		# move = move.replaceAll "$","david "
		# move = move.replaceAll "%","erik "
		# move = move.replaceAll "^","filip "
		# move = move.replaceAll "&","gustav "
		# move = move.replaceAll "*","helge "

		# move = move.replace "x", " slår "
		# move = move.replace "N", "springare "
		# move = move.replace "B", "löpare "
		# move = move.replace "R", "torn "
		# move = move.replace "Q", "dam "
		# move = move.replace "K", "kung "
		# move = move.replace "+", ", schack"
		# move = move.replace "#", ", schack matt"
		# move = move.replace 'O-O-O', 'kung lång'
		# move = move.replace 'O-O', 'kung kort'
		console.log oldmove,'->',move
		move

	onDrop = (source, target) =>
		move = game.move { from:source, to:target, promotion:'q' }
		if move == null then return 'snapback'
		if READBOTH then say lastMove()
		window.setTimeout makeMove, 150

	# update the board position after the piece snap
	# for castling, en passant, pawn promotion
	onSnapEnd = =>
		board.position game.fen()
		document.getElementById("PGN").innerHTML = game.pgn()
		updateStatus()
		#sound()

	updateStatus = =>
		status = ''
		moveColor = if game.turn() == 'b' then 'Black' else 'White'
		if game.in_checkmate() then status = 'Game over, ' + moveColor + ' is in checkmate.'
		else if game.in_draw() then status = 'Game over, drawn position'
		else 
			status = moveColor + ' to move'
			if game.in_check() then status += ', ' + moveColor + ' is in check'
		document.getElementById("status").innerHTML = status

	cfg = {draggable:true, position:query.fen, onDragStart,onDrop,onSnapEnd}
	console.log game.fen()
	board = ChessBoard 'board', cfg

# sound = =>
# 	document.getElementById('sound').innerHTML = '<audio autoplay preload controls> <source src="sound/move.wav" type="audio/wav" /> </audio>'

f = (a,b="") =>
	if b=="" then b = a.toUpperCase()
	tr {},
		td {},b+":"
		td {id:a}

newGame = => init()

analyze = =>
	window.location.href = "https://lichess.org/analysis/pgn/" + game.pgn().replaceAll " ","%20"

r4r =>
	table {},
		tr {},
			td {},
				div {id:"board", style:"width:500px"}
				button {onclick:newGame}, "New Game"
				button {onclick:analyze}, "Analyze"
		tr {},
			f "PGN"
			f "status"
			f "bestmove"
			f "score"

init()
#$(document).ready init
