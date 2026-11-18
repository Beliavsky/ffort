program main
implicit none
integer::i,a(4)
i=99
a=[(i*i,i=1,4)]
print *,a,i
end program
