subroutine read_unit_real_vec_alloc(iu,xx,print_vec,label,nread)
! read xx(:) from unit iu and print it if print_vec is present and .true.
integer          , intent(in)               :: iu
real(kind=dp)    , intent(out), allocatable :: xx(:)
logical          , intent(in) , optional    :: print_vec
character (len=*), intent(in) , optional    :: label
integer          , intent(out), optional    :: nread
character (len=1000)                        :: text
read (iu,"(a)") text
call read_real_vec_alloc(text,xx)
if (default(.false.,print_vec)) write (*,*) trim(label)," = ",xx
if (present(nread)) nread = size(xx)
end subroutine read_unit_real_vec_alloc
!
