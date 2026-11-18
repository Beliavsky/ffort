program main
implicit none
integer,pointer::i
integer::a(3)
nullify(i)
a=[(i,i=1,3)]
print *,a,associated(i)
end program
