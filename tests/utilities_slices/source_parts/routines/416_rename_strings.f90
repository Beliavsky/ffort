pure function rename_strings(xx,xold,xnew) result(yy)
character (len=*), intent(in) :: xx(:),xold(:),xnew(:)
character (len=len(xx))       :: yy(size(xx))
integer                       :: i,irep,nrep
yy = xx
nrep = size(xold)
if (size(xnew) /= nrep) return
do_i: do i=1,size(xx)
   do irep=1,nrep
      if (yy(i) == xold(irep)) then
         yy(i) = xnew(irep)
         cycle do_i
      end if   
   end do
end do do_i
end function rename_strings
!
