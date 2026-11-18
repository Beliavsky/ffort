program main
implicit none
integer::i,a(8)
i=99
a=[(i,10*i,i=1,4)]
print *,a,i
end program
