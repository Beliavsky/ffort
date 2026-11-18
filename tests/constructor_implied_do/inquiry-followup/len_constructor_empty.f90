program main
implicit none
integer::i
print *,len([("ab",i=2,1)]),size([("ab",i=2,1)])
end program
