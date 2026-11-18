program main
implicit none
integer::i
character(*),parameter::fmt='(3("[",i0,"]"))'
print fmt, (i,i=1,3)
end program
