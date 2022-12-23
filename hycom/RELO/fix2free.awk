#
# --- nawk script to convert fixed to free Fortran source form
# --- only the minimum necessary changes are made
#
# --- nawk -f fix2free file.f > file.f90
# ---  -v f77=1    indicates that ! is not used as a comment symbol.
# ---  -v sym="&"  indicates that & is used in column 6 when a lexical
# ---               token or a character context is split across lines.
# ---               any symbol can be used, & is just an example.
# ---               no embedded ! comments are allowed in such statements.
# ---               the default is " ", i.e. no such symbol.
#
# --- pathalogical cases may fail, but will be detectable from compiler
# --- error messages and can always be fixed using the sym option.
# --- an alternative, that may make more changes to the source, is
# --- f2f90, see  http"//www.fortran.com/fortran/f2f90.tar.gz
#
# --- Alan J. Wallcraft,  NRL,  August 1998.
#
# --- January 2014: added support for cpp macros (lines starting with #)
# ---               and for cdiag debugging lines (no trailing !)
# ---               and for !&OMP lines (no trailing !)
#

BEGIN	{
	n = length(sym)
	if (n==0) sym6 = "^      "; else sym6 = "^     " sym
	}

/^.diag     [&.]/ {
#		A debugging continuation line, no ! search necessary.
		print last " &"
		last = "!diag      " substr($0,12)
		next
	}

/^.diag[ !]/ {
#		A debugging non-continuation line
		print last
		last = "!" substr($0,2)
		next
	}

/^.diag/ {
#		A debugging continuation line, no ! search necessary.
		print last " &"
		last = "!diag " substr($0,7)
		next
	}

/^!\$OMP / {
#		An OpenMP non-continuation line
		print last
		last = $0
		next
	}

/^!\$OMP/ {
#		An OpenMP continuation line, no ! search necessary.
		print last " &"
		last = "!$OMP " substr($0,7)
		next
	}

	{
	if (first==0) {
#		One line look ahead.
		first = 1
		last = $0
		sub( /^[Cc*]/, "!", last )
		next
		}

	n = length($0)
	if (n<6) {
#		Short line cannot be a continuation line.
		print last
		last = $0
		sub( /^[Cc*]/, "!", last )
		next
		}

	c1 = substr($0,1,1)
	c6 = substr($0,6,1)
	if (c1=="C" || c1=="c" || c1=="*" || c1=="!") {
		print last
		last = "!" substr($0,2)
	} else if (c1=="#") {
		print last
		last = $0
	} else if (c6==" ") {
		print last
		last = $0
	} else if (c6=="0") {
		print last
		if (match($0,"^ *!")) {
			last = $0
		} else {
			last = substr($0,1,5) " " substr($0,7)
		}
	} else if (match($0,sym6)) {
#		A continuation line, may have a token across lines.
		print last "&"
		last = substr($0,1,5) "&" substr($0,7)
	} else if (f77==1) {
#		A continuation line, no ! search necessary.
		print last " &"
		last = substr($0,1,5) " " substr($0,7)
	} else {
#		Probably a continuation line.
		lt = last
		while (match(lt,"\"[^\"]*\"")) {
#			remove a character context
			for (i=RSTART; i < RSTART+RLENGTH; i++) {
				ltt = lt
				lt  = substr(ltt,1,i-1) "*" substr(ltt,i+1)
				}
			}
		while (match(lt,"'[^']*'")) {
#			remove a character context
			for (i=RSTART; i < RSTART+RLENGTH; i++) {
				ltt = lt
				lt  = substr(ltt,1,i-1) "*" substr(ltt,i+1)
				}
			}
		if (match(lt,"!")) n = RSTART;  else n = 0
		if      (n==0) print last " &"
		else if (n<6)  print last
		else           print substr(last,1,n-1) " & " substr(last,n)
		last = substr($0,1,5) " " substr($0,7)
		}
	}


END	{
	print last
	}
