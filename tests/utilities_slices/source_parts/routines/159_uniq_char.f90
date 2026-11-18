function uniq_char(ivec) result(yy)
! return the unique values in ivec(:)
character (len=*)        , intent(in)  :: ivec(:)
character (len=len(ivec)), allocatable :: yy(:)
call unique_values_char(ivec,yy)
end function uniq_char
!
