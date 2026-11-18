program p
implicit none
character(20)::lines(3)
integer::n,i,ios
integer::unit
character(20)::after
unit=27
read(unit,"(a)")lines(2)
read(lines(2),*)n
if(n/=59)stop 1
read(unit,"(a)")after
if(after/="NEXT")stop 2
print '(a)', "OK"
end program
