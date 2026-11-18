program p
implicit none
character(32)::a(1)
integer::n(2,2)
a(1)="1 2 3 4"
read(a(1),*)n
if(any(reshape(n,[4])/=[1,2,3,4]))stop 1
print '(a)', "OK"
end program
