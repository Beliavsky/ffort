program main
implicit none
integer(8)::i,a(3)
i=99_8
a=[(i,i=1,3)]
print *,a,i,kind(a)
end program
