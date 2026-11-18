pure function diff_vector_int(xx) result(yy)
integer, intent(in) :: xx(:)
integer             :: yy(size(xx)-1)
integer             :: n
n = size(xx)
if (n > 1) yy = xx(2:)-xx(:n-1)
end function diff_vector_int
!
