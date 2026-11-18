program main
implicit none
integer::i,a(6)
i=99
a=(/ -1,(i,10*i,i=1,2),-2 /)
print *,a,i
end program
