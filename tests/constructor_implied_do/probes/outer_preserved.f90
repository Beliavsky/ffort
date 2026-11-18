program main
implicit none
integer::i,a(3)
i=99
a=[(i,i=1,3)]
print *,a,i
end program
