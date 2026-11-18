program p
implicit none
character(8)::a(3)
integer::n
integer::i,j
i=1
j=1
a(2)="31"
read(a(i+2*j-1),*)n
if(n/=31)stop 1
print '(a)', "OK"
end program
