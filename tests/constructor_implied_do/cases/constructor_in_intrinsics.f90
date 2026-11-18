program main
implicit none
integer::i
i=99
print *,sum([(i,i=1,5)]),size([(i,i=2,1)]),i
end program
