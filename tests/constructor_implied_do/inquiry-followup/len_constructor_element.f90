program main
implicit none
integer::i
character(3)::x(3)
print *,len([(x(i),i=1,3)])
end program
