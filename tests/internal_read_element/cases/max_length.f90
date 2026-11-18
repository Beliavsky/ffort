program p
implicit none
character(65536)::a(1)
integer::n
a(1)="43"
read(a(1),*)n
if(n/=43)stop 1
print '(a)', "OK"
end program
