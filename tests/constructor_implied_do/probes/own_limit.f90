program main
implicit none
integer::i,a(3)
i=3
a=[(i,i=1,i)]
print *,a,i
end program
