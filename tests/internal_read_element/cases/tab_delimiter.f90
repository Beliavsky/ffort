program p
implicit none
character(20)::lines(3)
integer::n,i,ios
integer::m
lines(1)="2"//achar(9)//"3"
read(lines(1),*)n,m
if(n/=2.or.m/=3)stop 1
print '(a)', "OK"
end program
