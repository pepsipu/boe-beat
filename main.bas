'{$STAMP BS2}
'{$PBASIC 2.5}

TXLCD CON 10
BAUD19200 CON 32

wii DATA "wii channel!"
mario DATA "mario!"

marioMusic DATA "                >> < >> < >   > > > <<><>>>>                ", 0
wiiMusic DATA "                >>>> <><> > << >> >>>> <><> >> >> >>>> <><>                ", 0

idx VAR Byte
tmp VAR Byte
len VAR Byte

selectIndex VAR Byte
selectAddress VAR Word

health VAR Nib


INPUT 0
INPUT 9

leftButton VAR IN0
rightButton VAR IN9

leftButtonStore VAR Byte
rightButtonStore VAR Byte
bothButtonStore VAR Byte

beatmapNoteIndex VAR Word
score VAR Word

'program
selectIndex = 0
GOSUB setupDisplay
GOSUB clearDisplay
GOSUB playIntro
main:
  GOSUB selectBeatmap
  GOSUB playGame
  GOTO main
END

playGame:
  health = 5
  beatmapNoteIndex = 0
   
  GOSUB drawHealth
  
  'get notes for map
  LOOKUP selectIndex, [wiiMusic, marioMusic], selectAddress
  
  'note display loop
  DO
    SEROUT TXLCD, BAUD19200, [128]
    FOR idx = beatmapNoteIndex TO beatmapNoteIndex + 15
      READ selectAddress + idx, tmp
      IF (tmp = 0) THEN
        GOTO gameBreak
      ENDIF
      SEROUT TXLCD, BAUD19200, [tmp]
    NEXT
    'check first note, ie note the user must hit
    READ selectAddress + beatmapNoteIndex, tmp
    rightButtonStore = 0
    leftButtonStore = 0
    'make sure they can't hold at the start
    bothButtonStore.BIT0 = rightButton
    bothButtonStore.BIT1 = leftButton
    FOR idx = 0 TO 130
      IF rightButton = 1 THEN
        rightButtonStore = 1
      ENDIF
      IF leftButton = 1 THEN
        leftButtonStore = 1
      ENDIF
      PAUSE 2
    NEXT
    IF (tmp = ">") THEN
      IF (rightButtonStore = 1 AND bothButtonStore.BIT0 = 0) THEN
        score = score + 1
      ELSE
        health = health - 1
        GOSUB drawHealth
      ENDIF
    ENDIF

    IF (tmp = "<") THEN
     IF (leftButtonStore = 1 AND bothButtonStore.BIT1 = 0) THEN
       score = score + 1
     ELSE
       health = health - 1
       GOSUB drawHealth
     ENDIF
    ENDIF
     
    beatmapNoteIndex = beatmapNoteIndex + 1
  LOOP
  gameBreak:
  GOSUB clearDisplay
RETURN

drawHealth:
  IF health = 0 THEN
    GOSUB clearDisplay
    GOTO main
  ENDIF
  SEROUT TXLCD, BAUD19200, [148]
  FOR idx = 1 TO health
    SEROUT TXLCD, BAUD19200, [0]
  NEXT
  FOR idx = health TO 5
    SEROUT TXLCD, BAUD19200, [" "]
  NEXT
RETURN

setupDisplay:
  HIGH TXLCD
  PAUSE 100
  'set backlight & erase cursor
  SEROUT TXLCD, BAUD19200, [22]
  SEROUT TXLCD, BAUD19200, [17]
  GOSUB createHeartCharacter
  PAUSE 50
RETURN

playIntro:
  'cursor to (0,3)
  SEROUT TXLCD, BAUD19200, [131]
  SEROUT TXLCD, BAUD19200, ["welcome to"]
  'cursor to (1,4)
  SEROUT TXLCD, BAUD19200, [152]

  FOR idx = 0 TO 7
    PAUSE 100
    LOOKUP idx, ["boe beat"], tmp
    SEROUT TXLCD, BAUD19200, [tmp]
  NEXT
  PAUSE 400
  GOSUB clearDisplay
RETURN
 
selectBeatmap:
  DO UNTIL bothButtonStore > 5    
    'draw arrows
    SEROUT TXLCD, BAUD19200, [128]
    SEROUT TXLCD, BAUD19200, ["<"]

    SEROUT TXLCD, BAUD19200, [143]
    SEROUT TXLCD, BAUD19200, [">"]
    'draw song title
    LOOKUP selectIndex, [wii, mario], selectAddress
    LOOKUP selectIndex, [12, 6], len
    'padding
    SEROUT TXLCD, BAUD19200, [129 + ((14 - len)/2)]
    FOR idx = 0 TO len - 1
      READ selectAddress + idx, tmp
      SEROUT TXLCD, BAUD19200, [tmp]
    NEXT
   
    GOSUB calculateButtonStores
   
    IF rightButtonStore > 3 AND selectIndex < 2 THEN
      selectIndex = selectIndex + 1
      rightButtonStore = 0
      GOSUB clearDisplay
    ENDIF
    
    IF leftButtonStore > 3 AND selectIndex > 0 THEN
      selectIndex = selectIndex - 1
      leftButtonStore = 0
      GOSUB clearDisplay
    ENDIF
  LOOP
  GOSUB clearDisplay
  leftButtonStore = 0
  rightButtonStore = 0
RETURN

clearDisplay:
  SEROUT TXLCD, BAUD19200, [12]
RETURN

createHeartCharacter:
  SEROUT TXLCD, BAUD19200, [248]

  SEROUT TXLCD, BAUD19200, [0]
  SEROUT TXLCD, BAUD19200, [0]
  SEROUT TXLCD, BAUD19200, [10]
  SEROUT TXLCD, BAUD19200, [31]
  SEROUT TXLCD, BAUD19200, [31]
  SEROUT TXLCD, BAUD19200, [14]
  SEROUT TXLCD, BAUD19200, [4]
  SEROUT TXLCD, BAUD19200, [0]
RETURN

calculateButtonStores:
  IF leftButton = 1 AND rightButton = 1 THEN
    bothButtonStore = bothButtonStore + 1
  ELSE
    bothButtonStore = 0
    IF leftButton = 0 THEN
      leftButtonStore = 0
    ELSE
      leftButtonStore = leftButtonStore + 1
    ENDIF

    IF rightButton = 0 THEN
      rightButtonStore = 0
    ELSE
      rightButtonStore = rightButtonStore + 1
    ENDIF
  ENDIF
RETURN


