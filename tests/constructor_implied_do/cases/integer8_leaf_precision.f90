program main
implicit none
integer::i
integer(8)::a(3)
a=[(9007199254740992_8+i,i=1,3)]
print *,a
end program
