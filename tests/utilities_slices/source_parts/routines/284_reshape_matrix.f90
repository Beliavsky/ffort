subroutine reshape_matrix(xx,n1_new,n2_new,xfill)
real(kind=dp), intent(in out), allocatable :: xx(:,:)
integer      , intent(in)    , optional    :: n1_new,n2_new
real(kind=dp), intent(in)    , optional    :: xfill
integer                                    :: n1,n2,n1_new_,n2_new_
real(kind=dp), allocatable                 :: xtemp(:,:)
logical      , parameter                   :: print_debug=.false.
n1      = size(xx,1)
n2      = size(xx,2)
n1_new_ = default(n1,n1_new)
n2_new_ = default(n2,n2_new)
if (print_debug) then
   write (*,*)
   write (*,*) "in reshape_matrix, n1, n2, n1_new_, n2_new_=",n1,n2,n1_new_,n2_new_
end if
if (n1 == n1_new_ .or. n1_new_ < 0) then
   continue
else if (n1 >  n1_new_) then
   call set_alloc((xx(:n1_new_,:)),xx)
else
   allocate (xtemp(n1_new_,n2))
   xtemp = default(0.0_dp,xfill)
   xtemp(:n1,:) = xx
   call set_alloc(xtemp,xx)
   deallocate (xtemp)
end if
n1 = size(xx,1)
if (n2 == n2_new_ .or. n2_new_ < 0) then
   continue
else if (n2 >  n2_new_) then
   call set_alloc((xx(:,:n2_new_)),xx)
else
   allocate (xtemp(n1,n2_new_))
   xtemp = default(0.0_dp,xfill)
   xtemp(:,:n2) = xx
   call set_alloc(xtemp,xx)
end if
end subroutine reshape_matrix
!
