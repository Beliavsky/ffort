program p
implicit none
character(10)::a(-2:0)
integer::n
a(-1)="29"
read(a(-1),*)n
if(n/=29)stop 1
print '(a)', "OK"
end program
