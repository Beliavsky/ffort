program p
implicit none
integer,parameter::dp=kind(1.0d0)

print *,ivec(4),size(ivec(0))
contains
pure function ivec(n) result(jj)
! return a vector of consecutive integers from 1 to n
integer, intent(in) :: n
integer             :: jj(n)
integer             :: i
forall (i=1:n) jj(i) = i
end function ivec
end program
