program main
implicit none
integer::i,a(2)
i=99
a=[(i,i=2,1),(i,i=1,2)]
print *,a,i
end program
