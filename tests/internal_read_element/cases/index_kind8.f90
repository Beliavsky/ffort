program p
implicit none
character(8)::a(3)
integer::n
integer(8)::i
i=2
a(2)="31"
read(a(i),*)n
if(n/=31)stop 1
print '(a)', "OK"
end program
