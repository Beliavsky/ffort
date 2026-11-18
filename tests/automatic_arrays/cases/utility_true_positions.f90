module automatic_fixture
implicit none
contains
subroutine work(tf)
logical,intent(in)::tf(:)
integer::jpos(size(tf)),ntrue
call true_pos_count(tf,jpos,ntrue)
print *,ntrue,jpos(:ntrue)
end subroutine
subroutine true_pos_count(tf,ipos,npos_true)
! return in ipos(:) the first size(ipos) true positions in tf(:), and in npos_true the # of true positions
! stored in ipos
logical, intent(in)  :: tf(:)
integer, intent(out) :: ipos(:)
integer, intent(out) :: npos_true
integer              :: i,npos,ntf
ipos = 0
npos = size(ipos)
ntf  = size(tf)
npos_true = 0
if (npos == 0 .or. ntf == 0) return
do i=1,ntf
   if (tf(i)) then
      npos_true = npos_true + 1
      ipos(npos_true) = i
      if (npos_true == npos) return
   end if
end do
end subroutine true_pos_count
end module
program demo
use automatic_fixture
implicit none
logical::empty(0)
call work([.true.,.false.,.true.,.true.])
call work([.false.,.false.])
call work(empty)
end program
