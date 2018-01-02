/*  Mind.rexx17NOV93A, an Amiga Rexx program for artificial intelligence. */
/*  For related AI theory see "Mind" on Amiga Library (Fish) Disk #411.   */
/*  This version associatively prioritizes verbs to find and speak aloud  */
/*  the verb most germane to the noun chosen as subject of a sentence.    */
j = 0; n = 0; p = 0; top = 0; v = 0; z = 0    /*  Initialize the values.  */
/*  Preparation for running Mind.rexx as a single-file distribution.      */
SAY ""  /*  Mind.rexx lives in RAM so as to attain the speed of thought.  */
SAY "Launching Mind.rexx from Volume" PRAGMA('d',"RAM:")
SAY "We are now in Volume" PRAGMA('d')
n = 1; noun.n = "animal"
n = 2; noun.n = "human"
n = 3; noun.n = "robot"
stop = n
DO n = 1 TO stop
  store = value('noun.n') || ".noun"
  OPEN(node.n,store,'w')
  CLOSE(node.n)
  END
OPEN(verb.1,"find.verb",'w')
  WRITELN(verb.1,"human.animal")  /*  Mind.rexx creates some associative  */
  WRITELN(verb.1,"robot.human")   /*  RAM.verb files for use in those     */
  WRITELN(verb.1,"animal.robot")  /*  environments where no other files   */
  WRITELN(verb.1,"human.human")   /*  are distributed with this program.  */
  CLOSE(verb.1)
OPEN(verb.2,"know.verb",'w')
  WRITELN(verb.2,"man.world")     /*  In more controlled channels of      */
  WRITELN(verb.2,"robot.world")   /*  distribution, such as Fish CD-ROMs, */
  WRITELN(verb.2,"human.robot")   /*  groups of RAM.noun & RAM.verb files */
  WRITELN(verb.2,"robot.human")   /*  may be distributed along with the   */
  WRITELN(verb.2,"animal.human")  /*  Mind.rexx program, if necessary.    */
  CLOSE(verb.2)
OPEN(verb.3,"see.verb",'w')
  WRITELN(verb.3,"animal.human")  /*  As the mind algorithm progresses,   */
  WRITELN(verb.3,"human.world")   /*  the mind organism may create its    */
  WRITELN(verb.3,"robot.human")   /*  own linguistic memory files, or the */
  WRITELN(verb.3,"animal.robot")  /*  user may save various mindsets.     */
  CLOSE(verb.3)
SAY ""
SAY "Project Mentifex presents Mind.rexx for artificial intelligence."
DO FOREVER
  SAY "Press <RETURN> to continue, <Q> to QUIT:"; PULL opt
  IF opt = "Q" THEN LEAVE
  CALL Soma()
  SAY ""
  SAY "Done with Soma, switching into Psi mode...."
  CALL Psi()
  SAY ""
  SAY "Now forming sentence with the verb of highest priority...."
  CALL sent()
  END
SAY "Program terminated."
EXIT
/*  This Mind.rexx program is being released into the public domain by    */
/*  Project Mentifex, Post Office Box 31326, Seattle, WA 98103-1326 USA.  */
/*  Anyone may add to this program, but please do not copyright the code. */
/*  Please release your improvements into the public-domain channels.     */
Soma:
  SAY "Loading up all nouns stored as files ending in .noun ...."
  nouncom = 'List >RAM:nounlist' #?.noun QUICK FILES NOHEAD
  ADDRESS COMMAND nouncom
  nounload = Open(bank,nounlist,'r')
  n = 0
  DO WHILE ~EOF(bank)
    n = n + 1
    line = ReadLn(bank)
    PARSE VAR line node "." rest
    noun.n = node || . || n || . || v
    END
  CLOSE(bank)
  nstop = n - 1
  SAY ""
  SAY "Loading up all verbs stored as files ending in .verb ...."
  verbcom = 'List >RAM:verblist' #?.verb QUICK FILES NOHEAD
  ADDRESS COMMAND verbcom
  verbload = Open(zeitwort,verblist,'r')
  z = 0
  DO WHILE ~EOF(zeitwort)
    z = z + 1
    zeile = ReadLn(zeitwort)
    PARSE VAR zeile actus "." cetera
    verb.z = actus || . || z || . || p
    END
  CLOSE(zeitwort)
  zstop = z - 1
  RETURN
/*  This Amiga REXX implementation of the Mentifex AI mind-model is being */
/*  written from the core of the mind outwards, that is, first the basic  */
/*  conceptual apparatus and the linguistic structures are implemented.   */
/*  Whosoever has the resources to do so, please devise a way to add      */
/*    - vision:  videocamera input and a visual memory channel;           */
/*    - audition:  speech-input or general sound into auditory memory;    */
/*    - robotics:  a motorium of arms and legs under volitional control.  */
Psi:
DO z = 1 TO zstop
  SAY z " verb.z = " verb.z
  END
SAY ""
  DO n = 1 TO nstop
    SAY "Noun " n "=" noun.n
    END
SAY ""
SAY "Type in the noun that you choose to be the subject of a sentence:"
PULL vybor
IF vybor = "" THEN vybor = "nothing"
SAY "You choose" vybor "."
SAY ""
SAY "Now matching for" vybor "as a branch of access to verbs."
DO z = 1 TO zstop
  PARSE VAR verb.z action "." loipa
  verbseek = action || . || verb
  SAY ""
  SAY "Calling Verblook...."
  CALL Verblook()
  END
RETURN
/*  Whosoever publishes papers and reports on your work with Mind.rexx,   */
/*  please mail a reprint to the postal address of Project Mentifex.      */
/*  Further distribution and implementation on CD-ROM are appreciated.    */
/*  If anyone at MCC can combine the Cyc project of Douglas Lenat with    */
/*  the Mentifex mind-engine, please try your best.                       */
Verblook:
SAY "Now in Verblook...."
SAY "Verbseek = " verbseek
look = Open(verbfile,verbseek,'r')
DO WHILE ~EOF(verbfile)
  item = ReadLn(verbfile)
  PARSE UPPER VAR item comp "." obj    /*  Parse for comparand & object.  */
    SAY "Vybor and comparand = " vybor "and" comp
    IF comp = vybor THEN CALL Increment()
  END
  CLOSE(verbfile)
RETURN
/*  Whosoever can move Mind.rexx to other REXX platforms, please do so.   */
/*  Most internal Mind.rexx functions need a parallel implementation on   */
/*  massively parallel machines.                                          */
Increment:
SAY "z =" z " and verb.z =" verb.z
incverb = verb.z
PARSE VAR incverb base '.' ordv '.' pri
SAY "incverb = " base " . " ordv " . " pri
p = pri + 1
verb.z = base || . || z || . || p
p = 0
RETURN
/*  This Mind.rexx AI program is more philosophy than technology.         */
/*  Accordingly, please find philosophers to consult with as you program  */
/*  to implement your public-domain, free-for-all-humanity improvements.  */
sent:
SAY ""
bonmot = vybor   /*  French "bon mot" (good word) is the chosen subject.  */
SAY "The" bonmot "will..."
ADDRESS COMMAND say "The" bonmot "will"
/*  predicate  */
DO z = 1 TO zstop
  SAY z verb.z
  END
DO z = 1 TO zstop
  ziel = verb.z
  PARSE VAR ziel averb '.' ord '.' pri
  IF pri > top THEN motjuste = averb
  IF pri > top THEN top = pri
  END
SAY "...(do the action) " motjuste "."
ADDRESS COMMAND say motjuste
motjuste = "blank"
top = 0
RETURN
