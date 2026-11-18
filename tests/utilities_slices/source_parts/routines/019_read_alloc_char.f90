subroutine read_alloc_char(iu,xx,nx,print_vec,label,same_line)
! read the size of an allocatable array and then the array from the next line
integer          , intent(in)               :: iu    ! unit read
character (len=*), intent(out), allocatable :: xx(:) ! data read
integer          , intent(out), optional    :: nx    ! size(xx)
logical          , intent(in) , optional    :: print_vec
character (len=*), intent(in) , optional    :: label
logical          , intent(in) , optional    :: same_line
integer                                     :: i,nx_,ndum
read (iu,*) nx_
nx_ = max(0,nx_)
allocate (xx(nx_))
if (present_and_true(same_line)) then
   backspace(iu)
   read (iu,*) ndum,xx
else
   read (iu,*) xx
end if
if (present(nx)) nx = nx_
if (default(.false.,print_vec)) write (*,"(1x,a30,':',100(1x,a))") trim(default("          ",label)), &
                                                               (trim(xx(i)),i=1,size(xx))
end subroutine read_alloc_char
!
