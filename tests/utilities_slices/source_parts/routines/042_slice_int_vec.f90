function slice_int_vec(ivec,i1,i2) result(jvec)
! return the slice ivec(i1:i2), avoiding out-of-bounds
! array access
integer, intent(in)            :: ivec(:)
integer, intent(in), optional  :: i1,i2
integer, allocatable           :: jvec(:)
integer                        :: j1,j2,nj
if (present(i1)) then
   j1 = max(lbound(ivec,dim=1),i1)
else
   j1 = lbound(ivec,dim=1)
end if
if (present(i2)) then
   j2 = min(ubound(ivec,dim=1),i2)
else
   j2 = ubound(ivec,dim=1)
end if
nj = j2 - j1 + 1
allocate (jvec(nj))
jvec = ivec(j1:j2)
end function slice_int_vec
!
