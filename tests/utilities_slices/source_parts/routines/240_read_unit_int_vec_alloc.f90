subroutine read_unit_int_vec_alloc(iu,ivec,print_vec,label)
! read ivec(:) from unit iu and print it if print_vec is present and .true.
integer          , intent(in)               :: iu
integer          , intent(out), allocatable :: ivec(:)
logical          , intent(in) , optional    :: print_vec
character (len=*), intent(in) , optional    :: label
character (len=1000)                        :: text
read (iu,"(a)") text
call read_int_vec_alloc(text,ivec)
if (default(.false.,print_vec)) write (*,*) trim(label)," = ",ivec
end subroutine read_unit_int_vec_alloc
!
