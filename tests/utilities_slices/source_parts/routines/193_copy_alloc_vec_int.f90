subroutine copy_alloc_vec_int(ivec,jvec,values_include,values_exclude,imin,imax)
! return in jvec the values in ivec that are in values_include and are not in values_exclude
! and that are in the range (imin,imax), inclusive
integer, intent(in)               :: ivec(:)  ! source vector
integer, intent(out), allocatable :: jvec(:)  ! output vector
integer, intent(in) , optional    :: values_include(:)
integer, intent(in) , optional    :: values_exclude(:) ! values to exclude from jvec
integer, intent(in) , optional    :: imin     ! min allowable value in jvec
integer, intent(in) , optional    :: imax     ! max allowable
integer,              allocatable :: ipos(:)
call good_pos(ivec,ipos,values_include=values_include,values_exclude=values_exclude,imin=imin,imax=imax)
allocate(jvec(size(ipos)))
jvec = ivec(ipos)
end subroutine copy_alloc_vec_int
!
