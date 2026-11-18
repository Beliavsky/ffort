program p
implicit none
character(20)::lines(3)
integer::n,i,ios
lines(1)="53"
read(lines(1),*)n
if(n/=53)stop 1
n=0
read(lines(1),*)n
if(n/=53)stop 2
print '(a)', "OK"
end program
