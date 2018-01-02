e:\hippix\bin\yacc -dv yaccsrc.y
del yaccsrc.c
del symbols.h
move y.tab.c yaccsrc.c
move y.tab.h symbols.h
lex -8 lexsrc.l
del lexsrc.c
move lex.yy.c lexsrc.c
