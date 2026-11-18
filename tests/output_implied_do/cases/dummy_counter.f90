program main
implicit none
integer::j
j=0
call work(j)
contains
subroutine work(i)
integer,intent(inout)::i
print *, (i,i=1,3)
end subroutine
end program
