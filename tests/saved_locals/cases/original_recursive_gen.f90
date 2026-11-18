module original_generator
implicit none
interface default
module procedure default_logical
end interface
contains
elemental function default_logical(def,opt) result(tf)
! return opt if it is present, otherwise def (logical arguments and result)
logical, intent(in)           :: def
logical, intent(in), optional :: opt
logical                       :: tf
if (present(opt)) then
   tf = opt
else
   tf = def
end if
end function default_logical
recursive subroutine gen(m,n_max,m_max,comb,comb_mat,zero_icomb)
! based on https://rosettacode.org/wiki/Combinations#Fortran
integer, intent(in)               :: m,n_max,m_max
integer, intent(in out)           :: comb(m_max)
integer, intent(in out)           :: comb_mat(:,:)
logical, intent(in)    , optional :: zero_icomb
integer                           :: n
integer, save                     :: icomb=0
logical                           :: call_gen
if (default(.false.,zero_icomb)) icomb = 0
if (m > m_max) then
   icomb = icomb + 1
   if (icomb <= size(comb_mat,1)) comb_mat(icomb,:) = comb
else
   do n = 1, n_max
      if (m == 1) then
         call_gen = .true.
      else if (n> comb(m - 1)) then
         call_gen = .true.
      else
         call_gen = .false.
      end if
      if (call_gen) then
         comb(m) = n
         call gen(m+1,n_max,m_max,comb,comb_mat)
      end if
   end do
end if
end subroutine gen
end module
program check_original
use original_generator
implicit none
integer::comb(2),cmat(6,2)
comb=0
cmat=-1
call gen(1,4,2,comb,cmat,zero_icomb=.true.)
print *,cmat(:,1)
print *,cmat(:,2)
comb=0
cmat=-1
call gen(1,3,2,comb,cmat)
print *,sum(cmat)
comb=0
call gen(1,3,2,comb,cmat,zero_icomb=.true.)
print *,cmat(:,1)
print *,cmat(:,2)
end program
