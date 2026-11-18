program main
implicit none
integer(8)::i,a(8)
a=[(i,i=1,kind(i))]
print *,a,kind(a)
end program
