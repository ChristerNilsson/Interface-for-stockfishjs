# todo
# url: https://lichess.org/analysis/pgn/1.%20c3%20e5%202.%20f3%20Nc6%203.%20Qc2%20Nf6%204.%20Qd3%20d5%205.%20Qe3%20Bd6%206.%20Qf2%20e4%207.%20Kd1%20O-O%208.%20Qe1%20Re8%209.%20fxe4%20dxe4%2010.%20d3%20exd3%2011.%20exd3%20Rxe1+%2012.%20Kxe1%20Ng4%2013.%20Nf3%20Bf5%2014.%20h3%20Bg3+%2015.%20Kd2%20Nf2%2016.%20Rg1%20Bxd3%2017.%20Bxd3%20Qxd3+%2018.%20Ke1%20Qd1#36

import {r4r,table,tr,td,input,form,div,br,span} from '../js/utils.js'

BOKSTAVERA = true
STRENGTH = 10

READBOTH=true

speaker = null
voices = null
queue = []
speaking = 0

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
stockfish = new Worker 'stockfish.js'

init = =>
	board = null
	game = new Chess()

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

		document.getElementById('fen').value = FEN

		stockfish.postMessage "position fen"+" "+FEN
		stockfish.postMessage 'go depth ' + STRENGTH

		stockfish.onmessage = (event) =>
			#console.log event.data
			document.getElementById("bestmove").innerHTML = event.data
			str = event.data
			res = str.match /score/g
				
			if res == "score"
				meldung = str.split " "
				document.getElementById("sc").innerHTML = meldung[9]
			
			res = str.split " "
			
			if res[0] == "bestmove"
				zug = res[1].split ""
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

	lastMove = =>
		moves = game.history()
		if moves.length == 0 then return ''
		move = moves[moves.length-1]
		oldmove = move

		move = move.replaceAll "a", "!" # annars byts f ut mot filip
		move = move.replaceAll "b", "@"
		move = move.replaceAll "c", "_"
		move = move.replaceAll "d", "$"
		move = move.replaceAll "e", "%"
		move = move.replaceAll "f", "^"
		move = move.replaceAll "g", "&"
		move = move.replaceAll "h", "*"

		move = move.replace "x","X"
		move = move.replaceAll "!","alfa "
		move = move.replaceAll "@","bravo "
		move = move.replaceAll "_","charlie "
		move = move.replaceAll "$","dällta "
		move = move.replaceAll "%","eko "
		move = move.replaceAll "^","filip "
		move = move.replaceAll "&","golf "
		move = move.replaceAll "*","hotel "

		move = move.replace "X", " slår "
		move = move.replace "N", "springare "
		move = move.replace "B", "löpare "
		move = move.replace "R", "torn "
		move = move.replace "Q", "dam "
		move = move.replace "K", "kung "

		move = move.replace "+", ", schack"
		move = move.replace "#", ", schack matt"
		move = move.replace 'O-O-O', 'kung lång'
		move = move.replace 'O-O', 'kung kort'
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

	cfg = {draggable:true, position:'start', onDragStart,onDrop,onSnapEnd}
	board = ChessBoard 'board', cfg

# sound = =>
# 	document.getElementById('sound').innerHTML = '<audio autoplay preload controls> <source src="sound/move.wav" type="audio/wav" /> </audio>'

f = (a,b="") =>
	if b=="" then b = a.toUpperCase()
	tr {},
		td {},b+":"
		td {id:a}

r4r =>
	table {},
		tr {},
			td {},
				div {id:"board",style:"width: 400px"}
				input {size:"50", id:"fen", style:"color: #de5410;font-size: 12px; ", type:"text"},
					form {action:""},
						input {type:"submit", value:"New Game"}
		tr {},
			# td {valign:top},
#			table {},
			f "PGN"
			f "status"
			f "bestmove"
			f "sc","SCORE"

$(document).ready init
