program p
implicit none
character(32)::a(1)
integer::n(5)
a(1)="2*7,,9/"
n=3
read(a(1),*)n
if(any(n/=[7,7,3,9,3]))stop 1
print '(a)', "OK"
end program
