subroutine copy_alloc_vec_char(ivec,jvec,values_include,values_exclude)
! return in jvec the values in ivec that are in values_include and are not in values_exclude
! and that are in the range (imin,imax), inclusive
character (len=*), intent(in)               :: ivec(:)  ! source vector
character (len=*), intent(out), allocatable :: jvec(:)  ! output vector
character (len=*), intent(in) , optional    :: values_include(:)
character (len=*), intent(in) , optional    :: values_exclude(:) ! values to exclude from jvec
integer,              allocatable :: ipos(:)
call good_pos(ivec,ipos,values_include=values_include,values_exclude=values_exclude)
allocate(jvec(size(ipos)))
jvec = ivec(ipos)
end subroutine copy_alloc_vec_char
!
