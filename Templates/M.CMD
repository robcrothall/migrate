/*  */
trace n;
TOP:
'CLS';
say ' 旼컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴커';
say ' � M.BAT       ** Rob Crothall and Associates - Primary menu **               �';
Say ' �                                                                            �';
Say ' �  A  Operations menu                    N                                   �';
Say ' �  B                                     O  Switch to OS/2                   �';
Say ' �  C  Communications sub-menu            P                                   �';
Say ' �  D  Communications demonstration       Q                                   �';
Say ' �  E                                     R                                   �';
Say ' �  F                                     S                                   �';
Say ' �  G                                     T                                   �';
Say ' �  H                                     U                                   �';
Say ' �  I                                     V                                   �';
Say ' �  J                                     W  Word Perfect                     �';
Say ' �  K                                     X                                   �';
Say ' �  L                                     Y                                   �';
Say ' �  M  Make another Menu                  Z  Modify this bat file             �';
Say ' �                                                                            �';
Say ' �              Enter a letter from A to Z (or type Esc to quit)              �';
Say ' 읕컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴컴켸';
START:
pull nix;
If nix = '' then signal END;
If nix = 'Z' then signal LABELZ;
If nix = 'Y' then signal LABELY;
If nix = 'X' then signal LABELX;
If nix = 'W' then signal LABELW;
If nix = 'V' then signal LABELV;
If nix = 'U' then signal LABELU;
If nix = 'T' then signal LABELT;
If nix = 'S' then signal LABELS;
If nix = 'R' then signal LABELR;
If nix = 'Q' then signal LABELQ;
If nix = 'P' then signal LABELP;
If nix = 'O' then signal LABELO;
If nix = 'N' then signal LABELN;
If nix = 'M' then signal LABELM;
If nix = 'L' then signal LABELL;
If nix = 'K' then signal LABELK;
If nix = 'J' then signal LABELJ;
If nix = 'I' then signal LABELI;
If nix = 'H' then signal LABELH;
If nix = 'G' then signal LABELG;
If nix = 'F' then signal LABELF;
If nix = 'E' then signal LABELE;
If nix = 'D' then signal LABELD;
If nix = 'C' then signal LABELC;
If nix = 'B' then signal LABELB;
LABELA:
call opsmenu.bat
signal TOP
LABELB:
Say '(this simulates menu choice B)';
pull nix;
signal TOP
LABELC:
call \bat\tebamenu.bat
signal TOP
LABELD:
call csrmenu.bat
signal TOP
LABELE:
Say '(this simulates menu choice E)';
pull nix;
signal TOP
LABELF:
Say '(this simulates menu choice F)';
pull nix;
signal TOP
LABELG:
Say '(this simulates menu choice G)';
pull nix;
signal TOP
LABELH:
Say '(this simulates menu choice H)';
pull nix;
signal TOP
LABELI:
Say '(this simulates menu choice I)';
pull nix;
signal TOP
LABELJ:
Say '(this simulates menu choice J)';
pull nix;
signal TOP
LABELK:
Say '(this simulates menu choice K)';
pull nix;
signal TOP
LABELL:
Say '(this simulates menu choice L)';
pull nix;
signal TOP
LABELM:
call \bat\makemenu.bat
signal TOP
LABELN:
Say '(this simulates menu choice N)';
pull nix;
signal TOP
LABELO:
cd\os2
boot /os2
signal TOP
LABELP:
Say '(this simulates menu choice P)';
pull nix;
signal TOP
LABELQ:
Say '(this simulates menu choice Q)';
pull nix;
signal TOP
LABELR:
Say '(this simulates menu choice R)';
pull nix;
signal TOP
LABELS:
Say '(this simulates menu choice S)';
pull nix;
signal TOP
LABELT:
Say '(this simulates menu choice T)';
pull nix;
signal TOP
LABELU:
Say '(this simulates menu choice U)';
pull nix;
signal TOP
LABELV:
Say '(this simulates menu choice V)';
pull nix;
signal TOP
LABELW:
'cd \wpfiles';
'\WP51\WP';
'cd \';
signal TOP;
LABELX:
Say '(this simulates menu choice X)';
pull nix;
signal TOP
LABELY:
Say '(this simulates menu choice Y)';
pull nix;
signal TOP
LABELZ:
if exist \bat\mz.bat mz.bat
Say 'File \BAT\MZ.BAT does not exist';
pull nix;
signal TOP
END:
CLS
Say ' ';
Say 'Thank you for using this menu, which was created by:-';
Say '  Rob Crothall & Associates';
Say '  P.O. Box 61417';
Say '  2107 Marshalltown';
Say '  South Africa';
Say '  Phone: (011) 706 3791';
