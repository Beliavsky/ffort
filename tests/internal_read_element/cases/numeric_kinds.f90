program p
implicit none
character(64)::a(1)
integer(8)::n
real(4)::x
real(8)::y
a(1)="9007199254740993 1.25 2.5"
read(a(1),*)n,x,y
if(n/=9007199254740993_8.or.x/=1.25.or.y/=2.5_8)stop 1
print '(a)', "OK"
end program
