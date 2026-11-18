program p
implicit none
character(20)::lines(3)
integer::n,i,ios
integer::unit
unit=27
read(unit,"(a)")lines(2)
read(lines(2),*)n
if(n/=61)stop 1
backspace(unit)
read(unit,"(a)")lines(1)
if(lines(1)/=lines(2))stop 2
print '(a)', "OK"
end program
