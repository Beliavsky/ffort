program p
implicit none
call f(1)
contains
subroutine f(d)
integer,optional,intent(in)::d
print *,maxval([1,2],d)
end subroutine
end program
