program p
implicit none
character(10)::a(-1:0,3:4)
integer::n
a(0,4)="29"
read(a(0,4),*)n
if(n/=29)stop 1
print '(a)', "OK"
end program
