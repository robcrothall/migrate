/* VARPARSE.CMD */
string = '/abc def/'
parse var string delim +1 string (delim) .
say string
