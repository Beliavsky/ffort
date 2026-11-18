function uniq_int(ivec) result(yy)
! return the unique values in ivec(:)
integer, intent(in)  :: ivec(:)
integer, allocatable :: yy(:)
call unique_values_int(ivec,yy)
end function uniq_int
!
