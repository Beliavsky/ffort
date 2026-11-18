function positions(xmask,i1,i2) result(ipos)
! return integer vector ipos(:) such that corresponding elements of jvec are between jmin and jmax
logical      , intent(in)           :: xmask(:)
integer      , intent(in), optional :: i1,i2
integer      , allocatable          :: ipos(:)
integer      , allocatable          :: ivec(:)
integer                             :: i,i1_,i2_,n
n   = size(xmask)
i1_ = default(1,i1)
i2_ = default(n,i2)
call set_alloc([(i,i=1,n)],ivec)
call set_alloc(pack(ivec,xmask .and. ivec>=i1_ .and. ivec<=i2_),ipos)
end function positions
!
