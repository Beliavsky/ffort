subroutine spread_alloc_logical(idim,ncopies,xvec,xmat)
! create in xmat a 2D array containing copies of xvec, with an extra dimension
! along dimension idim
integer, intent(in)               :: idim,ncopies
logical, intent(in)               :: xvec(:)
logical, intent(out), allocatable :: xmat(:,:)
integer                           :: i,n,ncopies_
n        = size(xvec)
ncopies_ = max(0,ncopies)
if      (idim == 1) then
   allocate (xmat(ncopies_,n))
   forall (i=1:n) xmat(:,i) = xvec(i)
else if (idim == 2) then
   allocate (xmat(n,ncopies_))
   forall (i=1:n) xmat(i,:) = xvec(i)
else
   write (*,*) "in util_mod::spread_alloc_logical, idim =",idim," need idim = 1 or 2"
   stop
end if
end subroutine spread_alloc_logical
!
